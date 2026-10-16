import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app/tema.dart';

enum TipoMarcador { garagem, casa, escola, destaque }

class MarcadorMapa {
  const MarcadorMapa(this.posicao, this.tipo, {this.concluido = false, this.rotulo});

  /// Posição normalizada (0..1) dentro da área de atendimento.
  final Offset posicao;
  final TipoMarcador tipo;
  final bool concluido;
  final String? rotulo;
}

/// Área de atendimento da demonstração (região central de São Paulo).
/// Os dados guardam posições normalizadas; aqui viram coordenadas reais.
const _norte = -23.548;
const _oeste = -46.672;
const _alturaGraus = 0.036;
const _larguraGraus = 0.048;

LatLng paraLatLng(Offset n) => LatLng(_norte - n.dy * _alturaGraus, _oeste + n.dx * _larguraGraus);

/// Ponto da van no percurso: [p] é fracionário no espaço de índices de [pts].
/// Entre duas paradas segue o desenho "em L" (como quarteirões).
Offset posicaoNoPercurso(List<Offset> pts, double p) {
  if (pts.isEmpty) return Offset.zero;
  if (p <= 0) return pts.first;
  if (p >= pts.length - 1) return pts.last;
  final i = p.floor();
  final t = p - i;
  final a = pts[i], b = pts[i + 1];
  final c = Offset(b.dx, a.dy);
  final l1 = (c - a).distance, l2 = (b - c).distance;
  if (l1 + l2 == 0) return a;
  final d = t * (l1 + l2);
  if (d <= l1) return Offset.lerp(a, c, l1 == 0 ? 1 : d / l1)!;
  return Offset.lerp(c, b, l2 == 0 ? 1 : (d - l1) / l2)!;
}

List<LatLng> _caminho(List<Offset> pts, {double? ate}) {
  if (pts.isEmpty) return const [];
  final limite = ate == null ? pts.length - 1.0 : math.min(ate, pts.length - 1.0);
  final saida = <LatLng>[paraLatLng(pts.first)];
  for (var i = 0; i + 1 <= limite.ceil() && i < pts.length - 1; i++) {
    final a = pts[i], b = pts[i + 1];
    final fim = math.min(limite, i + 1.0);
    if (fim <= i) break;
    if (fim >= i + 1) {
      saida
        ..add(paraLatLng(Offset(b.dx, a.dy)))
        ..add(paraLatLng(b));
    } else {
      final meio = Offset(b.dx, a.dy);
      final van = posicaoNoPercurso(pts, fim);
      // Se a van já passou da esquina, inclui a esquina.
      if ((van - a).distance > (meio - a).distance) saida.add(paraLatLng(meio));
      saida.add(paraLatLng(van));
    }
  }
  return saida;
}

/// Saturação reduzida a [s] (0 = cinza), multiplicada por [k] e somada a [b] (por canal).
ColorFilter _matriz({required double s, required double k, required List<double> b, bool inverter = false}) {
  const r = 0.2126, g = 0.7152, bl = 0.0722;
  final sinal = inverter ? -1.0 : 1.0;
  final base = inverter ? 255.0 * k : 0.0;
  List<double> linha(int canal) => [
        sinal * k * (r * (1 - s) + (canal == 0 ? s : 0)),
        sinal * k * (g * (1 - s) + (canal == 1 ? s : 0)),
        sinal * k * (bl * (1 - s) + (canal == 2 ? s : 0)),
        0,
        base + b[canal],
      ];
  return ColorFilter.matrix([...linha(0), ...linha(1), ...linha(2), 0, 0, 0, 1, 0]);
}

final _matrizClara = _matriz(s: 0.12, k: 0.82, b: [44, 47, 54]);
final _matrizEscura = _matriz(s: 0.10, k: 0.85, b: [14, 17, 26], inverter: true);

/// Mapa real (OpenStreetMap) com percurso e van, em tons de cinza e azul.
class MapaTrajeto extends StatefulWidget {
  const MapaTrajeto({
    super.key,
    required this.pontos,
    required this.marcadores,
    this.progresso,
    this.transmitindo = false,
    this.altura = 260,
    this.raio = 24,
    this.interativo = false,
    this.margem = const EdgeInsets.all(36),
    this.controle,
    this.posicaoAoVivo,
  });

  final List<Offset> pontos;
  final List<MarcadorMapa> marcadores;

  /// Progresso fixo no espaço de índices de [pontos].
  final double? progresso;

  /// Posição da van ao vivo (posição da viagem; o primeiro ponto é a garagem).
  /// Só a rota e a van redesenham a cada quadro; as imagens do mapa, não.
  final ValueListenable<double>? posicaoAoVivo;
  final bool transmitindo;

  /// null = ocupa todo o espaço disponível.
  final double? altura;
  final double raio;
  final bool interativo;

  /// Espaço livre nas bordas ao enquadrar a rota (ex.: sob painéis).
  final EdgeInsets margem;
  final MapController? controle;

  @override
  State<MapaTrajeto> createState() => _MapaTrajetoState();
}

class _MapaTrajetoState extends State<MapaTrajeto> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.transmitindo) _pulso.repeat();
  }

  @override
  void didUpdateWidget(MapaTrajeto antigo) {
    super.didUpdateWidget(antigo);
    if (widget.transmitindo && !_pulso.isAnimating) _pulso.repeat();
    if (!widget.transmitindo && _pulso.isAnimating) _pulso.stop();
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  CameraFit get _enquadramento {
    final todos = [...widget.pontos, ...widget.marcadores.map((m) => m.posicao)];
    if (todos.isEmpty) todos.add(const Offset(0.5, 0.5));
    return CameraFit.coordinates(
      coordinates: todos.map(paraLatLng).toList(),
      padding: widget.margem,
      maxZoom: 16,
    );
  }

  TileLayer? _imagens;
  bool? _imagensEscuras;

  /// Camada de imagens criada uma vez por tema (recriar a cada quadro recarregaria tudo).
  TileLayer _camadaImagens(BuildContext context, bool escuro) {
    if (_imagens == null || _imagensEscuras != escuro) {
      _imagensEscuras = escuro;
      _imagens = TileLayer(
        // Imagens do OpenStreetMap (sem chave). Em produção, use um provedor com chave
        // (MapTiler, Stadia, Mapbox) ou google_maps_flutter — veja o README.
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'app.vanconnect.van_connect',
        maxNativeZoom: 19,
        // Filtro de cor: mapa cinza-claro e minimalista (ou escuro), combinando com o app.
        tileBuilder: (context, tile, _) => escuro
            ? ColorFiltered(
                colorFilter: _matrizEscura,
                child: tile,
              )
            : ColorFiltered(colorFilter: _matrizClara, child: tile),
      );
    }
    return _imagens!;
  }

  Widget _rota(Paleta p, double? prog) => widget.pontos.length < 2
      ? const SizedBox.shrink()
      : PolylineLayer(polylines: [
            Polyline(points: _caminho(widget.pontos), strokeWidth: 6, color: p.azul.withValues(alpha: 0.28)),
            if (prog != null && prog > 0) Polyline(points: _caminho(widget.pontos, ate: prog), strokeWidth: 6, color: p.azul),
          ]);

  Widget _marcadores(double? prog) => MarkerLayer(
          markers: [
            for (final m in widget.marcadores)
              Marker(
                point: paraLatLng(m.posicao),
                width: m.rotulo == null ? 40 : 70,
                height: m.tipo == TipoMarcador.destaque ? 64 : 40,
                alignment: m.tipo == TipoMarcador.destaque ? Alignment.topCenter : Alignment.center,
                child: _Pino(m),
              ),
            if (prog != null && widget.pontos.isNotEmpty)
              Marker(
                point: paraLatLng(posicaoNoPercurso(widget.pontos, prog)),
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _pulso,
                  builder: (_, _) => _Van(pulso: widget.transmitindo ? _pulso.value : null),
                ),
              ),
          ],
        );

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final aoVivo = widget.posicaoAoVivo;

    final mapa = FlutterMap(
      mapController: widget.controle,
      options: MapOptions(
        initialCameraFit: _enquadramento,
        backgroundColor: p.mapaFundo,
        interactionOptions: InteractionOptions(
          flags: widget.interativo ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        _camadaImagens(context, p.escuro),
        if (aoVivo == null) ...[
          _rota(p, widget.progresso),
          _marcadores(widget.progresso),
        ] else ...[
          ValueListenableBuilder<double>(valueListenable: aoVivo, builder: (_, pos, _) => _rota(p, pos + 1)),
          ValueListenableBuilder<double>(valueListenable: aoVivo, builder: (_, pos, _) => _marcadores(pos + 1)),
        ],
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 8, bottom: widget.margem.bottom > 60 ? widget.margem.bottom - 30 : 4),
            child: Text('© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: p.textoSuave.withValues(alpha: 0.8))),
          ),
        ),
      ],
    );

    final corpo = ClipRRect(borderRadius: BorderRadius.circular(widget.raio), child: mapa);
    return widget.altura == null ? corpo : SizedBox(height: widget.altura, width: double.infinity, child: corpo);
  }
}

class _Pino extends StatelessWidget {
  const _Pino(this.m);

  final MarcadorMapa m;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final sombra = [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6, offset: const Offset(0, 2))];
    switch (m.tipo) {
      case TipoMarcador.garagem:
        return Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: p.cinza, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
          ),
        );
      case TipoMarcador.casa:
        return Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: m.concluido ? p.verde : p.cartao,
              shape: BoxShape.circle,
              border: Border.all(color: m.concluido ? p.verde : p.azul, width: 2.5),
              boxShadow: sombra,
            ),
            child: Icon(m.concluido ? CupertinoIcons.checkmark_alt : CupertinoIcons.house_fill,
                size: 14, color: m.concluido ? Colors.white : p.azul),
          ),
        );
      case TipoMarcador.escola:
        return Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: ShapeDecoration(
              color: Paleta.marinhoMarca,
              shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadows: sombra,
            ),
            child: const Icon(CupertinoIcons.book_fill, size: 17, color: Colors.white),
          ),
        );
      case TipoMarcador.destaque:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.rotulo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: p.cartao, borderRadius: BorderRadius.circular(8), boxShadow: sombra),
                child: Text(m.rotulo!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.texto)),
              ),
            const SizedBox(height: 3),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: p.azul,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: sombra,
              ),
              child: const Icon(CupertinoIcons.house_fill, size: 15, color: Colors.white),
            ),
          ],
        );
    }
  }
}

class _Van extends StatelessWidget {
  const _Van({this.pulso});

  final double? pulso;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final pul = pulso;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (pul != null)
          Container(
            width: 36 + 40 * pul,
            height: 36 + 40 * pul,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.azul.withValues(alpha: 0.35 * (1 - pul))),
          ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: p.azul,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: p.azul.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(CupertinoIcons.bus, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
