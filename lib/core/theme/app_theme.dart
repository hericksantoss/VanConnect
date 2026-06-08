import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.fundoBranco,
      useMaterial3: true,
      
      // Configuração padrão de todos os Inputs (Campos de Texto) do App
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.campoCinza,
        hintStyle: const TextStyle(color: AppColors.textoSuave, fontSize: 14),
        prefixIconColor: AppColors.textoSuave,
        suffixIconColor: AppColors.textoSuave,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none, // Sem borda linear, estilo caixa clean
        ),
      ),
    );
  }
}