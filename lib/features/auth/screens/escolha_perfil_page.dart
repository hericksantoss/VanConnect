import 'package:flutter/material.dart';
import 'cadastro_motorista_page.dart';
import 'cadastro_pai_page.dart';

class EscolhaPerfilPage extends StatelessWidget {
  const EscolhaPerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Crie sua conta",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // CARD DO MOTORISTA
            _buildPerfilCard(
              context: context,
              titulo: "Sou Motorista",
              subtitulo: "Gerencie suas rotas, vans e passageiros.",
              icone: Icons.directions_bus_rounded,
              corIcone: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CadastroMotoristaPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // CARD DO PAI / RESPONSÁVEL
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
                    builder: (context) => const CadastroPaiPage(),
                  ),
                );
              },
            ),
          ],
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
          border: Border.all(color: Colors.black12, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                mainAxisAlignment: MainAxisAlignment.start,
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
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
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
