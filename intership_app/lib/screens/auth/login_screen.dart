import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';

// --- RUTAS DE PANTALLAS ---
import '../student/student_home.dart';
import '../Coordinador/coordinator_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true; // <-- NUEVO: Variable para el "ojito" de la contraseña

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LÓGICA PRINCIPAL: LOGIN ---
  Future<void> _login() async {
    // 1. VALIDACIÓN INICIAL (Evita el error feo de Firebase)
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showMessage("⚠️ Por favor, ingresa tu correo y contraseña.", isError: true);
      return; // Detenemos la ejecución aquí
    }

    setState(() => _isLoading = true);
    
    try {
      // 2. INTENTO DE LOGIN
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. VERIFICAR DATOS EN FIRESTORE
      final userDoc = await FirebaseFirestore.instance
          .collection('users') 
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found-db', 
          message: 'El usuario no tiene datos registrados en la base de datos.'
        );
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final String role = userData['role'] ?? 'student';

      // 4. REDIRECCIÓN SEGÚN ROL
      if (mounted) {
        if (role == 'admin' || role == 'coordinator') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CoordinatorHome()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      // 5. MANEJO DE ERRORES DE FIREBASE (Actualizado)
      String message = "Error de autenticación";
      
      switch (e.code) {
        case 'invalid-credential': // <-- NUEVO: El error actual de Firebase
        case 'user-not-found':     // Por si usas una versión antigua
        case 'wrong-password':     // Por si usas una versión antigua
          message = "Correo o contraseña incorrectos. Verifica tus datos.";
          break;
        case 'invalid-email':
          message = "El formato del correo no es válido.";
          break;
        case 'user-disabled':
          message = "Esta cuenta ha sido deshabilitada.";
          break;
        case 'too-many-requests':
          message = "Demasiados intentos fallidos. Intenta más tarde.";
          break;
        case 'user-not-found-db':
          message = e.message ?? "Error de base de datos.";
          break;
        default:
          message = "Error: ${e.message}";
      }
      
      _showMessage(message, isError: true);

    } catch (e) {
      _showMessage("Error de conexión: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA: RECUPERAR CONTRASEÑA ---
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Escribe tu correo arriba para enviarte el link.", isError: true);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage("¡Correo enviado! Revisa tu bandeja de entrada.", isError: false);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? "Error al enviar correo.";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
         msg = "No hay cuenta registrada con este correo.";
      }
      _showMessage(msg, isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER GRÁFICO ---
            Container(
              width: double.infinity,
              height: size.height * 0.35,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    // Nota: Si usas una versión antigua de Flutter y 'withValues' da error, usa 'withOpacity'
                    backgroundColor: Colors.white.withValues(alpha: 0.15), 
                    child: const CircleAvatar(
                      radius: 55,
                      backgroundImage: AssetImage('assets/Logo_app.jpeg'),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Gestión de Pasantías",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Universidad Metropolitana",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                  ),
                ],
              ),
            ),

            // --- FORMULARIO ---
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Iniciar Sesión", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  const Text("Ingresa tus credenciales para continuar", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),

                  // Email
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Correo Institucional",
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryOrange),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // <-- NUEVO: Usa la variable de estado
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryOrange),
                      // <-- NUEVO: Icono interactivo al final del campo
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),

                  // Reset Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botón Acceder
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 10,
                        shadowColor: AppTheme.primaryOrange.withValues(alpha: 0.4),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("ACCEDER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),

                  // Botón Registro
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Regístrate aquí',
                          style: TextStyle(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}