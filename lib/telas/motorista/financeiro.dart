import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

Widget seloCobranca(BuildContext context, StatusCobranca s) {
  final p = context.cores;
  return switch (s) {
    StatusCobranca.paga => Selo('Paga', cor: p.verde, icone: CupertinoIcons.checkmark_alt),
    StatusCobranca.pendente => Selo('Em aberto', cor: p.cinza),
    StatusCobranca.atrasada => Selo('Atrasada', cor: p.vermelho),
    StatusCobranca.informada => Selo('Confirmar', cor: p.azul, icone: CupertinoIcons.bell_fill),
  };
}

/// Tudo o que dá para fazer com uma mensalidade, em uma folha de ações.
Future<void> acoesCobranca(BuildContext context, Cobranca c) async {
  final store = VanScope.read(context);
  final a = store.aluno(c.alunoId);
  final s = c.status(DateTime.now());

  final escolha = await escolherAcao<String>(
    context,
    titulo: '${a.nome} · ${capitalizar(mesAno(c.competencia))}',
    mensagem: s == StatusCobranca.paga
        ? '${moeda(c.valor)} pagos em ${dataCurta(c.pagaEm!)} via ${c.meio?.rotulo}'
        : s == StatusCobranca.informada
            ? '${primeiroNome(a.responsavel.nome)} avisou que já pagou ${moeda(c.valor)}.'
            : '${moeda(c.valor)} · vence ${dataCurta(c.vencimento)}',
    opcoes: s == StatusCobranca.paga
        ? const [OpcaoAcao('Desfazer pagamento', 'desfazer', destrutiva: true)]
        : [
            for (final m in [MeioPagamento.pix, MeioPagamento.dinheiro, MeioPagamento.transferencia])
              OpcaoAcao(s == StatusCobranca.informada && m == MeioPagamento.pix ? 'Confirmar recebimento (Pix)' : 'Recebido via ${m.rotulo}', m.name),
            const OpcaoAcao('Cobrar: copiar mensagem', 'lembrete'),
          ],
  );
  if (escolha == null || !context.mounted) return;
  switch (escolha) {
    case 'desfazer':
      store.desfazerPagamento(c);
    case 'lembrete':
      Clipboard.setData(ClipboardData(text: store.mensagemCobranca(c)));
      avisar(context, 'Mensagem copiada — cole no WhatsApp', icone: CupertinoIcons.doc_on_doc_fill);
    default:
      store.registrarPagamento(c, MeioPagamento.values.byName(escolha));
      avisar(context, 'Pagamento de ${a.primeiro} registrado');
  }
}

class FinanceiroTela extends StatefulWidget {
  const FinanceiroTela({super.key});

  @override
  State<FinanceiroTela> createState() => _FinanceiroTelaState();
}

class _FinanceiroTelaState extends State<FinanceiroTela> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final hoje = DateTime.now();
    final r = store.resumo(_mes);
    final todas = store.cobrancasDoMes(_mes);
    final abertas = todas.where((c) => c.status(hoje) != StatusCobranca.paga).toList()
      ..sort((a, b) => a.status(hoje).index.compareTo(b.status(hoje).index));
    final pagas = todas.where((c) => c.status(hoje) == StatusCobranca.paga).toList();
    final atrasadas = store.atrasadas;
    final faltando = store.alunosAtivos.length - todas.length;
    final ativos = store.alunosAtivos.length;

    return PaginaIOS(
      titulo: 'Finanças',
      filhos: [
        _Grafico(mesSelecionado: _mes, aoEscolher: (m) => setState(() => _mes = m)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Indicador(rotulo: 'Recebido', valor: moeda(r.recebido), cor: p.verde, icone: CupertinoIcons.arrow_down_circle_fill)),
          const SizedBox(width: 10),
          Expanded(child: _Indicador(rotulo: 'A receber', valor: moeda(r.aReceber), cor: p.azul, icone: CupertinoIcons.clock_fill)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _Indicador(rotulo: 'Atrasado', valor: moeda(r.emAtraso), cor: p.vermelho, icone: CupertinoIcons.exclamationmark_circle_fill)),
          const SizedBox(width: 10),
          Expanded(
            child: _Indicador(
              rotulo: 'Ticket médio',
              valor: moeda(ativos == 0 ? 0 : r.esperado / ativos),
              cor: p.cinza,
              icone: CupertinoIcons.person_fill,
            ),
          ),
        ]),
        if (atrasadas.isNotEmpty || faltando > 0)
          Secao(
            titulo: 'Ações',
            filhos: [
              if (atrasadas.isNotEmpty)
                Linha(
                  inicio: IconeApp(CupertinoIcons.paperplane_fill, cor: p.vermelho),
                  titulo: 'Cobrar ${atrasadas.length} atrasada(s)',
                  subtitulo: 'Copia mensagens gentis para o WhatsApp',
                  corTitulo: p.vermelho,
                  seta: false,
                  aoTocar: () {
                    Clipboard.setData(ClipboardData(text: store.mensagemCobrancaEmLote(atrasadas)));
                    avisar(context, '${atrasadas.length} mensagens copiadas', icone: CupertinoIcons.doc_on_doc_fill);
                  },
                ),
              if (faltando > 0)
                Linha(
                  inicio: IconeApp(CupertinoIcons.doc_text_fill, cor: p.azul),
                  titulo: todas.isEmpty ? 'Gerar mensalidades de ${mesCurto(_mes)}' : 'Gerar $faltando mensalidade(s) faltando',
                  corTitulo: p.azul,
                  seta: false,
                  aoTocar: () => avisar(context, '${store.gerarCobrancas(_mes)} mensalidade(s) gerada(s)'),
                ),
            ],
          ),
        const SizedBox(height: 22),
        Segmentos<int>(
          valor: _seg,
          opcoes: {0: 'A receber (${abertas.length})', 1: 'Pagas (${pagas.length})'},
          aoMudar: (v) => setState(() => _seg = v),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey('$_seg-${_mes.month}-${_mes.year}'),
            child: (_seg == 0 ? abertas : pagas).isEmpty
                ? Vazio(
                    icone: _seg == 0 ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.tray,
                    titulo: _seg == 0 ? 'Tudo recebido!' : 'Nenhum pagamento ainda',
                  )
                : Secao(
                    titulo: capitalizar(mesAno(_mes)),
                    filhos: [
                      for (final c in _seg == 0 ? abertas : pagas)
                        Linha(
                          inicio: Avatar(store.aluno(c.alunoId).nome, tamanho: 36),
                          titulo: store.aluno(c.alunoId).nome,
                          subtitulo: c.pagaEm != null
                              ? '${moeda(c.valor)} · ${c.meio?.rotulo} em ${dataCurta(c.pagaEm!)}'
                              : '${moeda(c.valor)} · vence ${dataCurta(c.vencimento)}',
                          fim: seloCobranca(context, c.status(hoje)),
                          seta: false,
                          aoTocar: () => acoesCobranca(context, c),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}

/// Gráfico de barras dos últimos 6 meses: previsto (claro) × recebido (azul).
class _Grafico extends StatelessWidget {
  const _Grafico({required this.mesSelecionado, required this.aoEscolher});

  final DateTime mesSelecionado;
  final ValueChanged<DateTime> aoEscolher;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final dados = store.historico();
    final maximo = dados.fold<double>(1, (m, d) => d.$2.esperado > m ? d.$2.esperado : m);
    final atual = store.resumo(mesSelecionado);
    final pct = (atual.percentual * 100).round();

    return Cartao(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(capitalizar(mesAno(mesSelecionado)), style: TextStyle(color: p.textoSuave)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: atual.recebido),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text(moeda(v), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
              ),
              const Spacer(),
              Selo('$pct% recebido', cor: pct >= 80 ? p.verde : p.azul),
            ],
          ),
          Text('de ${moeda(atual.esperado)} previstos · inadimplência ${(store.inadimplencia(mesSelecionado) * 100).round()}%',
              style: TextStyle(color: p.textoSuave, fontSize: 13)),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (mes, r) in dados)
                  Expanded(
                    child: Tocavel(
                      aoTocar: () => aoEscolher(mes),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 112,
                            width: 26,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                _Barra(fracao: r.esperado / maximo, cor: p.preenchimento),
                                _Barra(
                                  fracao: r.recebido / maximo,
                                  cor: mes.month == mesSelecionado.month && mes.year == mesSelecionado.year
                                      ? p.azul
                                      : p.azul.withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mesCurto(mes),
                            style: TextStyle(
                              fontSize: 12,
                              color: mes.month == mesSelecionado.month ? p.texto : p.textoSuave,
                              fontWeight: mes.month == mesSelecionado.month ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({required this.fracao, required this.cor});

  final double fracao;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fracao.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (_, f, _) => FractionallySizedBox(
        heightFactor: f == 0 ? 0.02 : f,
        child: Container(decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(8))),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({required this.rotulo, required this.valor, required this.cor, required this.icone});

  final String rotulo;
  final String valor;
  final Color cor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Cartao(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: 6),
            Text(rotulo, style: TextStyle(color: p.textoSuave, fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
          ),
        ],
      ),
    );
  }
}
