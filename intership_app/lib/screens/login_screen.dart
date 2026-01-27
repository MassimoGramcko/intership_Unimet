import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'register_screen.dart';
import 'student_home.dart';      // <--- IMPORTANTE: Importamos vista Estudiante
import 'coordinator_home.dart';  // <--- IMPORTANTE: Importamos vista Coordinador

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. LOGO DE LA UNIMET
                  const Icon(
                    Icons.school, 
                    size: 100, 
                    color: AppTheme.primaryOrange
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "UNIMET INTERNSHIP",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.secondaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),

                  // 2. CAMPOS DE TEXTO
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Correo Electrónico",
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 20),

                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 3. BOTÓN PRINCIPAL (ROL ESTUDIANTE)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navegar al Home del Estudiante
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "INGRESAR",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. ACCESO RÁPIDO: COORDINADOR (SOLO PARA PRUEBAS)
                  // Este botón es temporal para que puedas ver la otra vista
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const CoordinatorHomeScreen())
                      );
                    },
                    child: const Text(
                      "Acceso Rápido: COORDINADOR (Demo)",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const Divider(), // Línea divisoria visual

                  // 5. ENLACE DE REGISTRO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿Eres estudiante nuevo?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Regístrate aquí",
                          style: TextStyle(color: AppTheme.secondaryBlue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}