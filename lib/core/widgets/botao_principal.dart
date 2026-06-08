import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BotaoPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback aoClicar;

  const BotaoPrincipal({
    super.key,
    required this.texto,
    required this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: aoClicar,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.azulPrincipal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        elevation: 0, // Visual plano e moderno como na imagem
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0), // Formato pílula
        ),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}