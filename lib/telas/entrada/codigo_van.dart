import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../responsavel/conectar_van.dart';

/// Depois de criar a conta, o responsável só entra com o código da van:
/// convite da família (libera na hora) ou código geral VAN-… (vira pedido).
class CodigoVanTela extends StatelessWidget {
  const CodigoVanTela({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Scaffold(
      backgroundColor: p.fundo,
      // A própria folha já sobe com o teclado.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(children: [BotaoVoltar()]),
            ),
            Expanded(child: ConectarVan(entrada: true)),
          ],
        ),
      ),
    );
  }
}
