import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/mapa.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import 'shell_motorista.dart';

List<MarcadorMapa> marcadoresDaRota(VanStore store, Trajeto t) => [
      MarcadorMapa(t.garagem, TipoMarcador.garagem),
      for (final a in store.alunosDo(t)) MarcadorMapa(a.posicao, TipoMarcador.casa),
      for (final id in t.escolaIds) MarcadorMapa(store.escola(id).posicao, TipoMarcador.escola),
    ];

/// Editor de rota: horário, van, escolas, quem vai e a ordem das paradas.
class RotaTela extends StatelessWidget {
  const RotaTela({super.key, required this.trajeto});

  final Trajeto trajeto;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    if (!store.trajetos.contains(trajeto)) return Scaffold(backgroundColor: p.fundo);
    final viagemAtiva = store.viagem != null && !store.viagem!.encerrada;
    final van = store.veiculoDe(trajeto);
    final ocupacao = store.alunosDo(trajeto).length;

    return PaginaIOS(
      titulo: trajeto.nome,
      voltar: true,
      rodape: viagemAtiva
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Botao('Iniciar esta viagem', icone: CupertinoIcons.play_fill, aoTocar: () {
                store.iniciarViagem(trajeto);
                Navigator.pop(context);
                abrirViagem(context);
              }),
            ),
      filhos: [
        MapaTrajeto(
          key: ValueKey(trajeto.alunoIds.join()),
          pontos: store.pontosDoTrajeto(trajeto),
          marcadores: marcadoresDaRota(store, trajeto),
          altura: 200,
          raio: 18,
        ),
        Secao(
          titulo: 'Configuração',
          filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.clock_fill, cor: p.azul),
              titulo: 'Saída',
              fim: Text(horario(trajeto.saida), style: TextStyle(color: p.textoSuave, fontSize: 16)),
              aoTocar: () async {
                final m = await escolherHorario(context, trajeto.saida);
                if (m != null) store.ajustarSaida(trajeto, m);
              },
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.bus, cor: p.azul),
              titulo: 'Van',
              subtitulo: '$ocupacao de ${van.capacidade} lugares',
              fim: Text(van.apelido, style: TextStyle(color: p.textoSuave)),
              aoTocar: store.veiculos.length < 2
                  ? null
                  : () async {
                      final id = await escolherAcao<String>(context,
                          titulo: 'Van desta rota',
                          opcoes: [for (final v in store.veiculos) OpcaoAcao('${v.apelido} · ${v.placa}', v.id)]);
                      if (id != null) store.definirVeiculoDoTrajeto(trajeto, store.veiculos.firstWhere((v) => v.id == id));
                    },
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.arrow_turn_up_right, cor: p.cinza),
              titulo: 'Percurso estimado',
              fim: Text('${store.km(trajeto).toStringAsFixed(1)} km', style: TextStyle(color: p.textoSuave, fontSize: 16)),
            ),
          ],
        ),
        Secao(
          titulo: 'Escolas atendidas',
          filhos: [
            for (final e in store.escolas)
              Linha(
                inicio: const IconeApp(CupertinoIcons.book_fill, cor: Paleta.azulMarca),
                titulo: e.nome,
                subtitulo: '${horario(e.entrada)} – ${horario(e.saida)}',
                fim: Icon(
                  trajeto.escolaIds.contains(e.id) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                  color: trajeto.escolaIds.contains(e.id) ? p.azul : p.cinza,
                ),
                seta: false,
                aoTocar: () => store.alternarEscolaNoTrajeto(trajeto, e.id),
              ),
          ],
        ),
        Secao(
          titulo: trajeto.sentido == Sentido.ida ? 'Ordem de busca' : 'Ordem de entrega',
          rodape: 'Segure e arraste para mudar a ordem.',
          filhos: [
            if (trajeto.alunoIds.isEmpty)
              Linha(inicio: IconeApp(CupertinoIcons.person, cor: p.cinza), titulo: 'Nenhum aluno nesta rota')
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: trajeto.alunoIds.length,
                proxyDecorator: (child, _, _) => Material(color: Colors.transparent, elevation: 6, child: child),
                onReorderItem: (de, para) => store.reordenar(trajeto, de, para),
                itemBuilder: (context, i) {
                  final a = store.aluno(trajeto.alunoIds[i]);
                  return Container(
                    key: ValueKey(a.id),
                    color: p.cartao,
                    child: Linha(
                      inicio: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.suave(p.azul), shape: BoxShape.circle),
                        child: Text('${i + 1}', style: TextStyle(color: p.azul, fontWeight: FontWeight.w700)),
                      ),
                      titulo: a.nome,
                      subtitulo: a.ativo ? a.endereco : 'Pausado',
                      fim: Icon(CupertinoIcons.line_horizontal_3, color: p.cinza, size: 20),
                    ),
                  );
                },
              ),
            Linha(
              inicio: IconeApp(CupertinoIcons.person_2_fill, cor: p.azul),
              titulo: 'Editar quem vai',
              corTitulo: p.azul,
              aoTocar: () => abrirFolha(context, _QuemVai(trajeto: trajeto)),
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.wand_stars, cor: p.azul),
              titulo: 'Otimizar ordem',
              subtitulo: 'Menor caminho entre as casas',
              corTitulo: p.azul,
              seta: false,
              aoTocar: () {
                final economia = store.otimizarOrdem(trajeto);
                avisar(context, economia > 0.05 ? '${economia.toStringAsFixed(1)} km a menos por viagem' : 'Já está no menor caminho',
                    icone: CupertinoIcons.wand_stars, cor: p.azul);
              },
            ),
          ],
        ),
        Secao(
          filhos: [
            Linha(
              titulo: 'Excluir rota',
              corTitulo: p.vermelho,
              seta: false,
              aoTocar: () async {
                if (await confirmar(context,
                    titulo: 'Excluir ${trajeto.nome}?',
                    mensagem: 'Os alunos continuam cadastrados.',
                    acao: 'Excluir',
                    destrutiva: true)) {
                  store.removerTrajeto(trajeto);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
          recuo: 14,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Lista de alunos com marcação: quem entra e quem sai desta rota.
class _QuemVai extends StatelessWidget {
  const _QuemVai({required this.trajeto});

  final Trajeto trajeto;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final candidatos = [...store.alunosAtivos]
      ..sort((a, b) {
        final pa = a.turno == trajeto.turno ? 0 : 1, pb = b.turno == trajeto.turno ? 0 : 1;
        return pa != pb ? pa.compareTo(pb) : a.nome.compareTo(b.nome);
      });

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controle) => ListView(
        controller: controle,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(children: [
            const Expanded(child: Text('Quem vai', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
            CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700))),
          ]),
          Text('${trajeto.alunoIds.length} selecionado(s) · ${trajeto.nome}', style: TextStyle(color: p.textoSuave)),
          Secao(
            filhos: [
              for (final a in candidatos)
                Linha(
                  inicio: Avatar(a.nome, tamanho: 34),
                  titulo: a.nome,
                  subtitulo: '${store.escola(a.escolaId).nome} · ${a.turno.rotulo}',
                  fim: Icon(
                    trajeto.alunoIds.contains(a.id) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                    color: trajeto.alunoIds.contains(a.id) ? p.azul : p.cinza,
                  ),
                  seta: false,
                  aoTocar: () => store.alternarAlunoNoTrajeto(trajeto, a.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
