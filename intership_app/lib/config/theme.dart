import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORES NUEVOS (MODO DARK) ---
  static const Color backgroundDark = Color(0xFF0F172A); 
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textGrey = Color(0xFF94A3B8);

  // --- ZONA DE COMPATIBILIDAD (PARA QUE NO DE ERROR EL CÓDIGO VIEJO) ---
  // Estas son las líneas que faltaban y causaban los errores rojos en otras pantallas:
  static const Color secondaryBlue = surfaceDark; 
  static const Color primaryColor = primaryOrange;

  // --- TEMA GLOBAL ---
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto', 
    
    // 1. Colores Principales
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primaryOrange,
    cardColor: surfaceDark, // Solución rápida para las tarjetas
    
    colorScheme: const ColorScheme.dark(
      primary: primaryOrange,
      secondary: primaryOrange,
      surface: surfaceDark,
      background: backgroundDark,
      error: Color(0xFFEF4444),
    ),

    // 2. AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textWhite,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: textWhite),
    ),

    // 3. Botones
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 5,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),

    // 4. Inputs (Campos de texto) - Actualizado a 'withValues'
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      hintStyle: const TextStyle(color: textGrey),
      labelStyle: const TextStyle(color: textWhite),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        // Usamos withValues porque tu Flutter es muy moderno
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
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
    iconTheme: const IconThemeData(color: textWhite),
  );
}