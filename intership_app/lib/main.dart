import 'package:flutter/material.dart';
import 'package:intership_app/config/theme/app_theme.dart';
// IMPORTANTE: Asegúrate de importar el Login
import 'package:intership_app/presentation/screens/login_screen.dart'; 

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      // AQUÍ ES EL CAMBIO:
      // Antes decía: home: const HomeScreen(),
      // Ahora debe decir:
      home: const LoginScreen(), 
    );
  }
}