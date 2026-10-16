import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/mapa.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import 'ausencias.dart';

/// Home do responsável: o mapa ocupa a tela toda e as informações flutuam por cima.
class MapaPrincipalTela extends StatefulWidget {
  const MapaPrincipalTela({super.key});

  @override
  State<MapaPrincipalTela> createState() => _MapaPrincipalTelaState();
}

class _MapaPrincipalTelaState extends State<MapaPrincipalTela> {
  int _filho = 0;
  final _controle = MapController();

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final filhos = store.filhosDoResponsavel.map(store.aluno).toList();
    final filho = filhos[_filho.clamp(0, filhos.length - 1)];
    final v = store.viagem;
    final naViagem = v != null && v.situacoes.containsKey(filho.id) && !v.encerrada ? v : null;
    final rodapeSeguro = MediaQuery.paddingOf(context).bottom + 62;

    final pontos = naViagem == null ? <Offset>[] : [naViagem.trajeto.garagem, ...naViagem.paradas.map((x) => x.posicao)];
    final marcadores = [
      if (naViagem != null)
        for (final x in naViagem.paradas)
          if (x.tipo == TipoParada.escola) MarcadorMapa(x.posicao, TipoMarcador.escola),
      if (naViagem == null) MarcadorMapa(store.escola(filho.escolaId).posicao, TipoMarcador.escola),
      MarcadorMapa(filho.posicao, TipoMarcador.destaque, rotulo: 'Casa'),
    ];
    final margem = EdgeInsets.fromLTRB(40, 130, 40, rodapeSeguro + 190);

    return Scaffold(
      backgroundColor: p.fundo,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapaTrajeto(
              // Chave muda com o contexto (filho/viagem) para reenquadrar o mapa.
              key: ValueKey('${filho.id}-${naViagem?.trajeto.id}-${p.escuro}'),
              controle: _controle,
              pontos: pontos,
              marcadores: marcadores,
              posicaoAoVivo: naViagem == null ? null : store.posicaoCompartilhada,
              transmitindo: naViagem != null,
              altura: null,
              raio: 0,
              interativo: true,
              margem: margem,
            ),
          ),
          // Topo: escolha do filho + recentralizar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _Vidro(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final (i, f) in filhos.indexed)
                              Tocavel(
                                aoTocar: () => setState(() => _filho = i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                                  decoration: BoxDecoration(
                                    color: i == _filho ? p.azul : Colors.transparent,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Row(
                                    children: [
                                      Avatar(f.nome, tamanho: 28),
                                      const SizedBox(width: 6),
                                      Text(
                                        f.primeiro,
                                        style: TextStyle(fontWeight: FontWeight.w600, color: i == _filho ? Colors.white : p.texto),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Tocavel(
                        aoTocar: () => _controle.fitCamera(
                          CameraFit.coordinates(
                            coordinates: [...pontos, ...marcadores.map((m) => m.posicao)].map(paraLatLng).toList(),
                            padding: margem,
                            maxZoom: 16,
                          ),
                        ),
                        escala: 0.9,
                        child: _Vidro(
                          padding: const EdgeInsets.all(11),
                          child: Icon(CupertinoIcons.location_fill, size: 20, color: p.azul),
                        ),
                      ),
                    ],
                  ),
                  if (store.localizacaoAtrasada && naViagem != null) ...[
                    const SizedBox(height: 10),
                    _Vidro(
                      raio: 18,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.wifi_slash, color: p.laranja),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A localização não está em tempo real (última há ${store.segundosSemLocalizacao}s). '
                              'Pode ser sinal ou GPS do motorista; o mapa mostra a última posição recebida.',
                              style: TextStyle(color: p.texto, fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (store.emergenciaEm != null && naViagem != null) ...[
                    const SizedBox(height: 10),
                    Cartao(
                      cor: p.vermelho,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Alerta do motorista às ${hora(store.emergenciaEm!)}. Ligue para ${primeiroNome(store.nomeMotorista)}.',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Base: status + ações rápidas
          Positioned(
            left: 12,
            right: 12,
            bottom: rodapeSeguro + 10,
            child: _PainelStatus(filho: filho, viagem: naViagem),
          ),
        ],
      ),
    );
  }
}

class _Vidro extends StatelessWidget {
  const _Vidro({required this.child, this.padding = const EdgeInsets.all(14), this.raio = 99});

  final Widget child;
  final EdgeInsets padding;
  final double raio;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: p.cartao.withValues(alpha: p.escuro ? 0.78 : 0.86),
            borderRadius: BorderRadius.circular(raio),
            border: Border.all(color: p.separador.withValues(alpha: 0.6), width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PainelStatus extends StatelessWidget {
  const _PainelStatus({required this.filho, required this.viagem});

  final Aluno filho;
  final Viagem? viagem;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final (icone, titulo, texto, cor, aoVivo) = _status(store, p);
    final ausenciaHoje = store.ausenciasFuturasDe(filho.id).where((a) => mesmoDia(a.data, DateTime.now())).firstOrNull;

    return _Vidro(
      raio: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconeApp(icone, cor: cor, tamanho: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (aoVivo)
                      Row(
                        children: [
                          PontoAoVivo(cor: p.verde),
                          const SizedBox(width: 6),
                          Text(
                            'AO VIVO',
                            style: TextStyle(color: p.verde, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                        ],
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        titulo,
                        key: ValueKey(titulo),
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: p.texto),
                      ),
                    ),
                    Text(texto, style: TextStyle(color: p.textoSuave)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (store.podeAgir) ...[
                Expanded(
                  child: ausenciaHoje == null
                      ? Botao(
                          'Não vai hoje',
                          compacto: true,
                          estilo: EstiloBotao.secundario,
                          icone: CupertinoIcons.calendar_badge_minus,
                          aoTocar: () => avisarAusencia(context, alunoId: filho.id),
                        )
                      : Botao(
                          'Vai sim',
                          compacto: true,
                          estilo: EstiloBotao.secundario,
                          icone: CupertinoIcons.arrow_uturn_left,
                          aoTocar: () => marcarPresenca(context, ausenciaHoje),
                        ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Botao(
                  'Motorista',
                  compacto: true,
                  estilo: EstiloBotao.secundario,
                  icone: CupertinoIcons.phone_fill,
                  aoTocar: () => avisar(context, 'Ligaria para ${store.nomeMotorista} (protótipo)', icone: CupertinoIcons.phone_fill),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (IconData, String, String, Color, bool) _status(VanStore store, Paleta p) {
    final v = viagem;
    if (v == null) {
      final aus = store.ausenciasFuturasDe(filho.id).where((a) => mesmoDia(a.data, DateTime.now()));
      final proximo = store.trajetosOrdenados.where(
        (t) => store.alunosDoDia(t).any((a) => a.id == filho.id) && !store.concluidosHoje.contains(t.id),
      );
      if (aus.isNotEmpty) {
        return (CupertinoIcons.calendar_badge_minus, 'Ausência avisada', '${aus.first.rotuloSentido} · motorista ciente', p.laranja, false);
      }
      if (proximo.isNotEmpty) {
        final t = proximo.first;
        return (
          CupertinoIcons.clock_fill,
          '${t.sentido.rotulo} às ${horario(t.saida)}',
          'Você recebe um aviso quando a van sair.',
          p.azul,
          false,
        );
      }
      return (CupertinoIcons.moon_fill, 'Sem viagens agora', '${filho.primeiro} está com você 💙', p.roxo, false);
    }
    final s = v.situacoes[filho.id]!;
    final ida = v.trajeto.sentido == Sentido.ida;
    final eta = store.previsaoMinutos(filho.id);
    final ev = v.eventos.where((e) => e.alunoId == filho.id).firstOrNull;
    final paradas = store.paradasAte(filho.id);
    final chegando = store.aproximacaoAvisada.containsKey(filho.id);
    String falta(int? n) => switch (n) {
      null => '',
      0 => 'Você é a próxima parada',
      1 => 'Falta 1 parada antes de você',
      _ => 'Faltam $n paradas antes de você',
    };
    return switch (s) {
      SituacaoAluno.aguardando =>
        ida
            ? (
                CupertinoIcons.bus,
                chegando ? 'A van está chegando!' : (eta == 0 ? 'A van chegou!' : 'Chega em ~$eta min'),
                chegando || (eta != null && eta <= 4) ? 'Hora de descer com a mochila 🎒' : falta(paradas),
                chegando ? p.verde : p.azul,
                true,
              )
            : (CupertinoIcons.bus, 'Aguardando a saída', 'A van está indo buscar ${filho.primeiro}.', p.azul, true),
      SituacaoAluno.aBordo => (
        CupertinoIcons.person_crop_circle_fill_badge_checkmark,
        '${filho.primeiro} está na van',
        ida ? 'Indo para a escola.' : 'Chega em ~${eta ?? '?'} min · ${falta(paradas).toLowerCase()}',
        p.verde,
        true,
      ),
      SituacaoAluno.entregue => (
        CupertinoIcons.checkmark_seal_fill,
        ida ? 'Chegou na escola' : 'Chegou em casa',
        'Às ${ev == null ? '--' : hora(ev.quando)}. Tudo certo 💙',
        p.verde,
        true,
      ),
      SituacaoAluno.faltou => (
        CupertinoIcons.xmark_circle_fill,
        'Marcado como ausente',
        'Algo errado? Fale com o motorista.',
        p.vermelho,
        true,
      ),
      SituacaoAluno.avisado => (CupertinoIcons.calendar_badge_minus, 'Ausência avisada', 'A parada saiu da rota de hoje.', p.laranja, true),
    };
  }
}
