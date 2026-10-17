import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import '../../tutoriais/tutoriais.dart';
import 'aguardando.dart';
import 'ajustes_responsavel.dart';
import 'ausencias.dart';
import 'filhos.dart';
import 'mapa_principal.dart';
import 'pagamentos.dart';

class ShellResponsavel extends StatefulWidget {
  const ShellResponsavel({super.key});

  @override
  State<ShellResponsavel> createState() => _ShellResponsavelState();
}

class _ShellResponsavelState extends State<ShellResponsavel> {
  int _aba = 0;

  List<String> _abas(VanStore store) => ['mapa', 'filhos', 'avisos', if (store.podeAgir) 'pagamentos', 'ajustes'];

  void _irPara(int aba) {
    if (aba == _aba) return;
    setState(() => _aba = aba);
    Tutoriais.aoAbrirAba(context, 'responsavel.${_abas(VanScope.read(context))[aba]}');
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    // Conta nova: só entra no app depois que o motorista libera (ou com convite).
    if (store.filhosDoResponsavel.isEmpty) return const AguardandoAprovacaoTela();
    final p = context.cores;
    final hoje = DateTime.now();
    final abertas = store.filhosDoResponsavel
        .expand(store.cobrancasDo)
        .where((c) => const [StatusCobranca.pendente, StatusCobranca.atrasada].contains(c.status(hoje)))
        .length;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _aba.clamp(0, _abas(store).length - 1),
        children: [
          const MapaPrincipalTela(),
          const FilhosTela(),
          const AvisosTela(),
          if (store.podeAgir) const PagamentosTela(),
          const AjustesResponsavelTela(),
        ],
      ),
      bottomNavigationBar: BarraAbas(
        indice: _aba.clamp(0, _abas(store).length - 1),
        aoMudar: _irPara,
        itens: [
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), activeIcon: Icon(CupertinoIcons.map_fill), label: 'Mapa'),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2),
            activeIcon: Icon(CupertinoIcons.person_2_fill),
            label: 'Filhos',
          ),
          BottomNavigationBarItem(
            icon: Badge(isLabelVisible: store.emergenciaEm != null, backgroundColor: p.vermelho, child: const Icon(CupertinoIcons.bell)),
            activeIcon: const Icon(CupertinoIcons.bell_fill),
            label: 'Avisos',
          ),
          if (store.podeAgir)
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: abertas > 0,
                label: Text('$abertas'),
                backgroundColor: p.vermelho,
                child: const Icon(CupertinoIcons.creditcard),
              ),
              activeIcon: const Icon(CupertinoIcons.creditcard_fill),
              label: 'Pagamentos',
            ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear_alt),
            activeIcon: Icon(CupertinoIcons.gear_alt_fill),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
