import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/mapa.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import '../comum/escolas.dart';
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
              child: Botao(
                'Iniciar esta viagem',
                icone: CupertinoIcons.play_fill,
                aoTocar: () => iniciarViagemComCuidado(context, trajeto, fecharTelaAtual: true),
              ),
            ),
      filhos: [
        MapaTrajeto(
          key: ValueKey(trajeto.alunoIds.join()),
          pontos: store.pontosDoTrajeto(trajeto),
          marcadores: marcadoresDaRota(store, trajeto),
          altura: 200,
          raio: 18,
        ),
        _SecaoHoje(trajeto: trajeto),
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
                      final id = await escolherAcao<String>(
                        context,
                        titulo: 'Van desta rota',
                        opcoes: [for (final v in store.veiculos) OpcaoAcao('${v.apelido} · ${v.placa}', v.id)],
                      );
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
            Linha(
              inicio: IconeApp(Icons.add_rounded, cor: p.azul),
              titulo: 'Adicionar colégio',
              subtitulo: 'Escolha da lista ou cadastre um novo',
              corTitulo: p.azul,
              aoTocar: () async {
                final e = await selecionarEscola(context);
                if (e != null && !trajeto.escolaIds.contains(e.id)) store.alternarEscolaNoTrajeto(trajeto, e.id);
              },
            ),
          ],
        ),
        Secao(
          titulo: trajeto.sentido == Sentido.ida ? 'Ordem de busca' : 'Ordem de entrega',
          rodape: 'Segure e arraste para mudar a ordem.',
          filhos: [
            if (trajeto.alunoIds.isEmpty)
              Linha(
                inicio: IconeApp(CupertinoIcons.person, cor: p.cinza),
                titulo: 'Nenhum aluno nesta rota',
              )
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
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(color: p.azul, fontWeight: FontWeight.w700),
                        ),
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
              titulo: 'Editar rota padrão',
              subtitulo: 'Quem vai todos os dias',
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
                avisar(
                  context,
                  economia > 0.05 ? '${economia.toStringAsFixed(1)} km a menos por viagem' : 'Já está no menor caminho',
                  icone: CupertinoIcons.wand_stars,
                  cor: p.azul,
                );
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
                if (await confirmar(
                  context,
                  titulo: 'Excluir ${trajeto.nome}?',
                  mensagem: 'Os alunos continuam cadastrados.',
                  acao: 'Excluir',
                  destrutiva: true,
                )) {
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

/// "Hoje": mudanças só para a rota de hoje, sem mexer na rota padrão.
class _SecaoHoje extends StatelessWidget {
  const _SecaoHoje({required this.trajeto});

  final Trajeto trajeto;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final ajuste = store.ajusteDeHoje(trajeto);
    final hoje = store.alunosDoDia(trajeto).length;
    final remota = store.execucoesRemotas[trajeto.veiculoId];

    return Secao(
      titulo: 'Hoje',
      rodape: ajuste.vazio ? 'Mudanças feitas aqui valem só para hoje. A rota padrão continua igual.' : null,
      filhos: [
        if (remota != null)
          Linha(
            inicio: IconeApp(CupertinoIcons.antenna_radiowaves_left_right, cor: p.laranja),
            titulo: 'Van em uso por ${remota.quem}',
            subtitulo: '${remota.trajetoNome} · desde ${hora(remota.desde)}',
          ),
        Linha(
          inicio: IconeApp(CupertinoIcons.calendar_today, cor: p.azul),
          titulo: 'Quem vai hoje',
          subtitulo: [
            '$hoje aluno(s)',
            if (ajuste.removidos.isNotEmpty) '${ajuste.removidos.length} fora só hoje',
            if (ajuste.incluidos.isNotEmpty) '${ajuste.incluidos.length} a mais só hoje',
          ].join(' · '),
          aoTocar: () => abrirFolha(context, _QuemVai(trajeto: trajeto, soHoje: true)),
        ),
        if (!ajuste.vazio) ...[
          Linha(
            inicio: IconeApp(CupertinoIcons.checkmark_seal_fill, cor: p.azul),
            titulo: 'Salvar hoje como padrão',
            corTitulo: p.azul,
            seta: false,
            aoTocar: () async {
              if (await confirmar(
                context,
                titulo: 'Salvar como padrão?',
                mensagem: 'A rota de todos os dias passa a ser igual à de hoje.',
                acao: 'Salvar',
              )) {
                store.salvarDiaComoPadrao(trajeto);
                if (context.mounted) avisar(context, 'Rota padrão atualizada');
              }
            },
          ),
          Linha(
            inicio: IconeApp(CupertinoIcons.arrow_uturn_left, cor: p.cinza),
            titulo: 'Desfazer mudanças de hoje',
            seta: false,
            aoTocar: () => store.desfazerAjustesDeHoje(trajeto),
          ),
        ],
      ],
    );
  }
}

/// Lista de alunos com marcação: quem entra e quem sai desta rota.
class _QuemVai extends StatelessWidget {
  const _QuemVai({required this.trajeto, this.soHoje = false});

  final Trajeto trajeto;

  /// true = mexe só na rota de hoje; false = mexe na rota padrão.
  final bool soHoje;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final hojeIds = store.alunosDoDia(trajeto).map((a) => a.id).toSet();
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
          Row(
            children: [
              Expanded(
                child: Text(
                  soHoje ? 'Quem vai hoje' : 'Rota padrão',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Text(
            soHoje ? '${hojeIds.length} selecionado(s) · vale só para hoje' : '${trajeto.alunoIds.length} selecionado(s) · todos os dias',
            style: TextStyle(color: p.textoSuave),
          ),
          Secao(
            filhos: [
              for (final a in candidatos)
                Linha(
                  inicio: Avatar(a.nome, tamanho: 34),
                  titulo: a.nome,
                  subtitulo: '${store.escola(a.escolaId).nome} · ${a.turno.rotulo}',
                  fim: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (soHoje && trajeto.alunoIds.contains(a.id) != hojeIds.contains(a.id))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Selo('só hoje', cor: p.azul),
                        ),
                      Icon(
                        (soHoje ? hojeIds : trajeto.alunoIds).contains(a.id) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                        color: (soHoje ? hojeIds : trajeto.alunoIds).contains(a.id) ? p.azul : p.cinza,
                      ),
                    ],
                  ),
                  seta: false,
                  aoTocar: () => soHoje ? store.alternarAlunoHoje(trajeto, a.id) : store.alternarAlunoNoTrajeto(trajeto, a.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
