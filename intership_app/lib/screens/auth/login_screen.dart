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
    // 1. VALIDACIÓN INICIAL Y DE FORMATO
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("⚠️ Por favor, ingresa tu correo y contraseña.", isError: true);
      return;
    }

    // Validación de dominio institucional
    if (!email.endsWith('@correo.unimet.edu.ve')) {
      _showMessage("⚠️ El correo debe pertenecer al dominio @correo.unimet.edu.ve.", isError: true);
      return;
    }

    // Validación básica de formato de contraseña (mismo criterio que registro para consistencia)
    final passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegExp.hasMatch(password)) {
      _showMessage(
        "⚠️ Credenciales no válidas. Verifica el formato de tu contraseña.", 
        isError: true
      );
      return;
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
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryOrange),
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
      // --- BOTÓN DEL CHATBOT ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openChatbot(context),
        backgroundColor: AppTheme.primaryOrange,
        elevation: 8,
        tooltip: "Asistente Virtual",
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/mascot.png'),
        ),
      ),
    );
  }

  void _openChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatbotBottomSheet(),
    );
  }
}

// --- WIDGET DEL CHATBOT (ESTILO MERCANTIL/MIA) ---
class ChatbotBottomSheet extends StatefulWidget {
  const ChatbotBottomSheet({super.key});

  @override
  State<ChatbotBottomSheet> createState() => _ChatbotBottomSheetState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, this.isUser = false});
}

class _ChatbotBottomSheetState extends State<ChatbotBottomSheet> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addBotMessage("¡Hola! 👋 Soy tu asistente de Pasantías. ¿En qué puedo ayudarte hoy?");
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
    _handleResponse(text.toLowerCase());
  }

  void _handleResponse(String query) {
    setState(() => _isTyping = true);
    
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      String response = "Lo siento, solo puedo ayudarte con el registro de cuenta o la recuperación de tu clave.";
      
      if (query.contains("hola") || query.contains("saludos")) {
        response = "¡Hola! Soy tu asistente. ¿Necesitas ayuda para registrarte o recuperar tu contraseña?";
      } else if (query.contains("registro") || query.contains("cuenta") || query.contains("registrar")) {
        response = "Para registrarte, usa el botón 'Regístrate aquí' en la parte inferior de la pantalla de inicio. Necesitarás tu correo @correo.unimet.edu.ve. ¿Hay algo más en lo que te pueda ayudar?";
      } else if (query.contains("password") || query.contains("contraseña") || query.contains("clave") || query.contains("olvid")) {
        response = "Si olvidaste tu clave, presiona el enlace '¿Olvidaste tu contraseña?' arriba del botón ACCEDER. Te enviaremos un email para que crees una nueva. ¿Hay algo más en lo que te pueda ayudar?";
      } else if (query.contains("no") || query.contains("gracias") || query.contains("nada") || query.contains("chao") || query.contains("adios")) {
        response = "¡Entendido! Espero haberte ayudado. ¡Éxito en tus pasantías! 👋";
        setState(() {
          _isTyping = false;
          _addBotMessage(response);
        });
        // Cerramos el chat automáticamente después de un breve delay para que lean la despedida
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
        return;
      }

      setState(() {
        _isTyping = false;
        _addBotMessage(response);
      });
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + keyboardHeight,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Header del Chat
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.2),
                  child: Image.asset('assets/mascot.png'),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Asistente Unimet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("En línea", style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          
          // Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_messages.length == 1 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildQuickActions();
                }
                final msg = _messages[index];
                return _buildBubble(msg);
              },
            ),
          ),

          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(alignment: Alignment.centerLeft, child: Text("Escribiendo...", style: TextStyle(color: Colors.grey, fontSize: 12))),
            ),

          // Input
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16 + keyboardHeight),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Escribe tu consulta...",
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _addUserMessage(val.trim());
                        _chatController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  onPressed: () {
                    if (_chatController.text.trim().isNotEmpty) {
                      _addUserMessage(_chatController.text.trim());
                      _chatController.clear();
                    }
                  },
                  backgroundColor: AppTheme.primaryOrange,
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _quickActionChip("¿Cómo me registro?", () => _addUserMessage("¿Cómo me registro?")),
          _quickActionChip("Olvidé mi clave", () => _addUserMessage("Olvidé mi clave")),
        ],
      ),
    );
  }

  Widget _quickActionChip(String label, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.primaryOrange, width: 1),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.primaryOrange : AppTheme.surfaceDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 0),
            bottomRight: Radius.circular(msg.isUser ? 0 : 20),
          ),
        ),
        child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
    );
  }
}