import 'package:flutter/material.dart';

class AppColors {
  // Fondos
  static const Color fondoPrincipal = Color(0xFF0A0A0A);
  static const Color fondoSecundario = Color(0xFF141414);
  static const Color fondoTarjeta = Color(0xFF1C1C1C);
  static const Color fondoInput = Color(0xFF222222);

  // Bordes
  static const Color borde = Color(0xFF2A2A2A);
  static const Color bordeActivo = Color(0xFF444444);

  // Texto
  static const Color textoPrimario = Color(0xFFFFFFFF);
  static const Color textoSecundario = Color(0xFF888888);
  static const Color textoTerciario = Color(0xFF555555);

  // Acento
  static const Color acento = Color(0xFFFFFFFF);
  static const Color acentoSuave = Color(0xFF2A2A2A);
  static const Color acentoTexto = Color(0xFFFFFFFF);

  // Estados
  static const Color exito = Color(0xFF4ADE80);
  static const Color error = Color(0xFFEF4444);
  static const Color advertencia = Color(0xFFFBBF24);
  static const Color info = Color(0xFF60A5FA);

  // Redes
  static const Color redJovenes = Color(0xFF60A5FA);
  static const Color redNinos = Color(0xFF4ADE80);
  static const Color redMujeres = Color(0xFFF97336);
  static const Color redHombres = Color(0xFF888888);
  static const Color redAdultos = Color(0xFFFBBF24);
}

class AppTheme {
  static ThemeData get tema => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.fondoPrincipal,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.acento,
      surface: AppColors.fondoSecundario,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fondoPrincipal,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textoPrimario,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.textoPrimario),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.fondoSecundario,
      selectedItemColor: AppColors.textoPrimario,
      unselectedItemColor: AppColors.textoTerciario,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.textoPrimario,
        foregroundColor: AppColors.fondoPrincipal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(AppColors.textoPrimario),
      checkColor: WidgetStateProperty.all(AppColors.fondoPrincipal),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.textoPrimario),
      trackColor: WidgetStateProperty.all(AppColors.bordeActivo),
    ),
  );
}
