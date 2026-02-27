import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../config/theme.dart';
import 'edit_profile_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isUploading = false;
  final User? user = FirebaseAuth.instance.currentUser;

  // --- COLORES PRE-COMPUTADOS ---

  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white30 = Color(0x4DFFFFFF);
  static const Color _white50 = Color(0x80FFFFFF);
  static const Color _white60 = Color(0x99FFFFFF);
  static const Color _white80 = Color(0xCCFFFFFF);

  // --- STREAM CACHEADO ---
  late final Stream<DocumentSnapshot>? _userStream;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots();
    } else {
      _userStream = null;
    }
  }

  Future<void> _uploadCV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() => _isUploading = true);

        PlatformFile file = result.files.first;

        if (file.path == null) {
          throw "No se pudo acceder a la ruta del archivo. Intenta con otro.";
        }

        final path = 'cvs/${user!.uid}/${file.name}';
        final ref = FirebaseStorage.instance.ref().child(path);

        UploadTask uploadTask = ref.putFile(File(file.path!));

        final snapshot = await uploadTask.whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
              'cvUrl': url,
              'cvName': file.name,
              'lastUpdated': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡CV actualizado con éxito! 🚀"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteCV() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "¿Eliminar CV?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Tu hoja de vida se borrará de tu perfil y las empresas no podrán verla.",
          style: TextStyle(color: Color(0xB3FFFFFF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
              'cvUrl': FieldValue.delete(),
              'cvName': FieldValue.delete(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("CV eliminado correctamente"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al eliminar: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Error de sesión"));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("No se encontraron datos del usuario"),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['firstName'] ?? 'Estudiante';
          final lastName = data['lastName'] ?? '';
          final career = data['career'] ?? 'Ingeniería';
          final email = data['email'] ?? user!.email;
          final String? cvName = data['cvName'];

          return Stack(
            children: [
              // --- FONDO AMBIENTAL (Glow) ---
              Positioned(
                top: -150,
                left: -50,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.2),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 60,
                ),
                child: Column(
                  children: [
                    // 1. AVATAR GLOW
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryOrange,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryOrange.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(
                              "https://ui-avatars.com/api/?name=$name+$lastName&background=random&color=fff&size=128",
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "$name $lastName",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      career,
                      style: const TextStyle(color: _white60, fontSize: 16),
                    ),

                    const SizedBox(height: 40),

                    // 2. SECCIÓN DEL CV
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Curriculum Vitae",
                        style: TextStyle(
                          color: _white80,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: () {
                        if (_isUploading) return;
                        
                        // FEEDBACK VISUAL
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 15),
                                Text("Abriendo visor de documentos...", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            backgroundColor: AppTheme.primaryOrange,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );

                        // SIMULACRO: Espera y abre modal
                        Future.delayed(const Duration(seconds: 2), () {
                          if (!context.mounted) return;
                          _showCVMockup(context);
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: cvName != null
                              ? const Color(0xFF1E293B)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cvName != null
                                ? AppTheme.primaryOrange
                                : _white30,
                            width: 1,
                          ),
                        ),
                        child: _isUploading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryOrange,
                                ),
                              )
                            : cvName != null
                            ? _buildCvActiveState(cvName)
                            : _buildCvEmptyState(),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 3. DATOS ACADÉMICOS
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Información Académica",
                        style: TextStyle(
                          color: _white80,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    _buildInfoTile(
                      Icons.email_outlined,
                      "Correo Institucional",
                      email,
                    ),
                    const SizedBox(height: 15),
                    _buildInfoTile(Icons.school_outlined, "Carrera", career),
                    const SizedBox(height: 15),
                    _buildInfoTile(
                      Icons.badge_outlined,
                      "Carnet",
                      data['carnet'] ?? 'Sin asignar',
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Editar Perfil Completo",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          elevation: 10,
                          shadowColor: AppTheme.primaryOrange.withValues(
                            alpha: 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCvEmptyState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, color: _white50, size: 30),
        SizedBox(height: 8),
        Text(
          "Toca para subir tu CV (PDF)",
          style: TextStyle(color: _white50, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // --- SIMULACRO DE VISOR DE CV (HU-21) ---
  void _showCVMockup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CV_Estudiante.pdf",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "1.2 MB • PDF Document",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        "Visor en modo de evaluación académica",
                        style: TextStyle(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCvActiveState(String fileName) {
    return Row(
      children: [
        const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.picture_as_pdf,
            color: Colors.redAccent,
            size: 28,
          ),
        ),
        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Documento cargado",
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: () => _showCVMockup(context), // También ver el mockup al hacer clic en el nombre
          icon: const Icon(
            Icons.visibility_outlined,
            color: Colors.blueAccent,
          ),
          tooltip: "Ver simulación",
        ),

        IconButton(
          onPressed: _deleteCV,
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.redAccent,
          ),
          tooltip: "Eliminar archivo",
        ),

        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xB3FFFFFF), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: _white50, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
