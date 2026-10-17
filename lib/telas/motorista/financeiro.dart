import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

Widget seloCobranca(BuildContext context, StatusCobranca s) {
  final p = context.cores;
  return switch (s) {
    StatusCobranca.paga => Selo('Paga', cor: p.verde, icone: Icons.check_rounded),
    StatusCobranca.pendente => Selo('Em aberto', cor: p.cinza),
    StatusCobranca.atrasada => Selo('Atrasada', cor: p.vermelho),
    StatusCobranca.informada => Selo('Confirmar', cor: p.roxo, icone: Icons.notifications_rounded),
  };
}

/// Tudo o que dá para fazer com uma mensalidade.
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
        ? const [OpcaoAcao('Desfazer pagamento', 'desfazer', destrutiva: true, icone: Icons.undo_rounded)]
        : [
            for (final m in [MeioPagamento.pix, MeioPagamento.dinheiro, MeioPagamento.transferencia])
              OpcaoAcao(
                s == StatusCobranca.informada && m == MeioPagamento.pix ? 'Confirmar recebimento (Pix)' : 'Recebido via ${m.rotulo}',
                m.name,
                icone: Icons.check_circle_rounded,
              ),
            const OpcaoAcao('Cobrar no app (com chave Pix)', 'cobrar', icone: Icons.notifications_active_rounded),
            const OpcaoAcao('Copiar mensagem para WhatsApp', 'lembrete', icone: Icons.copy_rounded),
          ],
  );
  if (escolha == null || !context.mounted) return;
  switch (escolha) {
    case 'desfazer':
      store.desfazerPagamento(c);
    case 'cobrar':
      if (store.chavePix == null && !await _pedirChavePix(context)) return;
      store.cobrar(c);
      if (context.mounted) avisar(context, 'Família de ${a.primeiro} avisada no app', icone: Icons.notifications_active_rounded);
    case 'lembrete':
      Clipboard.setData(ClipboardData(text: store.mensagemCobranca(c)));
      avisar(context, 'Mensagem copiada — cole no WhatsApp', icone: Icons.copy_rounded);
    default:
      store.registrarPagamento(c, MeioPagamento.values.byName(escolha));
      avisar(context, 'Pagamento de ${a.primeiro} registrado');
  }
}

/// Sem chave Pix: oferece cadastrar antes de cobrar. Retorna se dá para seguir.
Future<bool> _pedirChavePix(BuildContext context) async {
  final cadastrar = await confirmar(
    context,
    titulo: 'Cadastre sua chave Pix',
    mensagem: 'A cobrança vai com a sua chave Pix para a família copiar e pagar. Quer cadastrar agora?',
    acao: 'Cadastrar',
    cancelar: 'Cobrar sem Pix',
  );
  if (!context.mounted) return false;
  if (cadastrar) await abrirFolha(context, const FormularioChavePix());
  return true;
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
    final informadas = store.informadas;
    final faltando = store.alunosAtivos.length - todas.length;
    final aVencer = store.vencendoEm(7);

    return PaginaIOS(
      titulo: 'Finanças',
      filhos: [
        _CartaoMes(mes: _mes, resumo: r, pagas: pagas.length, total: todas.length),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Bloco(rotulo: 'Recebido', valor: moeda(r.recebido), cor: p.verde, icone: Icons.check_circle_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Bloco(rotulo: 'A receber', valor: moeda(r.aReceber), cor: p.azul, icone: Icons.schedule_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Bloco(rotulo: 'Atrasado', valor: moeda(r.emAtraso), cor: p.vermelho, icone: Icons.error_rounded),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'AÇÕES',
            style: TextStyle(color: p.textoSuave, fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          padding: EdgeInsets.zero,
          children: [
            _Acao(
              icone: Icons.campaign_rounded,
              titulo: 'Cobrar atrasados',
              detalhe: atrasadas.isEmpty ? 'Ninguém atrasado 🎉' : '${atrasadas.length} família(s)',
              cor: p.vermelho,
              aoTocar: atrasadas.isEmpty
                  ? null
                  : () async {
                      if (store.chavePix == null && !await _pedirChavePix(context)) return;
                      if (!context.mounted) return;
                      if (await confirmar(
                        context,
                        titulo: 'Cobrar ${atrasadas.length} família(s)?',
                        mensagem:
                            'Cada família recebe um aviso no app com o valor${store.chavePix == null ? '' : ' e a sua chave Pix para copiar'}.',
                        acao: 'Cobrar',
                      )) {
                        final n = store.cobrarAtrasadas();
                        if (context.mounted) {
                          avisar(context, '$n família(s) cobradas no app', icone: Icons.campaign_rounded, cor: p.vermelho);
                        }
                      }
                    },
            ),
            _Acao(
              icone: Icons.alarm_rounded,
              titulo: 'Lembrar antes',
              detalhe: aVencer == 0 ? 'Nada vencendo em 7 dias' : '$aVencer vencem em até 7 dias',
              cor: p.ambar,
              aoTocar: () async {
                final dias = await escolherAcao<int>(
                  context,
                  titulo: 'Lembrar quem vence em…',
                  mensagem: 'Só recebe quem ainda não pagou.',
                  opcoes: [
                    for (final d in [3, 5, 7, 10])
                      OpcaoAcao('Até $d dias (${store.vencendoEm(d)} família(s))', d, icone: Icons.alarm_rounded),
                  ],
                );
                if (dias == null || !context.mounted) return;
                if (store.chavePix == null && !await _pedirChavePix(context)) return;
                final n = store.lembrarAntesDoVencimento(dias: dias);
                if (context.mounted) {
                  avisar(
                    context,
                    n == 0 ? 'Ninguém vence nesse prazo' : '$n família(s) lembradas',
                    icone: Icons.alarm_rounded,
                    cor: p.ambar,
                  );
                }
              },
            ),
            _Acao(
              icone: Icons.pix_rounded,
              titulo: store.chavePix == null ? 'Cadastrar Pix' : 'Chave Pix',
              detalhe: store.chavePix == null ? 'Vai junto nas cobranças' : '${store.chavePix!.tipo.rotulo}: ${store.chavePix!.valor}',
              cor: p.verde,
              aoTocar: () => abrirFolha(context, const FormularioChavePix()),
            ),
            informadas.isNotEmpty
                ? _Acao(
                    icone: Icons.fact_check_rounded,
                    titulo: 'Confirmar pagos',
                    detalhe: '${informadas.length} informado(s) pelas famílias',
                    cor: p.roxo,
                    aoTocar: () => acoesCobranca(context, informadas.first),
                  )
                : _Acao(
                    icone: Icons.post_add_rounded,
                    titulo: 'Gerar mensalidades',
                    detalhe: faltando > 0 ? '$faltando faltando em ${mesCurto(_mes)}' : 'Tudo gerado em ${mesCurto(_mes)}',
                    cor: p.azul,
                    aoTocar: faltando > 0 ? () => avisar(context, '${store.gerarCobrancas(_mes)} mensalidade(s) gerada(s)') : null,
                  ),
          ],
        ),
        const SizedBox(height: 12),
        _Grafico(mesSelecionado: _mes, aoEscolher: (m) => setState(() => _mes = m)),
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
                    icone: _seg == 0 ? Icons.verified_rounded : Icons.inbox_rounded,
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

/// Cartão do mês: anel com o percentual recebido e o total previsto.
class _CartaoMes extends StatelessWidget {
  const _CartaoMes({required this.mes, required this.resumo, required this.pagas, required this.total});

  final DateTime mes;
  final ResumoMes resumo;
  final int pagas;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final pct = resumo.percentual.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(colors: p.heroi, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${(v * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recebido em ${mesAno(mes)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    moeda(resumo.recebido),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1),
                  ),
                ),
                Text('de ${moeda(resumo.esperado)} previstos', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(99)),
                  child: Text(
                    '$pagas de $total pagas',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
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

class _Bloco extends StatelessWidget {
  const _Bloco({required this.rotulo, required this.valor, required this.cor, required this.icone});

  final String rotulo;
  final String valor;
  final Color cor;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.suave(cor), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.texto),
            ),
          ),
          Text(
            rotulo,
            style: TextStyle(color: cor, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Acao extends StatelessWidget {
  const _Acao({required this.icone, required this.titulo, required this.detalhe, required this.cor, required this.aoTocar});

  final IconData icone;
  final String titulo;
  final String detalhe;
  final Color cor;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Tocavel(
      aoTocar: aoTocar,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: aoTocar == null ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.cartao,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(11)),
                child: Icon(icone, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(
                titulo,
                style: TextStyle(fontWeight: FontWeight.w800, color: p.texto, fontSize: 15),
              ),
              Text(
                detalhe,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.textoSuave, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cadastro da chave Pix do motorista.
class FormularioChavePix extends StatefulWidget {
  const FormularioChavePix({super.key});

  @override
  State<FormularioChavePix> createState() => _FormularioChavePixState();
}

class _FormularioChavePixState extends State<FormularioChavePix> {
  late final VanStore _store = VanScope.read(context);
  late TipoChavePix _tipo = _store.chavePix?.tipo ?? TipoChavePix.telefone;
  late final _valor = TextEditingController(text: _store.chavePix?.valor ?? '');
  late final _titular = TextEditingController(text: _store.chavePix?.titular ?? _store.nomeMotorista);

  @override
  void dispose() {
    _valor.dispose();
    _titular.dispose();
    super.dispose();
  }

  String? get _erro {
    final v = _valor.text.trim();
    if (v.isEmpty) return null;
    final digitos = v.replaceAll(RegExp(r'\D'), '');
    return switch (_tipo) {
      TipoChavePix.cpf => digitos.length == 11 ? null : 'CPF com 11 números',
      TipoChavePix.telefone => digitos.length >= 10 && digitos.length <= 11 ? null : 'Celular com DDD',
      TipoChavePix.email => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v) ? null : 'E-mail inválido',
      TipoChavePix.aleatoria => v.length >= 32 ? null : 'Chave aleatória completa',
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final valido = _valor.text.trim().isNotEmpty && _erro == null && _titular.text.trim().isNotEmpty;
    return Formulario(
      titulo: 'Chave Pix',
      podeSalvar: valido,
      rotuloSalvar: _store.chavePix == null ? 'Adicionar chave' : 'Salvar chave',
      aoSalvar: () {
        final nova = _store.chavePix == null;
        _store.salvarChavePix(ChavePix(tipo: _tipo, valor: _valor.text.trim(), titular: _titular.text.trim()));
        Navigator.pop(context);
        avisar(
          context,
          nova ? 'Nova chave Pix adicionada ✓ As famílias foram avisadas.' : 'Chave Pix atualizada ✓ As famílias foram avisadas.',
          icone: Icons.pix_rounded,
        );
      },
      campos: [
        Text('Ela vai junto nas cobranças e lembretes, para a família copiar e pagar.', style: TextStyle(color: p.textoSuave)),
        const SizedBox(height: 12),
        Segmentos<TipoChavePix>(
          valor: _tipo,
          opcoes: {for (final t in TipoChavePix.values) t: t.rotulo},
          aoMudar: (v) => setState(() => _tipo = v),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: _valor,
            keyboardType: switch (_tipo) {
              TipoChavePix.cpf || TipoChavePix.telefone => TextInputType.number,
              TipoChavePix.email => TextInputType.emailAddress,
              TipoChavePix.aleatoria => TextInputType.text,
            },
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: 'Chave', errorText: _erro, prefixIcon: const Icon(Icons.pix_rounded)),
          ),
        ),
        CampoTexto(controle: _titular, rotulo: 'Nome do titular', icone: Icons.person_rounded, aoMudar: () => setState(() {})),
      ],
    );
  }
}

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
          Text(
            'de ${moeda(atual.esperado)} previstos · inadimplência ${(store.inadimplencia(mesSelecionado) * 100).round()}%',
            style: TextStyle(color: p.textoSuave, fontSize: 13),
          ),
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
        child: Container(
          decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
