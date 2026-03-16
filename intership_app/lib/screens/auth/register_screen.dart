import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- CONTROLADORES ---
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ciController = TextEditingController();
  final _carnetController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Variable para el Dropdown de carreras
  String? _selectedCareer;
  
  // Lista de carreras de la Unimet (Puedes agregar más)
  final List<String> _careers = [
    'Ingeniería de Sistemas',
    'Ingeniería Civil',
    'Ingeniería Mecánica',
    'Ingeniería Química',
    'Ingeniería de Producción',
    'Administración',
    'Contaduría Pública',
    'Economía',
    'Derecho',
    'Psicología',
    'Idiomas Modernos',
    'Estudios Liberales',
    'Matemáticas Industriales',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _ciController.dispose();
    _carnetController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE REGISTRO ---
  Future<void> _register() async {
    // 1. Validaciones básicas y de formato
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (_nameController.text.isEmpty || 
        _lastNameController.text.isEmpty ||
        _selectedCareer == null ||
        email.isEmpty ||
        password.isEmpty) {
      _showMessage("⚠️ Por favor completa todos los campos obligatorios.", isError: true);
      return;
    }

    // Validación de dominio institucional
    if (!email.endsWith('@correo.unimet.edu.ve')) {
      _showMessage("⚠️ Debes usar tu correo institucional (@correo.unimet.edu.ve).", isError: true);
      return;
    }

    // Validación de seguridad de contraseña (Mínimo 8 caracteres, una mayúscula, una minúscula y un número)
    final passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegExp.hasMatch(password)) {
      _showMessage(
        "⚠️ La contraseña debe tener al menos 8 caracteres, incluir una mayúscula, una minúscula y un número.", 
        isError: true
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Crear usuario en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. Guardar datos extra en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'ci': _ciController.text.trim(),
        'carnet': _carnetController.text.trim(),
        'career': _selectedCareer,
        'email': _emailController.text.trim(),
        'role': 'student', // Por defecto todos los que se registran por aquí son estudiantes
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showMessage("¡Cuenta creada con éxito!", isError: false);
        // Volver al Login o ir al Home (Decidimos ir al Login para que se loguee limpio)
        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Error al registrarse.";
      if (e.code == 'email-already-in-use') message = "El correo ya está registrado.";
      if (e.code == 'weak-password') message = "La contraseña es muy débil (mínimo 6 caracteres).";
      _showMessage(message, isError: true);
    } catch (e) {
      _showMessage("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER COMPACTO ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Icon(Icons.person_add_outlined, size: 50, color: AppTheme.primaryOrange),
                    const SizedBox(height: 10),
                    const Text(
                      "Crear Nueva Cuenta",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Únete a la comunidad de pasantías",
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),

            // --- FORMULARIO ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // SECCIÓN 1: DATOS PERSONALES
                  _buildSectionTitle("Datos Personales"),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(child: _buildTextField(controller: _nameController, label: "Nombres", icon: Icons.person_outline)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField(controller: _lastNameController, label: "Apellidos", icon: Icons.person_outline)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(controller: _ciController, label: "Cédula de Identidad", icon: Icons.badge_outlined, keyboardType: TextInputType.number),

                  const SizedBox(height: 30),

                  // SECCIÓN 2: DATOS ACADÉMICOS
                  _buildSectionTitle("Información Académica"),
                  const SizedBox(height: 15),
                  _buildTextField(controller: _carnetController, label: "Carnet Unimet", icon: Icons.card_membership, keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  
                  // DROPDOWN DE CARRERAS
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1E293B), // Fondo oscuro para el menú desplegable
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Selecciona tu Carrera",
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.school_outlined, color: AppTheme.primaryOrange),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    value: _selectedCareer,
                    items: _careers.map((career) {
                      return DropdownMenuItem(
                        value: career,
                        child: Text(career),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCareer = val),
                  ),

                  const SizedBox(height: 30),

                  // SECCIÓN 3: CUENTA
                  _buildSectionTitle("Seguridad de la Cuenta"),
                  const SizedBox(height: 15),
                  _buildTextField(controller: _emailController, label: "Correo Institucional", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _buildTextField(controller: _passwordController, label: "Crear Contraseña", icon: Icons.lock_outline, isPassword: true),

                  const SizedBox(height: 40),

                  // BOTÓN DE REGISTRO
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: AppTheme.primaryOrange.withValues(alpha: 0.4),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("CREAR CUENTA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  
                  // FOOTER
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿Ya tienes cuenta?", style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Inicia sesión aquí", style: TextStyle(color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA TÍTULOS DE SECCIÓN ---
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: AppTheme.primaryOrange), // Barrita naranja decorativa
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- WIDGET AUXILIAR PARA INPUTS ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: AppTheme.primaryOrange),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}