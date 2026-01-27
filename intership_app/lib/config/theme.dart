import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORES PRINCIPALES ---
  // Definimos el color base una sola vez
  static const Color _baseOrange = Color(0xFFFF6600);
  static const Color _baseBlue = Color(0xFF003366);

  // --- COMPATIBILIDAD (Para que funcionen pantallas viejas y nuevas) ---
  
  // Nombres Nuevos
  static const Color primaryColor = _baseOrange;
  static const Color secondaryBlue = _baseBlue;
  
  // Nombres Antiguos (Legacy) - Esto arregla los errores de Login/Register/Explore
  static const Color primaryOrange = _baseOrange; 
  static const Color surfaceWhite = Colors.white;
  
  // --- COLORES DE ESTADO ---
  static const Color statusGreen = Colors.green;
  static const Color statusRed = Colors.red;
  static const Color statusGrey = Colors.grey;

  // --- TEMA GENERAL ---
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: surfaceWhite,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryBlue,
        surface: surfaceWhite,
      ),
      useMaterial3: true,
      
      // Estilo de botones por defecto
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      
      // Estilo de AppBar por defecto
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
    );
  }
}