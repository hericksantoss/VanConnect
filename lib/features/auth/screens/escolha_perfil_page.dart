import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/theme/app_colors.dart';
import 'cadastro_motorista_page.dart';
import 'cadastro_pai_page.dart';
import 'login_screen.dart';

class EscolhaPerfilPage extends StatefulWidget {
  final String? uid;
  final String? email;
  final String? nomeInicial;
  final String? fotoUrl;

  const EscolhaPerfilPage({
    super.key,
    this.uid,
    this.email,
    this.nomeInicial,
    this.fotoUrl,
  });

  @override
  State<EscolhaPerfilPage> createState() => _EscolhaPerfilPageState();
}

class _EscolhaPerfilPageState extends State<EscolhaPerfilPage> {
  Future<void> _cancelarESair() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
      }

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print("Erro ao cancelar fluxo de perfil: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("====== TESTE DE FLUXO VANCONNECT ======");
    print("UID recebido: ${widget.uid}");
    print("Email recebido: ${widget.email}");
    print("Nome recebido: ${widget.nomeInicial}");
    print("=======================================");
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _cancelarESair();
      },
      child: Scaffold(
        backgroundColor: AppColors.fundoBranco,
        appBar: AppBar(
          backgroundColor: AppColors.fundoBranco,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancelarESair,
          ),
          title: const Text(
            "Crie sua conta",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Quem é você no VanConnect?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Escolha o seu perfil para personalizarmos sua experiência.",
                style: TextStyle(fontSize: 14, color: AppColors.textoSuave),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              _buildPerfilCard(
                context: context,
                titulo: "Sou Motorista",
                subtitulo: "Gerencie suas rotas, vans e passageiros.",
                icone: Icons.directions_bus_rounded,
                corIcone: AppColors.azulPrincipal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CadastroMotoristaPage(
                        uid: widget.uid,
                        email: widget.email,
                        nomeInicial: widget.nomeInicial,
                        fotoUrl: widget.fotoUrl,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildPerfilCard(
                context: context,
                titulo: "Sou Pai / Responsável",
                subtitulo: "Acompanhe o transporte do seu filho em tempo real.",
                icone: Icons.family_restroom_rounded,
                corIcone: Colors.green[700]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CadastroPaiPage(
                        uid: widget.uid,
                        email: widget.email,
                        nomeInicial: widget.nomeInicial,
                        fotoUrl: widget.fotoUrl,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilCard({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color corIcone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: corIcone.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: corIcone, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.black26,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
