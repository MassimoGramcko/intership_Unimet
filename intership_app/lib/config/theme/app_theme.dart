import 'package:flutter/material.dart';

// Definición de colores de la UNIMET
const Color _customPrimaryColor = Color(0xFF003399); // Azul Profundo
const Color _customSecondaryColor = Color(0xFFFF6600); // Naranja

class AppTheme {
  ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _customPrimaryColor,
        primary: _customPrimaryColor,
        secondary: _customSecondaryColor,
      ),
      // Configuración automática de la AppBar para toda la app
      appBarTheme: const AppBarTheme(
        backgroundColor: _customPrimaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      // Configuración de botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _customSecondaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados modernos
          ),
        ),
      ),
    );
  }
}