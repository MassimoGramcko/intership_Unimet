import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- 1. Importar esto
import 'screens/login_screen.dart'; 

void main() async { // <--- 2. Agregar 'async' aquí
  WidgetsFlutterBinding.ensureInitialized(); // <--- 3. Agregar esta línea obligatoria
  await Firebase.initializeApp(); // <--- 4. Iniciar Firebase
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Internship App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(), 
    );
  }
}