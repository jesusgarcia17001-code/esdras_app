import 'package:flutter/material.dart';

class AppColors {
  // Fondos
  static const Color fondoPrincipal = Color(0xFFF5F7FB);
  static const Color fondoSecundario = Color(0xFFFFFFFF);
  static const Color fondoTarjeta = Color(0xFFFFFFFF);
  static const Color fondoInput = Color(0xFFF1F4F9);

  // Bordes
  static const Color borde = Color(0xFFE2E8F0);
  static const Color bordeActivo = Color(0xFF3B82F6);

  // Texto
  static const Color textoPrimario = Color(0xFF0F172A);
  static const Color textoSecundario = Color(0xFF64748B);
  static const Color textoTerciario = Color(0xFF94A3B8);

  // Acento
  static const Color acento = Color(0xFF2F6FED);
  static const Color acentoSuave = Color(0xFFE8EFFD);
  static const Color acentoTexto = Color(0xFFFFFFFF);

  // Estados
  static const Color exito = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color advertencia = Color(0xFFD97706);
  static const Color info = Color(0xFF2563EB);

  // Redes
  static const Color redJovenes = Color(0xFF2F6FED);
  static const Color redNinos = Color(0xFF16A34A);
  static const Color redMujeres = Color(0xFFEA580C);
  static const Color redHombres = Color(0xFF64748B);
  static const Color redAdultos = Color(0xFFD97706);
}

class AppTheme {
  static ThemeData get tema => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.fondoPrincipal,
    colorScheme: const ColorScheme.light(
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
      selectedItemColor: AppColors.acento,
      unselectedItemColor: AppColors.textoTerciario,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.acento,
        foregroundColor: AppColors.acentoTexto,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(AppColors.acento),
      checkColor: WidgetStateProperty.all(AppColors.acentoTexto),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.acento),
      trackColor: WidgetStateProperty.all(AppColors.bordeActivo),
    ),
  );
}
