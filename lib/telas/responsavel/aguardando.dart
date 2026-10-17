import 'package:flutter/cupertino.dart';

import '../../app/formatos.dart';
import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../estado/van_store.dart';
import 'conectar_van.dart';

/// Responsável com conta, mas ainda sem filho liberado: pedido em análise
/// pelo motorista, ou falta digitar o código da van.
class AguardandoAprovacaoTela extends StatelessWidget {
  const AguardandoAprovacaoTela({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.of(context);
    final p = context.cores;
    final pendentes = store.solicitacoesDoResponsavel;
    final esperando = pendentes.isNotEmpty;

    return PaginaIOS(
      titulo: 'Olá, ${primeiroNome(store.nomeSessao)}',
      filhos: [
        Cartao(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              IconeApp(esperando ? CupertinoIcons.hourglass : CupertinoIcons.qrcode, cor: esperando ? p.ambar : p.azul, tamanho: 64),
              const SizedBox(height: 14),
              Text(
                esperando ? 'Pedido enviado ao motorista' : 'Falta o código da van',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                esperando
                    ? '${primeiroNome(store.nomeMotorista)} vai conferir a escola e o endereço e aprovar. Assim que aprovar, o mapa da van aparece aqui.'
                    : 'Peça ao motorista o convite da sua família (ou o código VAN-…) pelo WhatsApp.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textoSuave, height: 1.35),
              ),
              if (!esperando) ...[
                const SizedBox(height: 18),
                Botao('Digitar código', icone: CupertinoIcons.qrcode, aoTocar: () => abrirFolha(context, const ConectarVan())),
              ],
            ],
          ),
        ),
        if (esperando)
          Secao(
            titulo: 'Aguardando aprovação',
            filhos: [
              for (final s in pendentes)
                Linha(
                  inicio: IconeApp(CupertinoIcons.person_fill, cor: p.ambar),
                  titulo: s.nomeAluno,
                  subtitulo: '${s.escolaInformada} · ${s.turno.rotulo}',
                  fim: Selo('Em análise', cor: p.ambar),
                ),
              Linha(
                inicio: IconeApp(CupertinoIcons.qrcode, cor: p.azul),
                titulo: 'Tenho um convite',
                subtitulo: 'Convite da família libera na hora',
                aoTocar: () => abrirFolha(context, const ConectarVan()),
              ),
            ],
          ),
        if (esperando)
          Secao(
            titulo: 'Demonstração',
            rodape: 'Na vida real, a aprovação acontece no celular do motorista (Alunos › Pedidos).',
            filhos: [
              Linha(
                inicio: IconeApp(CupertinoIcons.checkmark_seal_fill, cor: p.verde),
                titulo: 'Simular aprovação do motorista',
                aoTocar: () {
                  final n = store.aprovarPedidosDemonstracao();
                  if (n > 0) avisar(context, 'Pedido aprovado! O mapa da van já está liberado.', icone: CupertinoIcons.checkmark_seal_fill);
                },
              ),
            ],
          ),
        Secao(
          filhos: [
            Linha(
              inicio: IconeApp(CupertinoIcons.square_arrow_right, cor: p.vermelho),
              titulo: 'Sair',
              corTitulo: p.vermelho,
              seta: false,
              aoTocar: store.sair,
            ),
          ],
        ),
      ],
    );
  }
}
