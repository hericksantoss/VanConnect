import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import 'gestao.dart';
import 'rota.dart';
import 'shell_motorista.dart';

/// Início do motorista: o que importa agora, em uma tela.
class InicioTela extends StatelessWidget {
  const InicioTela({super.key, required this.irPara});

  final ValueChanged<int> irPara;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final agora = DateTime.now();

    final pendencias = <Widget>[
      if (store.solicitacoes.isNotEmpty)
        Linha(
          inicio: IconeApp(CupertinoIcons.person_badge_plus_fill, cor: p.azul),
          titulo: '${store.solicitacoes.length} pedido(s) para entrar',
          subtitulo: store.solicitacoes.map((s) => primeiroNome(s.nomeAluno)).join(', '),
          aoTocar: () => abrirAlunos(context, pedidos: true),
        ),
      if (store.ausenciasDeHoje.isNotEmpty)
        Linha(
          inicio: IconeApp(CupertinoIcons.calendar_badge_minus, cor: p.laranja),
          titulo: '${store.ausenciasDeHoje.length} ausência(s) hoje',
          subtitulo: '${store.ausenciasDeHoje.map((a) => store.aluno(a.alunoId).primeiro).join(', ')} · já fora da rota',
        ),
      if (store.informadas.isNotEmpty || store.atrasadas.isNotEmpty)
        Linha(
          inicio: IconeApp(CupertinoIcons.creditcard_fill, cor: store.atrasadas.isNotEmpty ? p.vermelho : p.verde),
          titulo: [
            if (store.informadas.isNotEmpty) '${store.informadas.length} a confirmar',
            if (store.atrasadas.isNotEmpty) '${store.atrasadas.length} atrasada(s)',
          ].join(' · '),
          subtitulo: 'Mensalidades',
          aoTocar: () => irPara(2),
        ),
      if (store.aniversariantesDaSemana.isNotEmpty)
        Linha(
          inicio: IconeApp(CupertinoIcons.gift_fill, cor: p.roxo),
          titulo: 'Aniversário na semana',
          subtitulo: store.aniversariantesDaSemana.map((a) => '${a.primeiro} (${dataCurta(a.nascimento)})').join(', '),
        ),
    ];

    return PaginaIOS(
      titulo: '${saudacao(agora)}, ${primeiroNome(store.nomeMotorista)}',
      filhos: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 14),
          child: Text(capitalizar(dataExtenso(agora)), style: TextStyle(color: p.textoSuave, fontSize: 15)),
        ),
        _ProximaViagem(store: store),
        if (pendencias.isNotEmpty) Secao(titulo: 'Para hoje', filhos: pendencias),
        Secao(
          titulo: 'Agenda',
          filhos: [
            for (final t in store.trajetosOrdenados)
              Linha(
                inicio: IconeApp(
                  store.concluidosHoje.contains(t.id)
                      ? CupertinoIcons.checkmark_alt
                      : (t.sentido == Sentido.ida ? CupertinoIcons.arrow_right_circle_fill : CupertinoIcons.house_fill),
                  cor: store.concluidosHoje.contains(t.id) ? p.verde : p.azul,
                ),
                titulo: t.nome,
                subtitulo: '${horario(t.saida)} · ${store.alunosDo(t).length} alunos',
                fim: store.concluidosHoje.contains(t.id) ? Selo('Feita', cor: p.verde) : null,
                aoTocar: () => abrir(context, RotaTela(trajeto: t)),
              ),
          ],
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}

class _ProximaViagem extends StatelessWidget {
  const _ProximaViagem({required this.store});

  final VanStore store;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    final v = store.viagem;
    final emAndamento = v != null && !v.encerrada;
    final t = emAndamento ? v.trajeto : store.proximoTrajeto;

    if (t == null) {
      return Cartao(
        child: Row(children: [
          IconeApp(CupertinoIcons.moon_fill, cor: p.roxo, tamanho: 44),
          const SizedBox(width: 14),
          const Expanded(child: Text('Viagens de hoje concluídas.\nBom descanso!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        ]),
      );
    }

    final alunos = store.alunosDo(t);
    final ausentes = alunos.where((a) => store.ausenciaHoje(a.id, t.sentido) != null).length;
    const branco = Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(colors: p.heroi, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: p.azul.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (emAndamento) ...[const PontoAoVivo(cor: branco), const SizedBox(width: 8)],
              Text(emAndamento ? 'EM ANDAMENTO' : 'PRÓXIMA VIAGEM',
                  style: TextStyle(color: branco.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const Spacer(),
              Text(horario(t.saida), style: const TextStyle(color: branco, fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.nome, style: const TextStyle(color: branco, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
          Text(
            '${store.escola(t.escolaIds.first).nome} · ${alunos.length - ausentes} alunos${ausentes > 0 ? ' · $ausentes ausente(s)' : ''}',
            style: TextStyle(color: branco.withValues(alpha: 0.8), fontSize: 15),
          ),
          const SizedBox(height: 18),
          Botao(
            emAndamento ? 'Abrir viagem' : 'Iniciar viagem',
            icone: emAndamento ? CupertinoIcons.map_fill : CupertinoIcons.play_fill,
            estilo: EstiloBotao.claro,
            aoTocar: () {
              if (!emAndamento) store.iniciarViagem(t);
              abrirViagem(context);
            },
          ),
        ],
      ),
    );
  }
}
