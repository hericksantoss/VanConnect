import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

(IconData, Color) estiloAviso(TipoAviso t, Paleta p) => switch (t) {
  TipoAviso.pedido => (Icons.person_add_alt_1_rounded, p.azul),
  TipoAviso.ausencia => (Icons.event_busy_rounded, p.ambar),
  TipoAviso.pagamento => (Icons.payments_rounded, p.verde),
  TipoAviso.cobranca => (Icons.receipt_long_rounded, p.vermelho),
  TipoAviso.lembrete => (Icons.alarm_rounded, p.ambar),
  TipoAviso.pix => (Icons.pix_rounded, p.verde),
  TipoAviso.viagem => (Icons.directions_bus_rounded, p.azul),
  TipoAviso.convite => (Icons.mark_email_read_rounded, p.roxo),
  TipoAviso.sistema => (Icons.warning_amber_rounded, p.vermelho),
};

String quandoFoi(DateTime d) {
  final dif = DateTime.now().difference(d);
  if (dif.inMinutes < 1) return 'agora';
  if (dif.inMinutes < 60) return 'há ${dif.inMinutes} min';
  if (dif.inHours < 24) return 'há ${dif.inHours} h';
  return dataCurta(d);
}

List<Aviso> _lista(VanStore s, bool motorista) => motorista ? s.avisosMotorista : s.avisosResponsavel;

void abrirCentralAvisos(BuildContext context, {required bool motorista}) => abrir(context, CentralAvisosTela(motorista: motorista));

/// Sino com contador de avisos não lidos.
class SinoAvisos extends StatelessWidget {
  const SinoAvisos({super.key, required this.motorista});

  final bool motorista;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final n = motorista ? store.naoLidosMotorista : store.naoLidosResponsavel;
    return Tocavel(
      aoTocar: () => abrirCentralAvisos(context, motorista: motorista),
      escala: 0.9,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: p.cartao,
          shape: BoxShape.circle,
          border: Border.all(color: p.separador),
        ),
        child: Badge(
          isLabelVisible: n > 0,
          label: Text('$n'),
          backgroundColor: p.vermelho,
          child: Icon(n > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: p.texto, size: 22),
        ),
      ),
    );
  }
}

/// Destaque do aviso mais recente não lido, logo na tela inicial.
class BannerAviso extends StatelessWidget {
  const BannerAviso({super.key, required this.motorista, this.flutuante = false});

  final bool motorista;

  /// true = sobre o mapa (fundo com vidro).
  final bool flutuante;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final naoLidos = _lista(store, motorista).where((a) => !a.lido).toList();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (c, a) => SizeTransition(
        sizeFactor: a,
        child: FadeTransition(opacity: a, child: c),
      ),
      child: naoLidos.isEmpty
          ? const SizedBox(width: double.infinity, key: ValueKey('vazio'))
          : TweenAnimationBuilder<double>(
              key: ValueKey(naoLidos.first.id),
              tween: Tween(begin: -14, end: 0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (_, y, filho) => Transform.translate(offset: Offset(0, y), child: filho),
              child: _CartaoBanner(aviso: naoLidos.first, mais: naoLidos.length - 1, motorista: motorista, flutuante: flutuante, p: p),
            ),
    );
  }
}

class _CartaoBanner extends StatelessWidget {
  const _CartaoBanner({required this.aviso, required this.mais, required this.motorista, required this.flutuante, required this.p});

  final Aviso aviso;
  final int mais;
  final bool motorista;
  final bool flutuante;
  final Paleta p;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final (icone, cor) = estiloAviso(aviso.tipo, p);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tocavel(
        aoTocar: () => abrirCentralAvisos(context, motorista: motorista),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          decoration: BoxDecoration(
            color: flutuante ? p.cartao.withValues(alpha: 0.95) : p.cartao,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cor.withValues(alpha: 0.35)),
            boxShadow: flutuante
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconeApp(icone, cor: cor, tamanho: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            aviso.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w800, color: p.texto),
                          ),
                        ),
                        Text(quandoFoi(aviso.criadoEm), style: TextStyle(color: p.textoSuave, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      aviso.texto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textoSuave, fontSize: 13.5),
                    ),
                    if (mais > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+ $mais aviso(s) novo(s)',
                        style: TextStyle(color: p.azul, fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dispensar',
                visualDensity: VisualDensity.compact,
                onPressed: () => store.marcarAvisoLido(aviso),
                icon: Icon(Icons.close_rounded, size: 18, color: p.cinza),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha de aviso (usada na central e na aba Avisos do responsável).
class LinhaAviso extends StatelessWidget {
  const LinhaAviso({super.key, required this.aviso});

  final Aviso aviso;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final (icone, cor) = estiloAviso(aviso.tipo, p);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconeApp(icone, cor: cor, tamanho: 36),
              if (!aviso.lido)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: p.azul,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.cartao, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        aviso.titulo,
                        style: TextStyle(fontWeight: FontWeight.w700, color: p.texto),
                      ),
                    ),
                    Text(quandoFoi(aviso.criadoEm), style: TextStyle(color: p.textoSuave, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(aviso.texto, style: TextStyle(color: p.textoSuave, height: 1.35)),
                if (aviso.chavePix != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Botao(
                      'Copiar chave Pix',
                      compacto: true,
                      estilo: EstiloBotao.secundario,
                      icone: Icons.copy_rounded,
                      aoTocar: () {
                        Clipboard.setData(ClipboardData(text: aviso.chavePix!));
                        avisar(context, 'Chave Pix copiada', icone: Icons.pix_rounded);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CentralAvisosTela extends StatefulWidget {
  const CentralAvisosTela({super.key, required this.motorista});

  final bool motorista;

  @override
  State<CentralAvisosTela> createState() => _CentralAvisosTelaState();
}

class _CentralAvisosTelaState extends State<CentralAvisosTela> {
  late final VanStore _store = VanScope.read(context);

  @override
  void dispose() {
    // Ao sair da central, tudo o que foi visto conta como lido.
    _store.marcarAvisosLidos(motorista: widget.motorista);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final lista = _lista(store, widget.motorista);
    return PaginaIOS(
      titulo: 'Avisos',
      voltar: true,
      filhos: [
        if (lista.isEmpty)
          const Vazio(icone: Icons.notifications_none_rounded, titulo: 'Nenhum aviso por enquanto')
        else
          Secao(recuo: 62, filhos: [for (final a in lista) LinhaAviso(aviso: a)]),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'No protótipo os avisos ficam dentro do app. Em produção, também chegam como notificação no celular.',
            style: TextStyle(color: p.textoSuave, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
