import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Este archivo YA lo tienes porque lo configuramos antes
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  // 1. Esto es OBLIGATORIO cuando usas Firebase al inicio
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Aquí encendemos la conexión con lo que ya configuraste
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Ahora sí, arrancamos la app visual
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión Pasantías',
      theme: AppTheme.theme, // Tu tema oscuro
      home: const LoginScreen(), // Vamos directo al Login
    );
  }
}