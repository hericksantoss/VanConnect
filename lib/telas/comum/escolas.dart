import 'package:flutter/material.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import 'endereco_tela.dart';

/// Campo que parece um input, mas abre uma escolha (ex.: "Selecionar colégio").
class CampoSelecao extends StatelessWidget {
  const CampoSelecao({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.aoTocar,
    this.detalhe,
    this.erro,
  });

  final String rotulo;
  final String? valor;
  final String? detalhe;
  final IconData icone;
  final VoidCallback aoTocar;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final vazio = valor == null || valor!.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Tocavel(
        aoTocar: aoTocar,
        escala: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: p.preenchimento,
            borderRadius: BorderRadius.circular(12),
            border: erro == null ? null : Border.all(color: p.vermelho, width: 1.2),
          ),
          child: Row(
            children: [
              Icon(icone, size: 20, color: p.textoSuave),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rotulo, style: TextStyle(color: p.textoSuave, fontSize: 12)),
                    Text(
                      vazio ? 'Toque para selecionar' : valor!,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: vazio ? p.azul : p.texto),
                    ),
                    if (detalhe != null) Text(detalhe!, style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
                    if (erro != null) Text(erro!, style: TextStyle(color: p.vermelho, fontSize: 12.5)),
                  ],
                ),
              ),
              Icon(Icons.unfold_more_rounded, color: p.cinza),
            ],
          ),
        ),
      ),
    );
  }
}

/// Escolha o colégio da lista; se não existir, cadastre na hora.
Future<Escola?> selecionarEscola(BuildContext context, {String? selecionadaId, String? sugestao}) =>
    abrirFolha<Escola>(context, _SeletorEscola(selecionadaId: selecionadaId, sugestao: sugestao));

class _SeletorEscola extends StatefulWidget {
  const _SeletorEscola({this.selecionadaId, this.sugestao});

  final String? selecionadaId;
  final String? sugestao;

  @override
  State<_SeletorEscola> createState() => _SeletorEscolaState();
}

class _SeletorEscolaState extends State<_SeletorEscola> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final q = _busca.toLowerCase();
    final lista = store.escolas.where((e) => q.isEmpty || e.nome.toLowerCase().contains(q)).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, controle) => ListView(
        controller: controle,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Selecionar colégio',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: p.texto),
          ),
          if (widget.sugestao != null) ...[
            const SizedBox(height: 4),
            Text('O responsável escreveu: "${widget.sugestao}"', style: TextStyle(color: p.textoSuave)),
          ],
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _busca = v),
            decoration: const InputDecoration(hintText: 'Buscar colégio', prefixIcon: Icon(Icons.search_rounded)),
          ),
          Secao(
            filhos: [
              if (lista.isEmpty)
                Linha(
                  inicio: IconeApp(Icons.search_off_rounded, cor: p.cinza),
                  titulo: 'Nenhum colégio com esse nome',
                ),
              for (final e in lista)
                Linha(
                  inicio: IconeApp(Icons.school_rounded, cor: e.id == widget.selecionadaId ? p.azul : p.cinza),
                  titulo: e.nome,
                  subtitulo: '${e.endereco} · ${horario(e.entrada)}–${horario(e.saida)}',
                  seta: false,
                  fim: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (e.id == widget.selecionadaId) Icon(Icons.check_circle_rounded, color: p.azul),
                      IconButton(
                        tooltip: 'Editar colégio',
                        icon: Icon(Icons.edit_outlined, color: p.textoSuave, size: 20),
                        onPressed: () => abrirFormularioEscola(context, escola: e),
                      ),
                    ],
                  ),
                  aoTocar: () => Navigator.pop(context, e),
                ),
            ],
          ),
          Secao(
            filhos: [
              Linha(
                inicio: IconeApp(Icons.add_rounded, cor: p.azul),
                titulo: 'Cadastrar novo colégio',
                subtitulo: 'Com endereço confirmado no mapa',
                corTitulo: p.azul,
                aoTocar: () async {
                  final nova = await abrirFormularioEscola(context, nomeInicial: _busca.isNotEmpty ? _busca : widget.sugestao);
                  if (nova != null && context.mounted) Navigator.pop(context, nova);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cadastro/edição de colégio: nome, endereço pelo CEP (confirmado no mapa) e horários.
Future<Escola?> abrirFormularioEscola(BuildContext context, {Escola? escola, String? nomeInicial}) =>
    abrirFolha<Escola>(context, FormularioEscola(escola: escola, nomeInicial: nomeInicial));

class FormularioEscola extends StatefulWidget {
  const FormularioEscola({super.key, this.escola, this.nomeInicial});

  final Escola? escola;
  final String? nomeInicial;

  @override
  State<FormularioEscola> createState() => _FormularioEscolaState();
}

class _FormularioEscolaState extends State<FormularioEscola> {
  late final _nome = TextEditingController(text: widget.escola?.nome ?? widget.nomeInicial ?? '');
  late int _entrada = widget.escola?.entrada ?? 7 * 60 + 30;
  late int _saida = widget.escola?.saida ?? 12 * 60 + 30;
  late Endereco? _endereco = widget.escola?.enderecoCompleto;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  /// Escolas antigas (sem CEP) podem ser salvas; novas precisam do endereço confirmado.
  bool get _valido => _nome.text.trim().isNotEmpty && (_endereco != null || widget.escola != null);

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    return Formulario(
      titulo: widget.escola == null ? 'Novo colégio' : 'Editar colégio',
      podeSalvar: _valido,
      aoSalvar: () {
        final e = store.salvarEscola(
          existente: widget.escola,
          nome: _nome.text.trim(),
          endereco: _endereco?.resumo ?? widget.escola?.endereco ?? '',
          enderecoCompleto: _endereco,
          entrada: _entrada,
          saida: _saida,
        );
        Navigator.pop(context, e);
        avisar(context, 'Colégio salvo');
      },
      aoExcluir: widget.escola == null
          ? null
          : () {
              if (store.removerEscola(widget.escola!)) {
                Navigator.pop(context);
                avisar(context, 'Colégio removido');
              } else {
                avisar(context, 'Há alunos neste colégio. Mude-os antes de remover.', icone: Icons.info_rounded, cor: p.azul);
              }
            },
      campos: [
        CampoTexto(controle: _nome, rotulo: 'Nome do colégio', icone: Icons.school_rounded, aoMudar: () => setState(() {})),
        CartaoEndereco(
          endereco: _endereco,
          rotulo: 'Endereço do colégio',
          icone: Icons.school_rounded,
          aoTocar: () async {
            final e = await escolherEndereco(
              context,
              inicial: _endereco,
              titulo: 'Endereço do colégio',
              ajuda: 'Confirme o colégio pelo CEP e no mapa: assim a rota passa no portão certo.',
            );
            if (e != null) setState(() => _endereco = e);
          },
        ),
        if (_endereco == null && widget.escola != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Endereço atual: ${widget.escola!.endereco}', style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
          ),
        Secao(
          filhos: [
            Linha(
              inicio: IconeApp(Icons.wb_sunny_rounded, cor: p.azul),
              titulo: 'Entrada',
              fim: Text(horario(_entrada), style: TextStyle(color: p.textoSuave, fontSize: 16)),
              aoTocar: () async {
                final m = await escolherHorario(context, _entrada);
                if (m != null) setState(() => _entrada = m);
              },
            ),
            Linha(
              inicio: IconeApp(Icons.nights_stay_rounded, cor: p.azul),
              titulo: 'Saída',
              fim: Text(horario(_saida), style: TextStyle(color: p.textoSuave, fontSize: 16)),
              aoTocar: () async {
                final m = await escolherHorario(context, _saida);
                if (m != null) setState(() => _saida = m);
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Lista de colégios (Gestão).
class EscolasTela extends StatelessWidget {
  const EscolasTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    return PaginaIOS(
      titulo: 'Colégios',
      voltar: true,
      acao: IconButton(
        tooltip: 'Novo colégio',
        onPressed: () => abrirFormularioEscola(context),
        icon: Icon(Icons.add_circle_rounded, size: 30, color: p.azul),
      ),
      filhos: [
        Secao(
          filhos: [
            for (final e in store.escolas)
              Linha(
                inicio: const IconeApp(Icons.school_rounded, cor: Paleta.azulMarca, tamanho: 36),
                titulo: e.nome,
                subtitulo:
                    '${e.endereco}\nAulas ${horario(e.entrada)} – ${horario(e.saida)} · '
                    '${store.alunosAtivos.where((a) => a.escolaId == e.id).length} alunos',
                aoTocar: () => abrirFormularioEscola(context, escola: e),
              ),
          ],
        ),
        Secao(
          filhos: [
            Linha(
              inicio: IconeApp(Icons.add_rounded, cor: p.azul),
              titulo: 'Cadastrar colégio',
              corTitulo: p.azul,
              aoTocar: () => abrirFormularioEscola(context),
            ),
          ],
        ),
      ],
    );
  }
}
