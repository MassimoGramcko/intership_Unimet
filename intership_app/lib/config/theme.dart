import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORES NUEVOS (MODO LIGHT) ---
  static const Color backgroundLight = Color(0xFFF8FAFC); // Blanco ahumado
  static const Color surfaceLight = Color(
    0xFFFFFFFF,
  ); // Blanco puro para tarjetas
  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color textPrimary = Color(0xFF1E293B); // Pizarra oscura
  static const Color textSecondary = Color(0xFF64748B); // Gris pizarra

  // (Opcional) Color de icono y acentos
  static const Color iconColor = Color(0xFF475569);

  // --- ZONA DE COMPATIBILIDAD (PARA QUE NO DE ERROR EL CÓDIGO VIEJO) ---
  // Mantenemos los nombres antiguos por un momento mientras refactorizamos
  // para que la app no se rompa de golpe, pero apuntando a los colores claros.
  static const Color backgroundDark = backgroundLight;
  static const Color surfaceDark = surfaceLight;
  static const Color textWhite = textPrimary;
  static const Color textGrey = textSecondary;

  static const Color secondaryBlue = surfaceLight;
  static const Color primaryColor = primaryOrange;

  // --- TEMA GLOBAL ---
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light, // Cambiado a light
    fontFamily: 'Roboto',

    // 1. Colores Principales
    scaffoldBackgroundColor: primaryOrange,
    primaryColor: primaryOrange,
    cardColor: surfaceLight,

    colorScheme: const ColorScheme.light(
      // Cambiado a light
      primary: primaryOrange,
      secondary: primaryOrange,
      surface:
          surfaceLight, // Asegurarse de que en Flutter 3.19+ background y surface estén bien
      error: Color(0xFFEF4444),
    ),

    // 2. AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryOrange,
      elevation: 0,
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // 3. Botones
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 5,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    ),

    // 4. Inputs (Campos de texto)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      hintStyle: const TextStyle(color: textSecondary),
      labelStyle: const TextStyle(color: textPrimary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
          width: 1,
        ), // Borde suave (slate-200)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
    ),

    // 5. Iconos
    iconTheme: const IconThemeData(color: iconColor),
  );
}
