import 'package:flutter/cupertino.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import '../comum/escolas.dart';
import 'rota.dart';

class RotasTela extends StatelessWidget {
  const RotasTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;

    return PaginaIOS(
      titulo: 'Rotas',
      acao: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => abrirFolha(context, const _NovaRota()),
        child: Icon(CupertinoIcons.add_circled_solid, size: 28, color: p.azul),
      ),
      filhos: [
        for (final turno in Turno.values)
          if (store.trajetosOrdenados.where((t) => t.turno == turno).toList() case final lista when lista.isNotEmpty)
            Secao(
              titulo: 'Turno da ${turno.rotulo.toLowerCase()}',
              filhos: [
                for (final t in lista)
                  Linha(
                    inicio: IconeApp(
                      t.sentido == Sentido.ida ? CupertinoIcons.arrow_right_circle_fill : CupertinoIcons.house_fill,
                      cor: p.azul,
                      tamanho: 36,
                    ),
                    titulo: '${t.sentido.rotulo} · ${horario(t.saida)}',
                    subtitulo:
                        '${t.escolaIds.map((id) => store.escola(id).nome).join(', ')}\n'
                        '${store.alunosDo(t).length} alunos · ${store.km(t).toStringAsFixed(1)} km · ${store.veiculoDe(t).apelido}',
                    fim: store.execucoesRemotas.containsKey(t.veiculoId)
                        ? Selo('Em uso', cor: p.laranja, icone: CupertinoIcons.antenna_radiowaves_left_right)
                        : (store.ajusteDeHoje(t).vazio ? null : Selo('Hoje alterada', cor: p.azul)),
                    aoTocar: () => abrir(context, RotaTela(trajeto: t)),
                  ),
              ],
            ),
        Secao(
          filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.add, cor: p.azul),
              titulo: 'Criar nova rota',
              corTitulo: p.azul,
              aoTocar: () => abrirFolha(context, const _NovaRota()),
            ),
          ],
          rodape: 'Ao criar, os alunos do turno e da escola escolhidos entram automaticamente.',
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}

class _NovaRota extends StatefulWidget {
  const _NovaRota();

  @override
  State<_NovaRota> createState() => _NovaRotaState();
}

class _NovaRotaState extends State<_NovaRota> {
  Turno _turno = Turno.manha;
  Sentido _sentido = Sentido.ida;
  String? _escolaId;
  int _saida = 6 * 60 + 30;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    _escolaId ??= store.escolas.first.id;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nova rota', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 16),
            Segmentos<Turno>(
              valor: _turno,
              opcoes: const {Turno.manha: 'Manhã', Turno.tarde: 'Tarde', Turno.integral: 'Integral'},
              aoMudar: (v) => setState(() => _turno = v),
            ),
            const SizedBox(height: 10),
            Segmentos<Sentido>(
              valor: _sentido,
              opcoes: const {Sentido.ida: 'Ida (casa → escola)', Sentido.volta: 'Volta'},
              aoMudar: (v) => setState(() => _sentido = v),
            ),
            Secao(
              filhos: [
                Linha(
                  inicio: const IconeApp(CupertinoIcons.book_fill, cor: Paleta.azulMarca),
                  titulo: 'Colégio',
                  subtitulo: store.escola(_escolaId!).endereco,
                  fim: Text(store.escola(_escolaId!).nome, style: TextStyle(color: p.textoSuave)),
                  // Selecionar da lista ou cadastrar um colégio novo (com CEP e mapa).
                  aoTocar: () async {
                    final e = await selecionarEscola(context, selecionadaId: _escolaId);
                    if (e != null) setState(() => _escolaId = e.id);
                  },
                ),
                Linha(
                  inicio: IconeApp(CupertinoIcons.clock_fill, cor: p.azul),
                  titulo: 'Saída',
                  fim: Text(horario(_saida), style: TextStyle(color: p.textoSuave)),
                  aoTocar: () async {
                    final m = await escolherHorario(context, _saida);
                    if (m != null) setState(() => _saida = m);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Botao(
              'Criar rota',
              icone: CupertinoIcons.checkmark_alt,
              aoTocar: () {
                final t = store.criarTrajeto(turno: _turno, sentido: _sentido, saida: _saida, escolaId: _escolaId!);
                Navigator.pop(context);
                avisar(context, 'Rota ${t.nome} criada com ${t.alunoIds.length} aluno(s)');
              },
            ),
          ],
        ),
      ),
    );
  }
}
