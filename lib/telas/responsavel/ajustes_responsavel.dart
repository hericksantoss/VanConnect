import 'package:flutter/cupertino.dart';

import '../../app/tema.dart';
import '../../componentes/aparencia.dart';
import '../../componentes/ui.dart';
import '../../estado/van_store.dart';
import '../../tutoriais/tutoriais.dart';

class AjustesResponsavelTela extends StatelessWidget {
  const AjustesResponsavelTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final filhos = store.filhosDoResponsavel.map(store.aluno).toList();
    final eu = filhos.first.responsavel;

    return PaginaIOS(
      titulo: 'Ajustes',
      filhos: [
        Cartao(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Avatar(eu.nome, tamanho: 58),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(eu.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                Text(eu.telefone, style: TextStyle(color: p.textoSuave)),
              ]),
            ),
          ]),
        ),
        const SecaoAparencia(),
        Secao(
          titulo: 'Notificações',
          filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.bell_fill, cor: p.azul),
              titulo: 'Van a caminho',
              fim: const _Chave(),
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.checkmark_seal_fill, cor: p.azul),
              titulo: 'Embarque e chegada',
              fim: const _Chave(),
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
              inicio: const IconeApp(CupertinoIcons.bus, cor: Paleta.azulMarca),
              titulo: 'Ver como motorista',
              aoTocar: () => store.escolherPerfil(Perfil.motorista),
            ),
            Linha(
              inicio: IconeApp(CupertinoIcons.square_arrow_right, cor: p.cinza),
              titulo: 'Sair',
              corTitulo: p.vermelho,
              seta: false,
              aoTocar: () => store.escolherPerfil(null),
            ),
          ],
        ),
        const SizedBox(height: 70),
      ],
    );
  }
}

/// Preferência local de demonstração (sem backend de notificações ainda).
class _Chave extends StatefulWidget {
  const _Chave();

  @override
  State<_Chave> createState() => _ChaveState();
}

class _ChaveState extends State<_Chave> {
  bool _ligado = true;

  @override
  Widget build(BuildContext context) =>
      CupertinoSwitch(value: _ligado, activeTrackColor: context.cores.azul, onChanged: (v) => setState(() => _ligado = v));
}
