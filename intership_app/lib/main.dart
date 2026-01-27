import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; 
import 'config/theme.dart';
import 'screens/login_screen.dart'; // <--- 1. IMPORTANTE: Agregamos esta línea

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); 
  
  runApp(const UnimetInternshipApp());
}

class UnimetInternshipApp extends StatelessWidget {
  const UnimetInternshipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unimet Internship',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Mantenemos tu tema naranja
      
      // 2. CAMBIO AQUÍ: En lugar del Scaffold de prueba, ponemos el Login
      home: const LoginScreen(), 
    );
  }
}