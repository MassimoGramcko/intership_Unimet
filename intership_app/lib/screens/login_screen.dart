import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'student_home_screen.dart'; 
import 'admin_home_screen.dart'; // <--- NUEVO IMPORT: Para poder ir a la pantalla del Admin

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    
    try {
      // 1. Verificar correo y contraseña en Auth
      final user = await authService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null) {
        // 2. Si las credenciales son buenas, buscamos el ROL en la base de datos (Firestore)
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (userDoc.exists) {
            String role = userDoc['role']; // Puede ser 'student' o 'admin'

            if (role == 'student') {
              // --> ES ESTUDIANTE: Vamos a la pantalla principal de Estudiante
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
              );
            } else if (role == 'admin') {
              // --> ES ADMIN: Vamos a la pantalla del Jefe
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
              );
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            
            TextField(
              controller: _emailController, 
              decoration: const InputDecoration(labelText: "Correo", border: OutlineInputBorder())
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController, 
              decoration: const InputDecoration(labelText: "Contraseña", border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Ingresar"),
                ),
            
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text("¿No tienes cuenta? Regístrate aquí"),
            ),
          ],
        ),
      ),
    );
  }
}