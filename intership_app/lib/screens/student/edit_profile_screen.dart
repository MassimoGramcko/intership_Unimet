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
  final _semesterController = TextEditingController();
  final _academicIndexController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _skillsController = TextEditingController();

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
    _semesterController.dispose();
    _academicIndexController.dispose();
    _aboutMeController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  // 1. Cargar datos existentes de Firebase
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _carnetController.text = data['carnet'] ?? '';
          _careerController.text = data['career'] ?? '';
          _semesterController.text = data['semester'] ?? '';
          _academicIndexController.text = data['academicIndex'] ?? '';
          _aboutMeController.text = data['aboutMe'] ?? '';
          // Convertir lista de habilidades a texto separado por comas
          final skills = data['skills'];
          if (skills is List) {
            _skillsController.text = skills.join(', ');
          } else if (skills is String) {
            _skillsController.text = skills;
          }
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'firstName': _nameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'carnet': _carnetController.text.trim(),
            'career': _careerController.text.trim(),
            'semester': _semesterController.text.trim(),
            'academicIndex': _academicIndexController.text.trim(),
            'aboutMe': _aboutMeController.text.trim(),
            // Guardar habilidades como lista
            'skills': _skillsController.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
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
        SnackBar(
          content: Text("Error al guardar: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Editar Datos Personales"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Información del Estudiante",
                      style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Estos datos aparecerán en tus postulaciones.",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- CAMPO: NOMBRE ---
                    _buildNeonTextField(
                      controller: _nameController,
                      label: "Nombre",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: APELLIDO ---
                    _buildNeonTextField(
                      controller: _lastNameController,
                      label: "Apellido",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: CARNET ---
                    _buildNeonTextField(
                      controller: _carnetController,
                      label: "Carnet de Estudiante",
                      icon: Icons.badge_outlined,
                      keyboardType:
                          TextInputType.text, // Puede tener letras y números
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: CARRERA ---
                    _buildNeonTextField(
                      controller: _careerController,
                      label: "Carrera",
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 10),
                    const Text(
                      "Datos Académicos",
                      style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Esta información es visible para los coordinadores.",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- CAMPO: SEMESTRE ---
                    _buildNeonTextField(
                      controller: _semesterController,
                      label: "Semestre actual",
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      required: false,
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: ÍNDICE ACADÉMICO ---
                    _buildNeonTextField(
                      controller: _academicIndexController,
                      label: "Índice Académico (Ej: 15.5)",
                      icon: Icons.workspace_premium_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      required: false,
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: SOBRE MÍ ---
                    _buildNeonTextField(
                      controller: _aboutMeController,
                      label: "Sobre mí",
                      icon: Icons.info_outline_rounded,
                      maxLines: 3,
                      required: false,
                    ),
                    const SizedBox(height: 20),

                    // --- CAMPO: HABILIDADES ---
                    _buildNeonTextField(
                      controller: _skillsController,
                      label: "Habilidades (separadas por coma)",
                      icon: Icons.code_rounded,
                      hint: "Flutter, Python, Excel...",
                      required: false,
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          shadowColor: AppTheme.primaryOrange.withValues(
                            alpha: 0.5,
                          ),
                          elevation: 10,
                        ),
                        child: const Text(
                          "Guardar Cambios",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
    int maxLines = 1,
    String? hint,
    bool required = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.primaryOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppTheme.primaryOrange,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return "Este campo es obligatorio";
                }
                return null;
              }
            : null,
      ),
    );
  }
}
