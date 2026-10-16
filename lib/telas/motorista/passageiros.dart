import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import 'convite.dart';
import 'financeiro.dart';

void abrirPassageiro(BuildContext context, Aluno a) => abrir(context, PassageiroTela(alunoId: a.id));

void copiarCodigo(BuildContext context, String codigo) {
  Clipboard.setData(ClipboardData(
    text: 'Olá! Para acompanhar a van escolar pelo Van Connect, use o código $codigo no app.',
  ));
  avisar(context, 'Convite com o código $codigo copiado', icone: CupertinoIcons.doc_on_doc_fill);
}

class PassageirosTela extends StatefulWidget {
  const PassageirosTela({super.key, required this.segmento, this.voltar = false});

  /// 0 = ativos, 1 = pedidos. Controlado de fora para a tela Hoje abrir direto nos pedidos.
  final ValueNotifier<int> segmento;
  final bool voltar;

  @override
  State<PassageirosTela> createState() => _PassageirosTelaState();
}

class _PassageirosTelaState extends State<PassageirosTela> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;

    return ValueListenableBuilder<int>(
      valueListenable: widget.segmento,
      builder: (context, seg, _) => PaginaIOS(
        titulo: 'Alunos',
        voltar: widget.voltar,
        acao: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => abrirFolha(context, const _NovoPassageiro()),
          child: Icon(CupertinoIcons.add_circled_solid, size: 28, color: p.azul),
        ),
        filhos: [
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: seg,
              backgroundColor: p.preenchimento,
              thumbColor: p.escuro ? p.elevado : Colors.white,
              onValueChanged: (v) => widget.segmento.value = v ?? 0,
              children: {
                0: const Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Text('Ativos')),
                1: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Text(store.solicitacoes.isEmpty ? 'Pedidos' : 'Pedidos (${store.solicitacoes.length})'),
                ),
              },
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: seg == 0 ? _ativos(context, store, p) : _pedidos(context, store, p),
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget _ativos(BuildContext context, VanStore store, Paleta p) {
    final q = _busca.toLowerCase();
    final lista = store.alunos
        .where((a) => q.isEmpty || a.nome.toLowerCase().contains(q) || a.responsavel.nome.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final porTurno = <Turno, List<Aluno>>{};
    for (final a in lista) {
      porTurno.putIfAbsent(a.turno, () => []).add(a);
    }

    return Column(
      key: const ValueKey('ativos'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoSearchTextField(
          placeholder: 'Buscar aluno ou responsável',
          onChanged: (v) => setState(() => _busca = v),
          style: TextStyle(color: p.texto),
          backgroundColor: p.preenchimento,
        ),
        if (lista.isEmpty) const Vazio(icone: CupertinoIcons.search, titulo: 'Ninguém encontrado'),
        for (final t in Turno.values)
          if (porTurno[t] case final grupo?)
            Secao(
              titulo: '${t.rotulo} · ${grupo.length}',
              filhos: [for (final a in grupo) _LinhaAluno(aluno: a)],
            ),
      ],
    );
  }

  Widget _pedidos(BuildContext context, VanStore store, Paleta p) {
    return Column(
      key: const ValueKey('pedidos'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Cartao(
          child: Row(
            children: [
              IconeApp(CupertinoIcons.qrcode, cor: p.azul, tamanho: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Código geral da van', style: TextStyle(color: p.textoSuave, fontSize: 13)),
                    Text(store.codigoVan, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
              ),
              Botao('Compartilhar', compacto: true, estilo: EstiloBotao.secundario, icone: CupertinoIcons.share,
                  aoTocar: () => copiarCodigo(context, store.codigoVan)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text('Para quem chega sozinho: a família digita este código e o pedido aparece aqui para você aprovar. '
              'Para quem você já atende, use Convidar na ficha do aluno: vai com filho e rota, sem aprovação.',
              style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
        ),
        if (store.solicitacoes.isEmpty)
          const Vazio(icone: CupertinoIcons.tray, titulo: 'Nenhum pedido', texto: 'Novos pedidos aparecem aqui.')
        else
          for (final s in store.solicitacoes)
            Padding(padding: const EdgeInsets.only(top: 14), child: _CartaoPedido(pedido: s)),
      ],
    );
  }
}

class _LinhaAluno extends StatelessWidget {
  const _LinhaAluno({required this.aluno});

  final Aluno aluno;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final ausente = store.ausenciasDeHoje.any((x) => x.alunoId == aluno.id);
    final atrasada = store.atrasadas.any((c) => c.alunoId == aluno.id);
    return Opacity(
      opacity: aluno.ativo ? 1 : 0.45,
      child: Linha(
        inicio: Avatar(aluno.nome, tamanho: 36),
        titulo: aluno.nome,
        subtitulo: aluno.familiaConectada
            ? store.escola(aluno.escolaId).nome
            : '${store.escola(aluno.escolaId).nome} · ${store.conviteAtivoDe(aluno.id) != null ? 'convite enviado' : 'família sem app'}',
        fim: Row(mainAxisSize: MainAxisSize.min, children: [
          if (aluno.cuidados.isNotEmpty) Icon(CupertinoIcons.heart_circle_fill, color: p.vermelho, size: 18),
          if (ausente) ...[const SizedBox(width: 4), Icon(CupertinoIcons.calendar_badge_minus, color: p.laranja, size: 18)],
          if (atrasada) ...[const SizedBox(width: 4), Icon(CupertinoIcons.exclamationmark_circle_fill, color: p.vermelho, size: 18)],
        ]),
        aoTocar: () => abrirPassageiro(context, aluno),
      ),
    );
  }
}

class _CartaoPedido extends StatelessWidget {
  const _CartaoPedido({required this.pedido});

  final Solicitacao pedido;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(pedido.nomeAluno, tamanho: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pedido.nomeAluno, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text('${store.escola(pedido.escolaId).nome} · ${pedido.turno.rotulo}', style: TextStyle(color: p.textoSuave)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${pedido.responsavel.parentesco}: ${pedido.responsavel.nome} · ${pedido.responsavel.telefone}\n${pedido.endereco}',
              style: TextStyle(color: p.textoSuave, height: 1.4)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Botao('Recusar', estilo: EstiloBotao.destrutivo, compacto: true, aoTocar: () async {
                  if (await confirmar(context,
                      titulo: 'Recusar pedido?',
                      mensagem: '${pedido.responsavel.nome} será avisado(a).',
                      acao: 'Recusar',
                      destrutiva: true)) {
                    store.recusar(pedido);
                  }
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Botao('Aceitar', compacto: true, icone: CupertinoIcons.checkmark_alt, aoTocar: () {
                  final rotas = store.aprovar(pedido);
                  avisar(context,
                      '${primeiroNome(pedido.nomeAluno)} entrou${rotas.isEmpty ? '' : ' em ${rotas.map((r) => r.nome).join(' e ')}'}');
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PassageiroTela extends StatelessWidget {
  const PassageiroTela({super.key, required this.alunoId});

  final String alunoId;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final a = store.aluno(alunoId);
    final escola = store.escola(a.escolaId);
    final hoje = DateTime.now();
    final ausencias = store.ausenciasFuturasDe(a.id);

    return PaginaIOS(
      titulo: a.primeiro,
      voltar: true,
      acao: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => abrirFolha(context, _EditarAluno(aluno: a)),
        child: const Text('Editar', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      filhos: [
        Center(child: Avatar(a.nome, tamanho: 84)),
        const SizedBox(height: 10),
        Text(a.nome, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        Text('${escola.nome} · ${a.turno.rotulo}', textAlign: TextAlign.center, style: TextStyle(color: p.textoSuave)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _Acao(icone: CupertinoIcons.phone_fill, rotulo: 'Ligar', aoTocar: () {
              Clipboard.setData(ClipboardData(text: a.responsavel.telefone));
              avisar(context, 'Telefone copiado', icone: CupertinoIcons.phone_fill);
            })),
            const SizedBox(width: 10),
            Expanded(child: _Acao(icone: CupertinoIcons.paperplane_fill, rotulo: 'Convidar', aoTocar: () => abrirConvite(context, a))),
            const SizedBox(width: 10),
            Expanded(child: _Acao(icone: CupertinoIcons.money_dollar_circle_fill, rotulo: 'Cobrar', aoTocar: () {
              final aberta = store.cobrancasDo(a.id).where((c) => c.status(hoje) != StatusCobranca.paga).firstOrNull;
              if (aberta == null) {
                avisar(context, 'Nada em aberto para ${a.primeiro} 🎉');
              } else {
                acoesCobranca(context, aberta);
              }
            })),
          ],
        ),
        if (a.cuidados.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Cartao(
              cor: p.suave(p.vermelho),
              child: Row(children: [
                Icon(CupertinoIcons.heart_circle_fill, color: p.vermelho),
                const SizedBox(width: 10),
                Expanded(child: Text(a.cuidados, style: TextStyle(color: p.vermelho, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
        Secao(
          titulo: 'Responsável',
          filhos: [
            Linha(inicio: IconeApp(CupertinoIcons.person_fill, cor: p.azul), titulo: a.responsavel.nome, subtitulo: a.responsavel.parentesco),
            Linha(inicio: IconeApp(CupertinoIcons.phone_fill, cor: p.verde), titulo: a.responsavel.telefone),
            Linha(
              inicio: IconeApp(
                a.familiaConectada ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.paperplane_fill,
                cor: a.familiaConectada ? p.verde : p.azul,
              ),
              titulo: situacaoFamilia(store, a),
              subtitulo: a.familiaConectada ? 'Acompanha a van e avisa ausências' : 'Toque para convidar pelo WhatsApp',
              corTitulo: a.familiaConectada ? null : p.azul,
              aoTocar: () => abrirConvite(context, a),
            ),
          ],
        ),
        Secao(
          titulo: 'Transporte',
          filhos: [
            Linha(inicio: IconeApp(CupertinoIcons.house_fill, cor: p.laranja), titulo: a.endereco, subtitulo: 'Embarque e desembarque'),
            Linha(
              inicio: const IconeApp(CupertinoIcons.book_fill, cor: Paleta.marinhoMarca),
              titulo: escola.nome,
              subtitulo: 'Entrada ${horario(escola.entrada)} · Saída ${horario(escola.saida)}',
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.creditcard_fill, cor: p.roxo),
              titulo: moeda(a.valorMensal),
              subtitulo: 'Mensalidade · vence dia ${a.diaVencimento}',
            ),
          ],
        ),
        if (ausencias.isNotEmpty)
          Secao(
            titulo: 'Ausências avisadas',
            filhos: [
              for (final x in ausencias)
                Linha(
                  inicio: IconeApp(CupertinoIcons.calendar_badge_minus, cor: p.laranja),
                  titulo: capitalizar(dataExtenso(x.data)),
                  subtitulo: [x.rotuloSentido, if (x.motivo.isNotEmpty) x.motivo].join(' · '),
                ),
            ],
          ),
        Secao(
          titulo: 'Mensalidades',
          filhos: [
            for (final c in store.cobrancasDo(a.id).take(4))
              Linha(
                titulo: capitalizar(mesAno(c.competencia)),
                subtitulo: moeda(c.valor),
                fim: seloCobranca(context, c.status(hoje)),
                aoTocar: () => acoesCobranca(context, c),
                seta: false,
              ),
          ],
          recuo: 14,
        ),
        Secao(
          filhos: [
            Linha(
              titulo: a.ativo ? 'Pausar transporte' : 'Reativar transporte',
              corTitulo: a.ativo ? p.vermelho : p.azul,
              seta: false,
              aoTocar: () async {
                if (!a.ativo ||
                    await confirmar(context,
                        titulo: 'Pausar ${a.primeiro}?',
                        mensagem: 'Sai das rotas e das próximas cobranças até ser reativado.',
                        acao: 'Pausar',
                        destrutiva: true)) {
                  store.alternarAtivo(a);
                }
              },
            ),
          ],
          recuo: 14,
        ),
      ],
    );
  }
}

class _Acao extends StatelessWidget {
  const _Acao({required this.icone, required this.rotulo, required this.aoTocar});

  final IconData icone;
  final String rotulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Cartao(
      aoTocar: aoTocar,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Icon(icone, color: p.azul, size: 22),
        const SizedBox(height: 4),
        Text(rotulo, style: TextStyle(color: p.azul, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Cadastro manual enxuto: só o essencial. O caminho preferido é a família pedir pelo código.
class _NovoPassageiro extends StatefulWidget {
  const _NovoPassageiro();

  @override
  State<_NovoPassageiro> createState() => _NovoPassageiroState();
}

class _NovoPassageiroState extends State<_NovoPassageiro> {
  final _nome = TextEditingController();
  final _endereco = TextEditingController();
  final _responsavel = TextEditingController();
  final _telefone = TextEditingController();
  final _valor = TextEditingController(text: '320');
  final _cuidados = TextEditingController();
  String _escolaId = 'e1';
  Turno _turno = Turno.manha;

  @override
  void dispose() {
    for (final c in [_nome, _endereco, _responsavel, _telefone, _valor, _cuidados]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valido => [_nome, _endereco, _responsavel, _telefone].every((c) => c.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;

    Widget campo(TextEditingController c, String rotulo, IconData icone, {TextInputType? teclado}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: c,
            keyboardType: teclado,
            textCapitalization: teclado == null ? TextCapitalization.words : TextCapitalization.none,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: rotulo, prefixIcon: Icon(icone, size: 20)),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              const Spacer(),
              const Text('Novo passageiro', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _valido
                    ? () {
                        final rotas = store.adicionarAluno(
                          nome: _nome.text.trim(),
                          serie: '—',
                          escolaId: _escolaId,
                          turno: _turno,
                          responsavel: Responsavel(nome: _responsavel.text.trim(), telefone: _telefone.text.trim(), parentesco: 'Responsável'),
                          endereco: _endereco.text.trim(),
                          valorMensal: double.tryParse(_valor.text.replaceAll(',', '.')) ?? 0,
                          diaVencimento: 10,
                          nascimento: DateTime(DateTime.now().year - 8),
                          cuidados: _cuidados.text.trim(),
                        );
                        // Contexto do navegador continua válido depois de fechar esta folha.
                        final nav = Navigator.of(context);
                        nav.pop();
                        avisar(nav.context, '${primeiroNome(_nome.text)} adicionado${rotas.isEmpty ? '' : ' às rotas da ${_turno.rotulo.toLowerCase()}'}');
                        // Fluxo direto: cadastrou → já convida a família.
                        abrirConvite(nav.context, store.alunos.last);
                      }
                    : null,
                child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
            Cartao(
              cor: p.suave(p.azul),
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(CupertinoIcons.lightbulb_fill, color: p.azul, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Depois de salvar, você já envia o convite para a família pelo WhatsApp.',
                      style: TextStyle(color: p.azul, fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            campo(_nome, 'Nome do aluno', CupertinoIcons.person_fill),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<String>(
                groupValue: _escolaId,
                backgroundColor: p.preenchimento,
                thumbColor: p.escuro ? p.elevado : Colors.white,
                onValueChanged: (v) => setState(() => _escolaId = v ?? _escolaId),
                children: {
                  for (final e in store.escolas)
                    e.id: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(e.nome, overflow: TextOverflow.ellipsis)),
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<Turno>(
                groupValue: _turno,
                backgroundColor: p.preenchimento,
                thumbColor: p.escuro ? p.elevado : Colors.white,
                onValueChanged: (v) => setState(() => _turno = v ?? _turno),
                children: {
                  for (final t in Turno.values) t: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(t.rotulo)),
                },
              ),
            ),
            const SizedBox(height: 10),
            campo(_endereco, 'Endereço de embarque', CupertinoIcons.house_fill),
            campo(_responsavel, 'Nome do responsável', CupertinoIcons.person_2_fill),
            campo(_telefone, 'WhatsApp', CupertinoIcons.phone_fill, teclado: TextInputType.phone),
            campo(_valor, 'Mensalidade (R\$)', CupertinoIcons.money_dollar, teclado: const TextInputType.numberWithOptions(decimal: true)),
            campo(_cuidados, 'Cuidados de saúde (opcional)', CupertinoIcons.heart_fill),
          ],
        ),
      ),
    );
  }
}

class _EditarAluno extends StatefulWidget {
  const _EditarAluno({required this.aluno});

  final Aluno aluno;

  @override
  State<_EditarAluno> createState() => _EditarAlunoState();
}

class _EditarAlunoState extends State<_EditarAluno> {
  late final _nome = TextEditingController(text: widget.aluno.nome);
  late final _endereco = TextEditingController(text: widget.aluno.endereco);
  late final _valor = TextEditingController(text: widget.aluno.valorMensal.toStringAsFixed(0));
  late final _cuidados = TextEditingController(text: widget.aluno.cuidados);
  late String _escolaId = widget.aluno.escolaId;
  late Turno _turno = widget.aluno.turno;
  late int _vencimento = widget.aluno.diaVencimento;

  @override
  void dispose() {
    for (final c in [_nome, _endereco, _valor, _cuidados]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    return Formulario(
      titulo: 'Editar aluno',
      podeSalvar: _nome.text.trim().isNotEmpty,
      aoSalvar: () {
        store.atualizarAluno(
          widget.aluno,
          nome: _nome.text.trim(),
          endereco: _endereco.text.trim(),
          escolaId: _escolaId,
          turno: _turno,
          valorMensal: double.tryParse(_valor.text.replaceAll(',', '.')),
          diaVencimento: _vencimento,
          cuidados: _cuidados.text.trim(),
        );
        Navigator.pop(context);
        avisar(context, 'Dados atualizados (rotas ajustadas)');
      },
      campos: [
        CampoTexto(controle: _nome, rotulo: 'Nome', icone: CupertinoIcons.person_fill, aoMudar: () => setState(() {})),
        CampoTexto(controle: _endereco, rotulo: 'Endereço de embarque', icone: CupertinoIcons.house_fill),
        Segmentos<String>(
          valor: _escolaId,
          opcoes: {for (final e in store.escolas) e.id: e.nome},
          aoMudar: (v) => setState(() => _escolaId = v),
        ),
        const SizedBox(height: 10),
        Segmentos<Turno>(
          valor: _turno,
          opcoes: {for (final t in Turno.values) t: t.rotulo},
          aoMudar: (v) => setState(() => _turno = v),
        ),
        const SizedBox(height: 10),
        CampoTexto(
          controle: _valor,
          rotulo: 'Mensalidade (R\$)',
          icone: CupertinoIcons.money_dollar,
          teclado: const TextInputType.numberWithOptions(decimal: true),
        ),
        Secao(filhos: [
          Linha(
            inicio: IconeApp(CupertinoIcons.calendar, cor: p.azul),
            titulo: 'Vencimento',
            fim: Text('Dia $_vencimento', style: TextStyle(color: p.textoSuave)),
            aoTocar: () async {
              final d = await escolherAcao<int>(context,
                  titulo: 'Dia do vencimento', opcoes: [for (final d in [5, 10, 15, 20, 25]) OpcaoAcao('Dia $d', d)]);
              if (d != null) setState(() => _vencimento = d);
            },
          ),
        ]),
        const SizedBox(height: 10),
        CampoTexto(controle: _cuidados, rotulo: 'Cuidados de saúde (opcional)', icone: CupertinoIcons.heart_fill),
      ],
    );
  }
}
