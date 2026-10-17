import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import 'conectar_van.dart';

class FilhosTela extends StatelessWidget {
  const FilhosTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final filhos = store.filhosDoResponsavel.map(store.aluno).toList();
    final pendentes = store.solicitacoesDoResponsavel;

    return PaginaIOS(
      titulo: 'Filhos',
      acao: !store.podeAgir
          ? null
          : CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => abrirFolha(context, const ConectarVan()),
              child: Icon(CupertinoIcons.add_circled_solid, size: 28, color: p.azul),
            ),
      filhos: [
        for (final f in filhos) ...[_CartaoFilho(aluno: f), const SizedBox(height: 14)],
        if (pendentes.isNotEmpty)
          Secao(
            titulo: 'Aguardando o motorista',
            filhos: [
              for (final s in pendentes)
                Linha(
                  inicio: IconeApp(CupertinoIcons.hourglass, cor: p.laranja),
                  titulo: s.nomeAluno,
                  subtitulo: '${s.escolaInformada} · ${s.turno.rotulo}',
                ),
            ],
          ),
        if (store.podeAgir)
          Secao(
            filhos: [
              Linha(
                inicio: IconeApp(CupertinoIcons.paperplane_fill, cor: p.azul),
                titulo: 'Adicionar filho com convite',
                subtitulo: 'Use o link ou o código que o motorista enviou',
                corTitulo: p.azul,
                aoTocar: () => abrirFolha(context, const ConectarVan()),
              ),
            ],
          ),
        const SizedBox(height: 90),
      ],
    );
  }
}

class _CartaoFilho extends StatelessWidget {
  const _CartaoFilho({required this.aluno});

  final Aluno aluno;

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final escola = store.escola(aluno.escolaId);
    final rotas = store.trajetosOrdenados.where((t) => t.alunoIds.contains(aluno.id)).toList();
    final idade = DateTime.now().year - aluno.nascimento.year;

    return Cartao(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Avatar(aluno.nome, tamanho: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(aluno.nome, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                      Text('$idade anos · ${aluno.serie}', style: TextStyle(color: p.textoSuave)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: p.separador),
          Linha(
            inicio: const IconeApp(CupertinoIcons.book_fill, cor: Paleta.azulMarca),
            titulo: escola.nome,
            subtitulo: 'Aulas ${horario(escola.entrada)} – ${horario(escola.saida)} · ${aluno.turno.rotulo}',
          ),
          for (final t in rotas)
            Linha(
              inicio: IconeApp(t.sentido == Sentido.ida ? CupertinoIcons.arrow_right_circle_fill : CupertinoIcons.house_fill, cor: p.azul),
              titulo: t.sentido == Sentido.ida ? 'Busca em casa' : 'Volta para casa',
              subtitulo: 'Van sai às ${horario(t.saida)}',
            ),
          Linha(
            inicio: IconeApp(CupertinoIcons.location_fill, cor: p.cinza),
            titulo: aluno.endereco,
            subtitulo: 'Endereço de embarque',
          ),
          if (aluno.cuidados.isNotEmpty)
            Linha(
              inicio: IconeApp(CupertinoIcons.heart_fill, cor: p.vermelho),
              titulo: aluno.cuidados,
              subtitulo: 'O motorista vê este aviso na chamada',
            ),
        ],
      ),
    );
  }
}
