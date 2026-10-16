import 'package:flutter/cupertino.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/aparencia.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import '../../tutoriais/tutoriais.dart';
import 'passageiros.dart';

void abrirAlunos(BuildContext context, {bool pedidos = false}) =>
    abrir(context, PassageirosTela(segmento: ValueNotifier(pedidos ? 1 : 0), voltar: true));

/// Central de cadastros do motorista.
class GestaoTela extends StatelessWidget {
  const GestaoTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;

    Widget chave(bool valor, ValueChanged<bool> aoMudar) => CupertinoSwitch(value: valor, onChanged: aoMudar, activeTrackColor: p.azul);

    return PaginaIOS(
      titulo: 'Gestão',
      filhos: [
        Cartao(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Avatar(store.nomeMotorista, tamanho: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.nomeMotorista, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                Text('Motorista · ${store.veiculo.apelido}', style: TextStyle(color: p.textoSuave)),
              ]),
            ),
            Botao('Código geral', compacto: true, estilo: EstiloBotao.secundario, icone: CupertinoIcons.share,
                aoTocar: () => copiarCodigo(context, store.codigoVan)),
          ]),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          padding: EdgeInsets.zero,
          children: [
            _Bloco(
              icone: CupertinoIcons.person_2_fill,
              titulo: 'Alunos',
              detalhe: '${store.alunosAtivos.length} ativos',
              selo: store.solicitacoes.isEmpty ? null : '${store.solicitacoes.length} pedido(s)',
              aoTocar: () => abrirAlunos(context, pedidos: store.solicitacoes.isNotEmpty),
            ),
            _Bloco(
              icone: CupertinoIcons.book_fill,
              titulo: 'Escolas',
              detalhe: '${store.escolas.length} atendida(s)',
              aoTocar: () => abrir(context, const EscolasTela()),
            ),
            _Bloco(
              icone: CupertinoIcons.bus,
              titulo: 'Vans',
              detalhe: '${store.veiculos.length} cadastrada(s)',
              aoTocar: () => abrir(context, const VansTela()),
            ),
            _Bloco(
              icone: CupertinoIcons.qrcode,
              titulo: 'Código',
              detalhe: store.codigoVan,
              aoTocar: () => copiarCodigo(context, store.codigoVan),
            ),
          ],
        ),
        const SecaoAparencia(),
        Secao(
          titulo: 'Durante a viagem',
          rodape: 'A localização só é compartilhada enquanto uma viagem está em andamento.',
          filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.location_fill, cor: p.azul),
              titulo: 'Compartilhar localização',
              fim: chave(store.compartilharAoIniciar, (x) => store.preferencias(compartilhar: x)),
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.bell_fill, cor: p.azul),
              titulo: 'Avisar próxima família',
              fim: chave(store.avisarProximaParada, (x) => store.preferencias(avisar: x)),
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.forward_fill, cor: p.azul),
              titulo: 'Seguir automaticamente',
              fim: chave(store.seguirAutomaticamente, (x) => store.preferencias(seguir: x)),
            ),
          ],
        ),
        Secao(
          filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.lightbulb_fill, cor: p.azul),
              titulo: 'Rever tutoriais',
              subtitulo: 'Mostra de novo as dicas de cada aba',
              seta: false,
              aoTocar: () async {
                await Tutoriais.reativarTodos();
                if (context.mounted) avisar(context, 'Tutoriais reativados: toque nas abas para ver', icone: CupertinoIcons.lightbulb_fill, cor: p.azul);
              },
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.person_2_fill, cor: p.cinza),
              titulo: 'Ver como responsável',
              aoTocar: () => store.escolherPerfil(Perfil.responsavel),
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.square_arrow_right, cor: p.vermelho),
              titulo: 'Sair',
              corTitulo: p.vermelho,
              seta: false,
              aoTocar: () => store.escolherPerfil(null),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Center(child: LogoVanConnect(tamanho: 20)),
        const SizedBox(height: 90),
      ],
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({required this.icone, required this.titulo, required this.detalhe, required this.aoTocar, this.selo});

  final IconData icone;
  final String titulo;
  final String detalhe;
  final String? selo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Cartao(
      aoTocar: aoTocar,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconeApp(icone, cor: p.azul, tamanho: 36),
            const Spacer(),
            if (selo != null) Selo(selo!, cor: p.vermelho),
          ]),
          const Spacer(),
          Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          Text(detalhe, style: TextStyle(color: p.textoSuave, fontSize: 13)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ Vans

class VansTela extends StatelessWidget {
  const VansTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    return PaginaIOS(
      titulo: 'Vans',
      voltar: true,
      acao: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => abrirFolha(context, const _FormVan()),
        child: Icon(CupertinoIcons.add_circled_solid, size: 28, color: p.azul),
      ),
      filhos: [
        for (final v in store.veiculos) ...[
          Cartao(
            aoTocar: () => abrirFolha(context, _FormVan(van: v)),
            child: Row(children: [
              IconeApp(CupertinoIcons.bus, cor: p.azul, tamanho: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.apelido, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('${v.modelo} · ${v.capacidade} lugares', style: TextStyle(color: p.textoSuave)),
                  Text('${store.trajetos.where((t) => t.veiculoId == v.id).length} rota(s)', style: TextStyle(color: p.textoSuave, fontSize: 13)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(border: Border.all(color: p.texto, width: 1.3), borderRadius: BorderRadius.circular(7)),
                child: Text(v.placa, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        Secao(filhos: [
          Linha(
            inicio: IconeApp(CupertinoIcons.add, cor: p.azul),
            titulo: 'Cadastrar van',
            corTitulo: p.azul,
            aoTocar: () => abrirFolha(context, const _FormVan()),
          ),
        ]),
      ],
    );
  }
}

class _FormVan extends StatefulWidget {
  const _FormVan({this.van});

  final Veiculo? van;

  @override
  State<_FormVan> createState() => _FormVanState();
}

class _FormVanState extends State<_FormVan> {
  late final _apelido = TextEditingController(text: widget.van?.apelido ?? '');
  late final _modelo = TextEditingController(text: widget.van?.modelo ?? '');
  late final _placa = TextEditingController(text: widget.van?.placa ?? '');
  late int _capacidade = widget.van?.capacidade ?? 15;

  @override
  void dispose() {
    _apelido.dispose();
    _modelo.dispose();
    _placa.dispose();
    super.dispose();
  }

  bool get _valido => _apelido.text.trim().isNotEmpty && _placa.text.trim().length >= 7;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    return Formulario(
      titulo: widget.van == null ? 'Nova van' : 'Editar van',
      podeSalvar: _valido,
      aoSalvar: () {
        store.salvarVeiculo(
          existente: widget.van,
          apelido: _apelido.text.trim(),
          modelo: _modelo.text.trim(),
          placa: _placa.text.trim(),
          capacidade: _capacidade,
        );
        Navigator.pop(context);
        avisar(context, 'Van salva');
      },
      aoExcluir: widget.van == null
          ? null
          : () {
              if (store.removerVeiculo(widget.van!)) {
                Navigator.pop(context);
                avisar(context, 'Van removida');
              } else {
                avisar(context, 'É preciso ter ao menos uma van', icone: CupertinoIcons.info_circle_fill, cor: p.azul);
              }
            },
      campos: [
        CampoTexto(controle: _apelido, rotulo: 'Apelido (ex.: Van azul)', icone: CupertinoIcons.tag_fill, aoMudar: () => setState(() {})),
        CampoTexto(controle: _modelo, rotulo: 'Modelo e ano', icone: CupertinoIcons.car_fill),
        CampoTexto(
          controle: _placa,
          rotulo: 'Placa',
          icone: CupertinoIcons.textformat_abc,
          maiusculas: true,
          aoMudar: () => setState(() {}),
        ),
        Secao(filhos: [
          Linha(
            inicio: IconeApp(CupertinoIcons.person_3_fill, cor: p.azul),
            titulo: 'Lugares',
            fim: Row(mainAxisSize: MainAxisSize.min, children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: _capacidade > 4 ? () => setState(() => _capacidade--) : null,
                child: const Icon(CupertinoIcons.minus_circle),
              ),
              SizedBox(width: 34, child: Text('$_capacidade', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: _capacidade < 30 ? () => setState(() => _capacidade++) : null,
                child: const Icon(CupertinoIcons.plus_circle),
              ),
            ]),
          ),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- Escolas

class EscolasTela extends StatelessWidget {
  const EscolasTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    return PaginaIOS(
      titulo: 'Escolas',
      voltar: true,
      acao: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => abrirFolha(context, const _FormEscola()),
        child: Icon(CupertinoIcons.add_circled_solid, size: 28, color: p.azul),
      ),
      filhos: [
        Secao(
          filhos: [
            for (final e in store.escolas)
              Linha(
                inicio: const IconeApp(CupertinoIcons.book_fill, cor: Paleta.azulMarca, tamanho: 36),
                titulo: e.nome,
                subtitulo: '${e.endereco}\nAulas ${horario(e.entrada)} – ${horario(e.saida)} · '
                    '${store.alunosAtivos.where((a) => a.escolaId == e.id).length} alunos',
                aoTocar: () => abrirFolha(context, _FormEscola(escola: e)),
              ),
          ],
        ),
        Secao(filhos: [
          Linha(
            inicio: IconeApp(CupertinoIcons.add, cor: p.azul),
            titulo: 'Cadastrar escola',
            corTitulo: p.azul,
            aoTocar: () => abrirFolha(context, const _FormEscola()),
          ),
        ]),
      ],
    );
  }
}

class _FormEscola extends StatefulWidget {
  const _FormEscola({this.escola});

  final Escola? escola;

  @override
  State<_FormEscola> createState() => _FormEscolaState();
}

class _FormEscolaState extends State<_FormEscola> {
  late final _nome = TextEditingController(text: widget.escola?.nome ?? '');
  late final _endereco = TextEditingController(text: widget.escola?.endereco ?? '');
  late int _entrada = widget.escola?.entrada ?? 7 * 60 + 30;
  late int _saida = widget.escola?.saida ?? 12 * 60 + 30;

  @override
  void dispose() {
    _nome.dispose();
    _endereco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    return Formulario(
      titulo: widget.escola == null ? 'Nova escola' : 'Editar escola',
      podeSalvar: _nome.text.trim().isNotEmpty,
      aoSalvar: () {
        store.salvarEscola(
          existente: widget.escola,
          nome: _nome.text.trim(),
          endereco: _endereco.text.trim(),
          entrada: _entrada,
          saida: _saida,
        );
        Navigator.pop(context);
        avisar(context, 'Escola salva');
      },
      aoExcluir: widget.escola == null
          ? null
          : () {
              if (store.removerEscola(widget.escola!)) {
                Navigator.pop(context);
                avisar(context, 'Escola removida');
              } else {
                avisar(context, 'Há alunos nesta escola. Mude-os antes de remover.', icone: CupertinoIcons.info_circle_fill, cor: p.azul);
              }
            },
      campos: [
        CampoTexto(controle: _nome, rotulo: 'Nome da escola', icone: CupertinoIcons.book_fill, aoMudar: () => setState(() {})),
        CampoTexto(controle: _endereco, rotulo: 'Endereço', icone: CupertinoIcons.location_fill),
        Secao(filhos: [
          Linha(
            inicio: IconeApp(CupertinoIcons.sunrise_fill, cor: p.azul),
            titulo: 'Entrada',
            fim: Text(horario(_entrada), style: TextStyle(color: p.textoSuave, fontSize: 16)),
            aoTocar: () async {
              final m = await escolherHorario(context, _entrada);
              if (m != null) setState(() => _entrada = m);
            },
          ),
          Linha(
            inicio: IconeApp(CupertinoIcons.sunset_fill, cor: p.azul),
            titulo: 'Saída',
            fim: Text(horario(_saida), style: TextStyle(color: p.textoSuave, fontSize: 16)),
            aoTocar: () async {
              final m = await escolherHorario(context, _saida);
              if (m != null) setState(() => _saida = m);
            },
          ),
        ]),
      ],
    );
  }
}
