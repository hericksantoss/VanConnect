import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

Future<void> abrirConvite(BuildContext context, Aluno aluno) => abrirFolha(context, _FolhaConvite(aluno: aluno));

/// Texto curto do estado da família no app (usado na ficha e na lista de alunos).
String situacaoFamilia(VanStore store, Aluno a) {
  if (a.familiaConectada) return 'Família no app';
  final c = store.conviteAtivoDe(a.id);
  if (c != null) return 'Convite enviado · até ${dataCurta(c.expiraEm)}';
  return 'Família ainda sem o app';
}

/// Motorista convida a família: escolhe os irmãos, vê o que a família vai ver e envia.
class _FolhaConvite extends StatefulWidget {
  const _FolhaConvite({required this.aluno});

  final Aluno aluno;

  @override
  State<_FolhaConvite> createState() => _FolhaConviteState();
}

class _FolhaConviteState extends State<_FolhaConvite> {
  late final Set<String> _selecionados;
  Convite? _convite;

  /// false = responsável cadastrado (ver e agir); true = outro familiar (escolhe o escopo).
  bool _outroFamiliar = false;
  Escopo _escopo = Escopo.leitura;
  final _nomeFamiliar = TextEditingController();

  @override
  void dispose() {
    _nomeFamiliar.dispose();
    super.dispose();
  }

  void _mudou(VoidCallback f) => setState(() {
    f();
    _convite = null; // mudou para quem / o que pode → gera de novo
  });

  @override
  void initState() {
    super.initState();
    final store = VanScope.read(context);
    _selecionados = store.familiaDe(widget.aluno).map((a) => a.id).toSet();
    final ativo = store.conviteAtivoDe(widget.aluno.id);
    if (ativo != null && ativo.alunoIds.toSet().containsAll(_selecionados)) _convite = ativo;
  }

  void _alternar(String id) {
    setState(() {
      _selecionados.contains(id) ? _selecionados.remove(id) : _selecionados.add(id);
      _convite = null; // mudou quem vai → precisa gerar de novo
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final familia = store.familiaDe(widget.aluno);
    final selecionados = familia.where((a) => _selecionados.contains(a.id)).toList();
    final nomes = selecionados.map((a) => a.primeiro).toList();
    final quem = nomes.isEmpty
        ? '—'
        : nomes.length == 1
        ? nomes.first
        : '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';
    final convite = _convite;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      maxChildSize: 0.95,
      builder: (context, controle) => ListView(
        controller: controle,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const Text('Convidar família', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
          const SizedBox(height: 4),
          Text(
            'A família recebe um link que já vem com o filho e a rota. É só tocar em Aceitar, sem precisar da sua aprovação.',
            style: TextStyle(color: p.textoSuave, height: 1.35),
          ),
          if (familia.length > 1)
            Secao(
              titulo: 'Quem entra no convite',
              rodape: 'Irmãos com o mesmo responsável vão juntos.',
              filhos: [
                for (final a in familia)
                  Linha(
                    inicio: Avatar(a.nome, tamanho: 34),
                    titulo: a.nome,
                    subtitulo: a.familiaConectada ? 'Já conectado' : store.escola(a.escolaId).nome,
                    fim: Icon(
                      _selecionados.contains(a.id) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                      color: _selecionados.contains(a.id) ? p.azul : p.cinza,
                    ),
                    seta: false,
                    aoTocar: () => _alternar(a.id),
                  ),
              ],
            ),
          Secao(
            titulo: 'Para quem',
            rodape: _outroFamiliar ? _escopo.descricao : 'Responsável cadastrado: pode ver e agir.',
            filhos: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Segmentos<bool>(
                      valor: _outroFamiliar,
                      opcoes: {false: primeiroNome(widget.aluno.responsavel.nome), true: 'Outro familiar'},
                      aoMudar: (v) => _mudou(() => _outroFamiliar = v),
                    ),
                    if (_outroFamiliar) ...[
                      const SizedBox(height: 10),
                      CampoTexto(
                        controle: _nomeFamiliar,
                        rotulo: 'Nome (ex.: Avó Lúcia)',
                        icone: CupertinoIcons.person_fill,
                        aoMudar: () => _mudou(() {}),
                      ),
                      Segmentos<Escopo>(
                        valor: _escopo,
                        opcoes: {for (final e in Escopo.values) e: e.rotulo},
                        aoMudar: (v) => _mudou(() => _escopo = v),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Secao(
            titulo:
                'O que ${_outroFamiliar && _nomeFamiliar.text.trim().isNotEmpty ? primeiroNome(_nomeFamiliar.text) : primeiroNome(widget.aluno.responsavel.nome)} vai ver',
            filhos: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(store.nomeMotorista, tamanho: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${primeiroNome(store.nomeMotorista)} convidou você para acompanhar $quem',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final a in selecionados) _ResumoAluno(aluno: a),
                    const SizedBox(height: 4),
                    Text('${store.veiculo.modelo} · ${store.veiculo.placa}', style: TextStyle(color: p.textoSuave, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: convite == null
                ? Botao(
                    'Gerar convite',
                    key: const ValueKey('gerar'),
                    icone: CupertinoIcons.paperplane_fill,
                    aoTocar: selecionados.isEmpty || (_outroFamiliar && _nomeFamiliar.text.trim().isEmpty)
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            setState(
                              () => _convite = store.gerarConvite(
                                _selecionados.toList(),
                                escopo: _outroFamiliar ? _escopo : Escopo.completo,
                                nomeConvidado: _outroFamiliar ? _nomeFamiliar.text : null,
                              ),
                            );
                          },
                  )
                : _ConviteGerado(
                    key: ValueKey(convite.codigo),
                    convite: convite,
                    aoCancelar: () {
                      store.cancelarConvite(convite);
                      setState(() => _convite = null);
                      avisar(context, 'Convite cancelado', icone: CupertinoIcons.xmark_circle_fill, cor: p.cinza);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResumoAluno extends StatelessWidget {
  const _ResumoAluno({required this.aluno});

  final Aluno aluno;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final rotas = store.trajetosOrdenados.where((t) => t.alunoIds.contains(aluno.id)).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.person_fill, size: 16, color: p.azul),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${aluno.nome} · ${store.escola(aluno.escolaId).nome}\n'
              '${rotas.isEmpty ? 'Ainda sem rota' : rotas.map((t) => '${t.sentido.rotulo} ${horario(t.saida)}').join(' · ')}',
              style: TextStyle(color: p.texto, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConviteGerado extends StatelessWidget {
  const _ConviteGerado({super.key, required this.convite, required this.aoCancelar});

  final Convite convite;
  final VoidCallback aoCancelar;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Cartao(
          cor: p.suave(p.azul),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Column(
            children: [
              Text(
                'Código do convite',
                style: TextStyle(color: p.azul, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                convite.codigoFormatado,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 4, color: p.texto),
              ),
              Text('Uso único · válido até ${dataCurta(convite.expiraEm)}', style: TextStyle(color: p.textoSuave, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Botao(
          'Enviar pelo WhatsApp',
          icone: CupertinoIcons.chat_bubble_fill,
          aoTocar: () {
            Clipboard.setData(ClipboardData(text: store.mensagemConvite(convite)));
            avisar(context, 'Mensagem com o link copiada — cole no WhatsApp da família', icone: CupertinoIcons.doc_on_doc_fill);
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Botao(
                'Copiar código',
                compacto: true,
                estilo: EstiloBotao.secundario,
                icone: CupertinoIcons.doc_on_doc,
                aoTocar: () {
                  Clipboard.setData(ClipboardData(text: convite.codigoFormatado));
                  avisar(context, 'Código ${convite.codigoFormatado} copiado', icone: CupertinoIcons.doc_on_doc_fill);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Botao('Cancelar convite', compacto: true, estilo: EstiloBotao.destrutivo, aoTocar: aoCancelar),
            ),
          ],
        ),
      ],
    );
  }
}
