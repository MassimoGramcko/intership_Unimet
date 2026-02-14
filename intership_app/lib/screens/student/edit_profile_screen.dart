import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores solo para los datos Reales
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _carnetController = TextEditingController();
  final _careerController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _carnetController.dispose();
    _careerController.dispose();
    super.dispose();
  }

  // 1. Cargar datos existentes de Firebase
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _carnetController.text = data['carnet'] ?? '';
          _careerController.text = data['career'] ?? '';
          _isLoading = false;
        });
      }
    }
  }

  // 2. Guardar datos en Firebase
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'firstName': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'carnet': _carnetController.text.trim(), // Actualizamos el Carnet
        'career': _careerController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Datos actualizados correctamente! ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Regresar al perfil
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text("Editar Datos Personales"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Información del Estudiante", 
                      style: TextStyle(color: AppTheme.primaryOrange, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Estos datos aparecerán en tus postulaciones.",
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                    const SizedBox(height: 25),
                    
                    // --- CAMPO: NOMBRE ---
                    _buildNeonTextField(
                      controller: _nameController, 
                      label: "Nombre", 
                      icon: Icons.person_outline
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: APELLIDO ---
                    _buildNeonTextField(
                      controller: _lastNameController, 
                      label: "Apellido", 
                      icon: Icons.person_outline
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: CARNET ---
                    _buildNeonTextField(
                      controller: _carnetController, 
                      label: "Carnet de Estudiante", 
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.text // Puede tener letras y números
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: CARRERA ---
                    _buildNeonTextField(
                      controller: _careerController, 
                      label: "Carrera", 
                      icon: Icons.school_outlined
                    ),

                    const SizedBox(height: 50),

                    // --- BOTÓN GUARDAR ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          shadowColor: AppTheme.primaryOrange.withOpacity(0.5),
                          elevation: 10,
                        ),
                        child: const Text(
                          "Guardar Cambios",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget personalizado para inputs (Estilo Neón)
  Widget _buildNeonTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // surfaceDark
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppTheme.primaryOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Este campo es obligatorio";
          }
          return null;
        },
      ),
    );
  }
}