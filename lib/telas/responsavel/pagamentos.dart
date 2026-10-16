import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../dominio/modelos.dart';
import '../../estado/van_store.dart';

class PagamentosTela extends StatelessWidget {
  const PagamentosTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final hoje = DateTime.now();
    final todas = store.filhosDoResponsavel.expand(store.cobrancasDo).toList()
      ..sort((a, b) => b.vencimento.compareTo(a.vencimento));
    final abertas = todas.where((c) => const [StatusCobranca.pendente, StatusCobranca.atrasada].contains(c.status(hoje))).toList();
    final total = abertas.fold<double>(0, (s, c) => s + c.valor);

    return PaginaIOS(
      titulo: 'Pagamentos',
      filhos: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(colors: p.heroi, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(abertas.isEmpty ? 'Tudo em dia 🎉' : 'Em aberto', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
              Text(moeda(total), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1)),
              if (abertas.isNotEmpty) ...[
                const SizedBox(height: 14),
                Botao('Copiar chave Pix', estilo: EstiloBotao.claro, icone: CupertinoIcons.doc_on_doc_fill, aoTocar: () {
                  Clipboard.setData(const ClipboardData(text: 'pix-demonstracao@vanconnect.app'));
                  avisar(context, 'Chave Pix copiada (demonstração)', icone: CupertinoIcons.doc_on_doc_fill);
                }),
              ],
            ],
          ),
        ),
        Secao(
          titulo: 'Histórico',
          rodape: 'Pagou fora do app? Toque em "Já paguei" e o motorista confirma.',
          filhos: [
            for (final c in todas)
              Linha(
                inicio: Avatar(store.aluno(c.alunoId).nome, tamanho: 34),
                titulo: '${store.aluno(c.alunoId).primeiro} · ${capitalizar(mesAno(c.competencia))}',
                subtitulo: '${moeda(c.valor)} · vence ${dataCurta(c.vencimento)}',
                fim: switch (c.status(hoje)) {
                  StatusCobranca.pendente || StatusCobranca.atrasada => Botao(
                      'Já paguei',
                      compacto: true,
                      estilo: c.status(hoje) == StatusCobranca.atrasada ? EstiloBotao.destrutivo : EstiloBotao.secundario,
                      aoTocar: () {
                        store.informarPagamento(c);
                        avisar(context, 'Avisamos o motorista para confirmar');
                      },
                    ),
                  StatusCobranca.informada => Selo('Confirmando', cor: p.laranja, icone: CupertinoIcons.hourglass),
                  StatusCobranca.paga => Selo('Paga', cor: p.verde, icone: CupertinoIcons.checkmark_alt),
                },
              ),
          ],
        ),
        const SizedBox(height: 70),
      ],
    );
  }
}
