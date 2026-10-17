import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../../componentes/ui.dart';
import '../../estado/van_store.dart';
import 'entrar_conta.dart';

class BoasVindas extends StatelessWidget {
  const BoasVindas({super.key});

  @override
  Widget build(BuildContext context) {
    final store = VanScope.read(context);
    final p = context.cores;

    return Scaffold(
      backgroundColor: p.escuro ? p.fundo : Colors.white,
      body: SafeArea(
        // Rolável: nunca estoura em telas baixas.
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),
                    if (!p.escuro)
                      Center(child: Image.asset('assets/logo.png', height: 170, fit: BoxFit.contain))
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 56),
                        child: Center(child: LogoVanConnect(tamanho: 34)),
                      ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    Text(
                      'A van escolar,\nconectada com a família.',
                      style: TextStyle(fontSize: 30, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -1, color: p.texto),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Acompanhe ao vivo, avise ausências e organize rotas e mensalidades.',
                      style: TextStyle(fontSize: 16, color: p.textoSuave, height: 1.35),
                    ),
                    const SizedBox(height: 28),
                    _Opcao(
                      icone: CupertinoIcons.bus,
                      cor: p.azul,
                      titulo: 'Sou motorista',
                      texto: 'Cadastre-se com seus dados e a van',
                      aoTocar: () => abrir(context, const EntrarContaTela(perfil: Perfil.motorista)),
                    ),
                    const SizedBox(height: 10),
                    _Opcao(
                      icone: CupertinoIcons.person_2_fill,
                      cor: p.azul,
                      titulo: 'Sou responsável',
                      texto: 'Crie a conta e use o código da van',
                      aoTocar: () => abrir(context, const EntrarContaTela(perfil: Perfil.responsavel)),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Ver demonstração:', style: TextStyle(color: p.textoSuave, fontSize: 13.5)),
                        TextButton(onPressed: store.entrarDemonstracaoMotorista, child: const Text('Motorista')),
                        TextButton(onPressed: store.entrarDemonstracaoResponsavel, child: const Text('Família')),
                      ],
                    ),
                    Center(
                      child: Text('Protótipo · dados fictícios', style: TextStyle(color: p.textoSuave, fontSize: 12.5)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({required this.icone, required this.cor, required this.titulo, required this.texto, required this.aoTocar});

  final IconData icone;
  final Color cor;
  final String titulo;
  final String texto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.cores;
    return Cartao(
      aoTocar: aoTocar,
      cor: p.escuro ? p.cartao : p.fundo,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconeApp(icone, cor: cor, tamanho: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(texto, style: TextStyle(color: p.textoSuave)),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, size: 18, color: p.cinza),
        ],
      ),
    );
  }
}
