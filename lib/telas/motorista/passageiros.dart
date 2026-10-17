import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import '../comum/endereco_tela.dart';
import '../comum/escolas.dart';
import 'convite.dart';
import 'financeiro.dart';

void abrirPassageiro(BuildContext context, Aluno a) => abrir(context, PassageiroTela(alunoId: a.id));

void copiarCodigo(BuildContext context, String codigo) {
  Clipboard.setData(ClipboardData(text: 'Olá! Para acompanhar a van escolar pelo Van Connect, use o código $codigo no app.'));
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
          Segmentos<int>(
            valor: seg,
            opcoes: {0: 'Ativos', 1: store.solicitacoes.isEmpty ? 'Pedidos' : 'Pedidos (${store.solicitacoes.length})'},
            aoMudar: (v) => widget.segmento.value = v,
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
    final lista =
        store.alunos.where((a) => q.isEmpty || a.nome.toLowerCase().contains(q) || a.responsavel.nome.toLowerCase().contains(q)).toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
    final porTurno = <Turno, List<Aluno>>{};
    for (final a in lista) {
      porTurno.putIfAbsent(a.turno, () => []).add(a);
    }

    return Column(
      key: const ValueKey('ativos'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (v) => setState(() => _busca = v),
          style: TextStyle(color: p.texto),
          decoration: const InputDecoration(hintText: 'Buscar aluno ou responsável', prefixIcon: Icon(Icons.search_rounded)),
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
              Botao(
                'Compartilhar',
                compacto: true,
                estilo: EstiloBotao.secundario,
                icone: CupertinoIcons.share,
                aoTocar: () => copiarCodigo(context, store.codigoVan),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Para quem chega sozinho: a família digita este código e o pedido aparece aqui para você aprovar. '
            'Para quem você já atende, use Convidar na ficha do aluno: vai com filho e rota, sem aprovação.',
            style: TextStyle(color: p.textoSuave, fontSize: 12.5),
          ),
        ),
        if (store.solicitacoes.isEmpty)
          const Vazio(icone: CupertinoIcons.tray, titulo: 'Nenhum pedido', texto: 'Novos pedidos aparecem aqui.')
        else
          for (final s in store.solicitacoes)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _CartaoPedido(pedido: s),
            ),
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
        fim: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (aluno.cuidados.isNotEmpty) Icon(CupertinoIcons.heart_circle_fill, color: p.vermelho, size: 18),
            if (ausente) ...[const SizedBox(width: 4), Icon(CupertinoIcons.calendar_badge_minus, color: p.laranja, size: 18)],
            if (atrasada) ...[const SizedBox(width: 4), Icon(CupertinoIcons.exclamationmark_circle_fill, color: p.vermelho, size: 18)],
          ],
        ),
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
    final escola = pedido.escolaId == null ? null : store.escola(pedido.escolaId!);
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
                    Text(pedido.turno.rotulo, style: TextStyle(color: p.textoSuave)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar pedido',
                onPressed: () => abrirFolha(context, _EditarPedido(pedido: pedido)),
                icon: Icon(Icons.edit_outlined, color: p.azul),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                escola == null ? Icons.help_outline_rounded : Icons.school_rounded,
                size: 18,
                color: escola == null ? p.vermelho : p.verde,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  escola == null
                      ? 'Colégio "${pedido.escolaInformada}" não confirmado'
                      : '${escola.nome}${pedido.escolaInformada == escola.nome ? '' : ' (pai escreveu "${pedido.escolaInformada}")'}',
                  style: TextStyle(color: escola == null ? p.vermelho : p.texto, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${pedido.responsavel.parentesco}: ${pedido.responsavel.nome} · ${pedido.responsavel.telefone}\n${pedido.endereco}',
            style: TextStyle(color: p.textoSuave, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Botao(
                  'Recusar',
                  estilo: EstiloBotao.destrutivo,
                  compacto: true,
                  aoTocar: () async {
                    if (await confirmar(
                      context,
                      titulo: 'Recusar pedido?',
                      mensagem: '${pedido.responsavel.nome} será avisado(a).',
                      acao: 'Recusar',
                      destrutiva: true,
                    )) {
                      store.recusar(pedido);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Botao(
                  pedido.prontoParaAprovar ? 'Aceitar' : 'Revisar e aceitar',
                  compacto: true,
                  icone: Icons.check_rounded,
                  aoTocar: () {
                    // Sem colégio confirmado, abre a revisão antes de aceitar.
                    if (!pedido.prontoParaAprovar) {
                      abrirFolha(context, _EditarPedido(pedido: pedido, aceitarAoSalvar: true));
                      return;
                    }
                    final rotas = store.aprovar(pedido);
                    avisar(
                      context,
                      '${primeiroNome(pedido.nomeAluno)} entrou${rotas.isEmpty ? '' : ' em ${rotas.map((r) => r.nome).join(' e ')}'}',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// O motorista corrige o pedido (o pai pode ter mandado algo errado) e confirma o colégio.
class _EditarPedido extends StatefulWidget {
  const _EditarPedido({required this.pedido, this.aceitarAoSalvar = false});

  final Solicitacao pedido;
  final bool aceitarAoSalvar;

  @override
  State<_EditarPedido> createState() => _EditarPedidoState();
}

class _EditarPedidoState extends State<_EditarPedido> {
  late final _nome = TextEditingController(text: widget.pedido.nomeAluno);
  late final _responsavel = TextEditingController(text: widget.pedido.responsavel.nome);
  late final _telefone = TextEditingController(text: widget.pedido.responsavel.telefone);
  late String? _escolaId = widget.pedido.escolaId;
  late Turno _turno = widget.pedido.turno;
  late Endereco? _endereco = widget.pedido.enderecoCompleto;

  @override
  void dispose() {
    for (final c in [_nome, _responsavel, _telefone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final escola = _escolaId == null ? null : store.escola(_escolaId!);
    return Formulario(
      titulo: widget.aceitarAoSalvar ? 'Revisar e aceitar' : 'Editar pedido',
      rotuloSalvar: widget.aceitarAoSalvar ? 'Salvar e aceitar' : 'Salvar',
      podeSalvar: _nome.text.trim().isNotEmpty && (!widget.aceitarAoSalvar || _escolaId != null),
      aoSalvar: () {
        store.atualizarSolicitacao(
          widget.pedido,
          nomeAluno: _nome.text.trim(),
          escolaId: _escolaId,
          turno: _turno,
          endereco: _endereco,
          nomeResponsavel: _responsavel.text.trim(),
          telefone: _telefone.text.trim(),
        );
        Navigator.pop(context);
        if (widget.aceitarAoSalvar && widget.pedido.prontoParaAprovar) {
          final rotas = store.aprovar(widget.pedido);
          avisar(
            context,
            '${primeiroNome(widget.pedido.nomeAluno)} entrou${rotas.isEmpty ? '' : ' em ${rotas.map((r) => r.nome).join(' e ')}'}',
          );
        } else {
          avisar(context, 'Pedido atualizado');
        }
      },
      campos: [
        Cartao(
          cor: p.suave(p.azul),
          padding: const EdgeInsets.all(12),
          child: Text(
            'O responsável informou o colégio "${widget.pedido.escolaInformada}". Confirme qual é o colégio certo.',
            style: TextStyle(color: p.azul, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 12),
        CampoTexto(controle: _nome, rotulo: 'Nome do aluno', icone: Icons.person_rounded, aoMudar: () => setState(() {})),
        CampoSelecao(
          rotulo: 'Colégio',
          valor: escola?.nome,
          detalhe: escola?.endereco,
          icone: Icons.school_rounded,
          erro: _escolaId == null ? 'Selecione o colégio' : null,
          aoTocar: () async {
            final e = await selecionarEscola(context, selecionadaId: _escolaId, sugestao: widget.pedido.escolaInformada);
            if (e != null) setState(() => _escolaId = e.id);
          },
        ),
        Segmentos<Turno>(valor: _turno, opcoes: {for (final t in Turno.values) t: t.rotulo}, aoMudar: (v) => setState(() => _turno = v)),
        const SizedBox(height: 10),
        CartaoEndereco(
          endereco: _endereco,
          rotulo: _endereco == null ? 'Endereço informado: ${widget.pedido.endereco}' : 'Endereço de embarque',
          aoTocar: () async {
            final e = await escolherEndereco(context, inicial: _endereco, titulo: 'Endereço de embarque');
            if (e != null) setState(() => _endereco = e);
          },
        ),
        const SizedBox(height: 10),
        CampoTexto(controle: _responsavel, rotulo: 'Nome do responsável', icone: Icons.family_restroom_rounded),
        CampoTexto(controle: _telefone, rotulo: 'WhatsApp', icone: Icons.phone_rounded, teclado: TextInputType.phone),
      ],
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
        Text(
          a.nome,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(
          '${escola.nome} · ${a.turno.rotulo}',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.textoSuave),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Acao(
                icone: CupertinoIcons.phone_fill,
                rotulo: 'Ligar',
                aoTocar: () {
                  Clipboard.setData(ClipboardData(text: a.responsavel.telefone));
                  avisar(context, 'Telefone copiado', icone: CupertinoIcons.phone_fill);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Acao(icone: CupertinoIcons.paperplane_fill, rotulo: 'Convidar', aoTocar: () => abrirConvite(context, a)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Acao(
                icone: CupertinoIcons.money_dollar_circle_fill,
                rotulo: 'Cobrar',
                aoTocar: () {
                  final aberta = store.cobrancasDo(a.id).where((c) => c.status(hoje) != StatusCobranca.paga).firstOrNull;
                  if (aberta == null) {
                    avisar(context, 'Nada em aberto para ${a.primeiro} 🎉');
                  } else {
                    acoesCobranca(context, aberta);
                  }
                },
              ),
            ),
          ],
        ),
        if (a.cuidados.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Cartao(
              cor: p.suave(p.vermelho),
              child: Row(
                children: [
                  Icon(CupertinoIcons.heart_circle_fill, color: p.vermelho),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a.cuidados,
                      style: TextStyle(color: p.vermelho, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Secao(
          titulo: 'Responsável',
          filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.person_fill, cor: p.azul),
              titulo: a.responsavel.nome,
              subtitulo: a.responsavel.parentesco,
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.phone_fill, cor: p.verde),
              titulo: a.responsavel.telefone,
            ),
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
            Linha(
              inicio: IconeApp(CupertinoIcons.house_fill, cor: p.laranja),
              titulo: a.endereco,
              subtitulo: 'Embarque e desembarque',
            ),
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
                    await confirmar(
                      context,
                      titulo: 'Pausar ${a.primeiro}?',
                      mensagem: 'Sai das rotas e das próximas cobranças até ser reativado.',
                      acao: 'Pausar',
                      destrutiva: true,
                    )) {
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
      child: Column(
        children: [
          Icon(icone, color: p.azul, size: 22),
          const SizedBox(height: 4),
          Text(
            rotulo,
            style: TextStyle(color: p.azul, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Cadastro manual: nome, colégio (selecionar ou cadastrar), turno, endereço pelo CEP
/// confirmado no mapa, responsável e mensalidade.
class _NovoPassageiro extends StatefulWidget {
  const _NovoPassageiro();

  @override
  State<_NovoPassageiro> createState() => _NovoPassageiroState();
}

class _NovoPassageiroState extends State<_NovoPassageiro> {
  final _nome = TextEditingController();
  final _responsavel = TextEditingController();
  final _telefone = TextEditingController();
  final _valor = TextEditingController(text: '320');
  final _cuidados = TextEditingController();
  String? _escolaId;
  Turno _turno = Turno.manha;
  Endereco? _endereco;
  bool _tentouSalvar = false;

  @override
  void dispose() {
    for (final c in [_nome, _responsavel, _telefone, _valor, _cuidados]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valido =>
      _nome.text.trim().isNotEmpty &&
      _escolaId != null &&
      _endereco != null &&
      _responsavel.text.trim().isNotEmpty &&
      _telefone.text.trim().isNotEmpty;

  void _salvar() {
    if (!_valido) {
      setState(() => _tentouSalvar = true);
      return;
    }
    final store = VanScope.read(context);
    final rotas = store.adicionarAluno(
      nome: _nome.text.trim(),
      serie: '—',
      escolaId: _escolaId!,
      turno: _turno,
      responsavel: Responsavel(nome: _responsavel.text.trim(), telefone: _telefone.text.trim(), parentesco: 'Responsável'),
      endereco: _endereco!.resumo,
      enderecoCompleto: _endereco,
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

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final escola = _escolaId == null ? null : store.escola(_escolaId!);
    return Formulario(
      titulo: 'Novo passageiro',
      rotuloSalvar: 'Salvar e convidar família',
      podeSalvar: true,
      aoSalvar: _salvar,
      campos: [
        CampoTexto(controle: _nome, rotulo: 'Nome do aluno', icone: Icons.person_rounded, aoMudar: () => setState(() {})),
        CampoSelecao(
          rotulo: 'Colégio',
          valor: escola?.nome,
          detalhe: escola == null ? null : '${escola.endereco} · ${horario(escola.entrada)}–${horario(escola.saida)}',
          icone: Icons.school_rounded,
          erro: _tentouSalvar && _escolaId == null ? 'Selecione ou cadastre o colégio' : null,
          aoTocar: () async {
            final e = await selecionarEscola(context, selecionadaId: _escolaId);
            if (e != null) setState(() => _escolaId = e.id);
          },
        ),
        Segmentos<Turno>(valor: _turno, opcoes: {for (final t in Turno.values) t: t.rotulo}, aoMudar: (v) => setState(() => _turno = v)),
        const SizedBox(height: 10),
        CartaoEndereco(
          endereco: _endereco,
          rotulo: 'Endereço de embarque',
          aoTocar: () async {
            final e = await escolherEndereco(
              context,
              inicial: _endereco,
              titulo: 'Endereço de embarque',
              ajuda: 'Use o CEP da casa e confirme no mapa: é ali que a van vai parar.',
            );
            if (e != null) setState(() => _endereco = e);
          },
        ),
        if (_tentouSalvar && _endereco == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Informe o endereço pelo CEP e confirme no mapa', style: TextStyle(color: p.vermelho, fontSize: 12.5)),
          ),
        const SizedBox(height: 12),
        CampoTexto(
          controle: _responsavel,
          rotulo: 'Nome do responsável',
          icone: Icons.family_restroom_rounded,
          aoMudar: () => setState(() {}),
        ),
        CampoTexto(
          controle: _telefone,
          rotulo: 'WhatsApp',
          icone: Icons.phone_rounded,
          teclado: TextInputType.phone,
          aoMudar: () => setState(() {}),
        ),
        CampoTexto(
          controle: _valor,
          rotulo: 'Mensalidade (R\$)',
          icone: Icons.payments_rounded,
          teclado: const TextInputType.numberWithOptions(decimal: true),
        ),
        CampoTexto(controle: _cuidados, rotulo: 'Cuidados de saúde (opcional)', icone: Icons.favorite_rounded),
      ],
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
  late final _valor = TextEditingController(text: widget.aluno.valorMensal.toStringAsFixed(0));
  late final _cuidados = TextEditingController(text: widget.aluno.cuidados);
  late String _escolaId = widget.aluno.escolaId;
  late Turno _turno = widget.aluno.turno;
  late int _vencimento = widget.aluno.diaVencimento;
  late Endereco? _endereco = widget.aluno.enderecoCompleto;

  @override
  void dispose() {
    for (final c in [_nome, _valor, _cuidados]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    final escola = store.escola(_escolaId);
    return Formulario(
      titulo: 'Editar aluno',
      podeSalvar: _nome.text.trim().isNotEmpty,
      aoSalvar: () {
        store.atualizarAluno(
          widget.aluno,
          nome: _nome.text.trim(),
          escolaId: _escolaId,
          turno: _turno,
          valorMensal: double.tryParse(_valor.text.replaceAll(',', '.')),
          diaVencimento: _vencimento,
          cuidados: _cuidados.text.trim(),
          enderecoCompleto: _endereco != widget.aluno.enderecoCompleto ? _endereco : null,
        );
        Navigator.pop(context);
        avisar(context, 'Dados atualizados (rotas ajustadas)');
      },
      campos: [
        CampoTexto(controle: _nome, rotulo: 'Nome', icone: Icons.person_rounded, aoMudar: () => setState(() {})),
        CampoSelecao(
          rotulo: 'Colégio',
          valor: escola.nome,
          detalhe: escola.endereco,
          icone: Icons.school_rounded,
          aoTocar: () async {
            final e = await selecionarEscola(context, selecionadaId: _escolaId);
            if (e != null) setState(() => _escolaId = e.id);
          },
        ),
        Segmentos<Turno>(valor: _turno, opcoes: {for (final t in Turno.values) t: t.rotulo}, aoMudar: (v) => setState(() => _turno = v)),
        const SizedBox(height: 10),
        CartaoEndereco(
          endereco: _endereco,
          rotulo: _endereco == null ? 'Endereço atual: ${widget.aluno.endereco} (confirmar pelo CEP)' : 'Endereço de embarque',
          aoTocar: () async {
            final e = await escolherEndereco(context, inicial: _endereco, titulo: 'Endereço de embarque');
            if (e != null) setState(() => _endereco = e);
          },
        ),
        const SizedBox(height: 10),
        CampoTexto(
          controle: _valor,
          rotulo: 'Mensalidade (R\$)',
          icone: Icons.payments_rounded,
          teclado: const TextInputType.numberWithOptions(decimal: true),
        ),
        Secao(
          filhos: [
            Linha(
              inicio: IconeApp(Icons.event_rounded, cor: p.azul),
              titulo: 'Vencimento',
              fim: Text('Dia $_vencimento', style: TextStyle(color: p.textoSuave)),
              aoTocar: () async {
                final d = await escolherAcao<int>(
                  context,
                  titulo: 'Dia do vencimento',
                  opcoes: [
                    for (final d in [5, 10, 15, 20, 25]) OpcaoAcao('Dia $d', d),
                  ],
                );
                if (d != null) setState(() => _vencimento = d);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        CampoTexto(controle: _cuidados, rotulo: 'Cuidados de saúde (opcional)', icone: Icons.favorite_rounded),
      ],
    );
  }
}
