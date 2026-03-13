import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';

class EditCoordinatorProfileScreen extends StatefulWidget {
  const EditCoordinatorProfileScreen({super.key});

  @override
  State<EditCoordinatorProfileScreen> createState() =>
      _EditCoordinatorProfileScreenState();
}

class _EditCoordinatorProfileScreenState
    extends State<EditCoordinatorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _aboutController = TextEditingController();

  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;

  // --- COLORES ---
  static const Color _bgDark = AppTheme.backgroundLight;
  static const Color _surfaceDark = AppTheme.surfaceLight;
  static const Color _white10 = Color(0xFFE2E8F0);
  static const Color _white40 = AppTheme.textSecondary;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

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
          _phoneController.text = data['phone'] ?? '';
          _departmentController.text = data['department'] ?? '';
          _aboutController.text = data['about'] ?? '';
          _email = data['email'] ?? user.email ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _email = user.email ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'firstName': _nameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'department': _departmentController.text.trim(),
            'about': _aboutController.text.trim(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Perfil actualizado con éxito! ✅"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getInitials() {
    final first = _nameController.text.trim();
    final last = _lastNameController.text.trim();
    final fi = first.isNotEmpty ? first[0].toUpperCase() : '';
    final li = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$fi$li'.isEmpty ? '?' : '$fi$li';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: const Text("Editar Perfil"),
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
                    // ── AVATAR CON INICIALES ──────────────────────────────
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryOrange.withValues(alpha: 0.8),
                                  AppTheme.primaryOrange.withValues(alpha: 0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppTheme.primaryOrange.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryOrange.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange,
                                shape: BoxShape.circle,
                                border: Border.all(color: _bgDark, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Email (solo lectura)
                    Center(
                      child: Text(
                        _email,
                        style: const TextStyle(color: _white40, fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // ── SECCIÓN: DATOS PERSONALES ─────────────────────────
                    _buildSectionTitle(
                      Icons.person_outline,
                      "Datos Personales",
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _nameController,
                      label: "Nombre(s)",
                      icon: Icons.badge_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _lastNameController,
                      label: "Apellido(s)",
                      icon: Icons.badge_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _phoneController,
                      label: "Teléfono",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isRequired: false,
                    ),

                    const SizedBox(height: 30),

                    // ── SECCIÓN: DATOS INSTITUCIONALES ───────────────────
                    _buildSectionTitle(
                      Icons.school_outlined,
                      "Datos Institucionales",
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _departmentController,
                      label: "Departamento / Cargo",
                      icon: Icons.workspaces_outlined,
                      hint: "Ej: Coordinación de Pasantías",
                      isRequired: false,
                    ),

                    const SizedBox(height: 30),

                    // ── SECCIÓN: ACERCA DE MÍ ─────────────────────────────
                    _buildSectionTitle(Icons.info_outline, "Acerca de mí"),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _aboutController,
                      label: "Descripción",
                      icon: Icons.edit_note_outlined,
                      hint: "Breve descripción de tu rol y experiencia...",
                      maxLines: 4,
                      isRequired: false,
                    ),

                    const SizedBox(height: 40),

                    // ── BOTÓN GUARDAR ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          disabledBackgroundColor: AppTheme.primaryOrange
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 10,
                          shadowColor: AppTheme.primaryOrange.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.save_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Guardar Cambios",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryOrange, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primaryOrange,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: AppTheme.primaryOrange.withValues(alpha: 0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.textPrimary),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: _white40, fontSize: 13),
          labelStyle: const TextStyle(color: _white40),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: AppTheme.primaryOrange, size: 20)
              : Padding(
                  padding: const EdgeInsets.only(left: 12, top: 12),
                  child: Icon(icon, color: AppTheme.primaryOrange, size: 20),
                ),
          alignLabelWithHint: maxLines > 1,
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
          contentPadding: EdgeInsets.symmetric(
            vertical: maxLines > 1 ? 16 : 0,
            horizontal: maxLines > 1 ? 16 : 0,
          ),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Este campo es obligatorio";
                }
                return null;
              }
            : null,
      ),
    );
  }
}
