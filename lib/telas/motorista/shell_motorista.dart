import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../componentes/ui.dart';
import '../../app/tema.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';
import '../../tutoriais/tutoriais.dart';
import 'financeiro.dart';
import 'gestao.dart';
import 'inicio.dart';
import 'rotas.dart';
import 'viagem.dart';

/// Motorista: quatro abas diretas — Início, Rotas, Finanças e Gestão.
class ShellMotorista extends StatefulWidget {
  const ShellMotorista({super.key});

  @override
  State<ShellMotorista> createState() => _ShellMotoristaState();
}

class _ShellMotoristaState extends State<ShellMotorista> {
  int _aba = 0;

  static const _tutoriais = ['inicio', 'rotas', 'financas', 'gestao'];

  void _irPara(int aba) {
    if (aba == _aba) return;
    setState(() => _aba = aba);
    Tutoriais.aoAbrirAba(context, 'motorista.${_tutoriais[aba]}');
  }

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final v = store.viagem;
    final emAndamento = v != null && !v.encerrada;
    final pendencias = store.atrasadas.length + store.informadas.length;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _aba,
        children: [
          InicioTela(irPara: _irPara),
          const RotasTela(),
          const FinanceiroTela(),
          const GestaoTela(),
        ],
      ),
      bottomNavigationBar: BarraAbas(
        indice: _aba,
        aoMudar: _irPara,
        topo: emAndamento
            ? Tocavel(
                aoTocar: () => abrirViagem(context),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: store.emergenciaEm != null ? p.vermelho : p.azul,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const PontoAoVivo(cor: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          store.emergenciaEm != null ? 'Emergência ativa' : '${v.trajeto.nome} · ${v.aBordo} a bordo',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_up, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              )
            : null,
        itens: [
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), activeIcon: Icon(CupertinoIcons.house_fill), label: 'Início'),
          const BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), activeIcon: Icon(CupertinoIcons.map_fill), label: 'Rotas'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pendencias > 0,
              label: Text('$pendencias'),
              backgroundColor: p.vermelho,
              child: const Icon(CupertinoIcons.chart_bar),
            ),
            activeIcon: const Icon(CupertinoIcons.chart_bar_fill),
            label: 'Finanças',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: store.solicitacoes.isNotEmpty,
              label: Text('${store.solicitacoes.length}'),
              backgroundColor: p.vermelho,
              child: const Icon(CupertinoIcons.square_grid_2x2),
            ),
            activeIcon: const Icon(CupertinoIcons.square_grid_2x2_fill),
            label: 'Gestão',
          ),
        ],
      ),
    );
  }
}

/// Inicia a viagem conferindo antes se a van já está em uso (outro aparelho ou outra viagem).
Future<void> iniciarViagemComCuidado(BuildContext context, Trajeto t, {bool fecharTelaAtual = false}) async {
  final store = VanScope.read(context);
  final conflito = store.conflitoAoIniciar(t);
  if (conflito != null) {
    final ok = await confirmar(context, titulo: 'Iniciar mesmo assim?', mensagem: conflito, acao: 'Iniciar aqui', destrutiva: true);
    if (!ok || !context.mounted) return;
    store.assumirVan(t.veiculoId);
  }
  store.iniciarViagem(t);
  if (!context.mounted) return;
  if (fecharTelaAtual) {
    Navigator.of(context).pushReplacement(_rotaViagem());
  } else {
    abrirViagem(context);
  }
}

PageRouteBuilder<void> _rotaViagem() => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => const ViagemTela(),
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
        child: child,
      ),
    );

void abrirViagem(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => const ViagemTela(),
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
        child: child,
      ),
    ),
  );
}
