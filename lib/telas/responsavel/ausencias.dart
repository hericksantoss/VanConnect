import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

Future<void> avisarAusencia(BuildContext context, {String? alunoId}) =>
    abrirFolha(context, _FolhaAusencia(alunoId: alunoId));

class AvisosTela extends StatelessWidget {
  const AvisosTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final lista = store.filhosDoResponsavel.expand(store.ausenciasFuturasDe).toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    final v = store.viagem;
    final ids = store.filhosDoResponsavel.toSet();
    final nomes = ids.map((id) => store.aluno(id).primeiro).toList();
    final feed = v == null
        ? <EventoViagem>[]
        : v.eventos
            .where((e) =>
                ids.contains(e.alunoId) ||
                e.tipo == TipoEvento.partida ||
                e.tipo == TipoEvento.fim ||
                e.tipo == TipoEvento.emergencia ||
                (e.tipo == TipoEvento.aviso && nomes.any(e.texto.contains)))
            .take(12)
            .toList();

    return PaginaIOS(
      titulo: 'Avisos',
      acao: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => avisarAusencia(context),
        child: Icon(CupertinoIcons.add_circled_solid, size: 28, color: p.azul),
      ),
      filhos: [
        Cartao(
          aoTocar: () => avisarAusencia(context),
          child: Row(children: [
            IconeApp(CupertinoIcons.calendar_badge_minus, cor: p.laranja, tamanho: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Avisar que não vai', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text('A van já sai sem passar na sua casa.', style: TextStyle(color: p.textoSuave)),
              ]),
            ),
            Icon(CupertinoIcons.chevron_right, color: p.cinza, size: 18),
          ]),
        ),
        if (feed.isNotEmpty)
          Secao(
            titulo: 'Hoje',
            filhos: [
              for (final e in feed)
                Linha(
                  inicio: IconeApp(
                    switch (e.tipo) {
                      TipoEvento.emergencia => CupertinoIcons.exclamationmark_triangle_fill,
                      TipoEvento.embarque => CupertinoIcons.arrow_right_circle_fill,
                      TipoEvento.desembarque => CupertinoIcons.checkmark_seal_fill,
                      TipoEvento.falta => CupertinoIcons.xmark_circle_fill,
                      TipoEvento.fim => CupertinoIcons.flag_fill,
                      _ => CupertinoIcons.bell_fill,
                    },
                    cor: switch (e.tipo) {
                      TipoEvento.emergencia || TipoEvento.falta => p.vermelho,
                      TipoEvento.desembarque || TipoEvento.embarque => p.verde,
                      _ => p.azul,
                    },
                  ),
                  titulo: e.texto
                      .replaceFirst('Responsáveis de ', 'Aviso: ')
                      .replaceFirst(' avisados: van a caminho', ' — van a caminho'),
                  fim: Text(hora(e.quando), style: TextStyle(color: p.textoSuave, fontSize: 13)),
                ),
            ],
          ),
        if (lista.isEmpty)
          Secao(titulo: 'Ausências', filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.calendar, cor: p.cinza),
              titulo: 'Nenhuma ausência marcada',
            ),
          ])
        else
          Secao(
            titulo: 'Ausências marcadas',
            rodape: 'Deslize para a esquerda para cancelar.',
            filhos: [
              for (final a in lista)
                Dismissible(
                  key: ValueKey(a.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: p.vermelho,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  onDismissed: (_) {
                    store.removerAusencia(a);
                    avisar(context, 'Aviso cancelado', icone: CupertinoIcons.arrow_uturn_left);
                  },
                  child: Linha(
                    inicio: Avatar(store.aluno(a.alunoId).nome, tamanho: 36),
                    titulo: '${store.aluno(a.alunoId).primeiro} · ${capitalizar(dataExtenso(a.data))}',
                    subtitulo: [a.rotuloSentido, if (a.motivo.isNotEmpty) a.motivo].join(' · '),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 90),
      ],
    );
  }
}

class _FolhaAusencia extends StatefulWidget {
  const _FolhaAusencia({this.alunoId});

  final String? alunoId;

  @override
  State<_FolhaAusencia> createState() => _FolhaAusenciaState();
}

class _FolhaAusenciaState extends State<_FolhaAusencia> {
  late final Set<String> _quem = {if (widget.alunoId != null) widget.alunoId!};
  int _quando = 0; // 0 hoje, 1 amanhã, 2 outra
  DateTime? _outra;
  int _sentido = 0; // 0 ida e volta, 1 só ida, 2 só volta

  DateTime get _data {
    final hoje = soData(DateTime.now());
    return switch (_quando) {
      0 => hoje,
      1 => hoje.add(const Duration(days: 1)),
      _ => _outra ?? hoje.add(const Duration(days: 2)),
    };
  }

  @override
  void initState() {
    super.initState();
    if (_quem.isEmpty) _quem.addAll(VanScope.read(context).filhosDoResponsavel);
  }

  Widget _segmento<T extends Object>(T valor, Map<T, String> opcoes, ValueChanged<T> aoMudar) {
    final p = context.cores;
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        groupValue: valor,
        backgroundColor: p.preenchimento,
        thumbColor: p.escuro ? p.elevado : Colors.white,
        onValueChanged: (v) {
          aoMudar(v ?? valor);
          setState(() {});
        },
        children: {
          for (final e in opcoes.entries) e.key: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(e.value)),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final filhos = store.filhosDoResponsavel.map(store.aluno).toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Não vai na van', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('O motorista é avisado na hora.', style: TextStyle(color: p.textoSuave)),
            if (filhos.length > 1)
              Secao(
                titulo: 'Quem',
                filhos: [
                  for (final f in filhos)
                    Linha(
                      inicio: Avatar(f.nome, tamanho: 32),
                      titulo: f.primeiro,
                      fim: Icon(
                        _quem.contains(f.id) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                        color: _quem.contains(f.id) ? p.azul : p.cinza,
                      ),
                      seta: false,
                      aoTocar: () => setState(() => _quem.contains(f.id) ? _quem.remove(f.id) : _quem.add(f.id)),
                    ),
                ],
              ),
            const SizedBox(height: 18),
            _segmento<int>(_quando, {0: 'Hoje', 1: 'Amanhã', 2: _outra == null ? 'Outro dia' : dataCurta(_outra!)}, (v) async {
              _quando = v;
              if (v == 2) {
                final hoje = soData(DateTime.now());
                final d = await showDatePicker(
                  context: context,
                  initialDate: hoje.add(const Duration(days: 2)),
                  firstDate: hoje,
                  lastDate: hoje.add(const Duration(days: 120)),
                );
                if (d != null) setState(() => _outra = d);
              }
            }),
            const SizedBox(height: 10),
            _segmento<int>(_sentido, const {0: 'Ida e volta', 1: 'Só ida', 2: 'Só volta'}, (v) => _sentido = v),
            const SizedBox(height: 20),
            Botao(
              'Avisar motorista',
              icone: CupertinoIcons.paperplane_fill,
              aoTocar: _quem.isEmpty
                  ? null
                  : () {
                      for (final id in _quem) {
                        store.avisarAusencia(
                          alunoId: id,
                          data: _data,
                          sentido: switch (_sentido) { 1 => Sentido.ida, 2 => Sentido.volta, _ => null },
                        );
                      }
                      Navigator.pop(context);
                      avisar(context, '${primeiroNome(store.nomeMotorista)} foi avisado. Obrigado! 💛', icone: CupertinoIcons.paperplane_fill, cor: p.azul);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
