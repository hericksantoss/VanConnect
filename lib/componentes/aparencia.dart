import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app/tema.dart';
import '../estado/van_store.dart';
import 'ui.dart';

/// Seletor de aparência no estilo do iOS: Automático / Claro / Escuro.
class SecaoAparencia extends StatelessWidget {
  const SecaoAparencia({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: store.tema,
      builder: (context, modo, _) => Secao(
        titulo: 'Aparência',
        rodape: modo == ThemeMode.system ? 'Segue o modo claro/escuro do celular.' : null,
        filhos: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Row(
              children: [
                for (final (m, rotulo, claro) in [
                  (ThemeMode.light, 'Claro', true),
                  (ThemeMode.dark, 'Escuro', false),
                  (ThemeMode.system, 'Automático', null),
                ])
                  Expanded(
                    child: Tocavel(
                      aoTocar: () => store.definirTema(m),
                      child: Column(
                        children: [
                          _Miniatura(claro: claro, selecionado: modo == m),
                          const SizedBox(height: 8),
                          Text(
                            rotulo,
                            style: TextStyle(fontSize: 14, color: p.texto, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: modo == m ? p.azul : Colors.transparent,
                              border: Border.all(color: modo == m ? p.azul : p.cinza.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: modo == m ? const Icon(CupertinoIcons.checkmark_alt, size: 15, color: Colors.white) : null,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Miniatura de "celular" mostrando o tema (null = metade de cada, automático).
class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.claro, required this.selecionado});

  final bool? claro;
  final bool selecionado;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    Widget tela(Paleta t) => ColoredBox(
      color: t.fundo,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 6,
              width: 26,
              decoration: BoxDecoration(color: t.texto, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 6),
            Container(
              height: 18,
              decoration: BoxDecoration(color: t.cartao, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 4),
            Container(
              height: 18,
              decoration: BoxDecoration(color: t.cartao, borderRadius: BorderRadius.circular(4)),
            ),
            const Spacer(),
            Container(
              height: 8,
              decoration: BoxDecoration(color: t.azul, borderRadius: BorderRadius.circular(3)),
            ),
          ],
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 64,
      height: 104,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: selecionado ? p.azul : p.separador, width: selecionado ? 2.5 : 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: switch (claro) {
          true => tela(Paleta.claro),
          false => tela(Paleta.noturno),
          null => Row(
            children: [
              Expanded(
                child: ClipRect(
                  child: OverflowBox(alignment: Alignment.centerLeft, maxWidth: 59, child: tela(Paleta.claro)),
                ),
              ),
              Expanded(
                child: ClipRect(
                  child: OverflowBox(alignment: Alignment.centerRight, maxWidth: 59, child: tela(Paleta.noturno)),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
