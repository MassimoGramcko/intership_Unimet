import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../config/theme.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isUploading = false;
  final User? user = FirebaseAuth.instance.currentUser;

  // --- FUNCIÓN 1: SUBIR / REEMPLAZAR CV ---
  Future<void> _uploadCV() async {
    try {
      // 1. Abrir selector de archivos (Solo PDF)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() => _isUploading = true);

        PlatformFile file = result.files.first;
        final path = 'cvs/${user!.uid}/${file.name}';
        
        // 2. Subir a Firebase Storage
        final ref = FirebaseStorage.instance.ref().child(path);
        
        // Verificamos si es móvil (path) o web (bytes)
        UploadTask uploadTask;
        if (file.path != null) {
          uploadTask = ref.putFile(File(file.path!));
        } else {
           setState(() => _isUploading = false);
           return;
        }

        final snapshot = await uploadTask.whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();

        // 3. Guardar el link en Firestore
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'cvUrl': url,
          'cvName': file.name,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡CV actualizado con éxito! 🚀"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      print("Error subiendo CV: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- FUNCIÓN 2: ELIMINAR CV ---
  Future<void> _deleteCV() async {
    // 1. Preguntar confirmación
    bool? confirm = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("¿Eliminar CV?", style: TextStyle(color: Colors.white)),
        content: const Text("Tu hoja de vida se borrará de tu perfil.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isUploading = true);
      try {
        // 2. Borrar campos de Firestore (El archivo en Storage se puede quedar o borrar, aquí borramos la referencia)
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'cvUrl': FieldValue.delete(),
          'cvName': FieldValue.delete(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("CV eliminado"), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        // Error handling
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
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
          }

          if (!snapshot.hasData) return const Center(child: Text("No se encontraron datos"));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['firstName'] ?? 'Estudiante';
          final lastName = data['lastName'] ?? '';
          final career = data['career'] ?? 'Ingeniería';
          final email = data['email'] ?? user!.email;
          final String? cvName = data['cvName']; // Nombre del archivo si existe
          
          return Stack(
            children: [
              // --- FONDO AMBIENTAL (Glow Superior) ---
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
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
                child: Column(
                  children: [
                    // 1. AVATAR GLOW
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryOrange, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5
                            )
                          ],
                          image: DecorationImage(
                            // Generador de avatares con iniciales
                            image: NetworkImage("https://ui-avatars.com/api/?name=$name+$lastName&background=random&color=fff&size=128"), 
                          )
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text("$name $lastName", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(career, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16)),
                    
                    const SizedBox(height: 40),

                    // 2. SECCIÓN DEL CV (INTERACTIVA)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Curriculum Vitae", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 15),
                    
                    GestureDetector(
                      // Solo permite tocar el contenedor grande si NO hay CV. 
                      // Si hay CV, se usan los botones pequeños.
                      onTap: (cvName == null && !_isUploading) ? _uploadCV : null,
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: cvName != null 
                              ? const Color(0xFF1E293B) // Fondo sólido si hay CV
                              : Colors.transparent,     // Transparente si no hay
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: cvName != null ? AppTheme.primaryOrange : Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: _isUploading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
                          : cvName != null
                              ? _buildCvActiveState(cvName) // Muestra el archivo + Botones
                              : _buildCvEmptyState(),       // Muestra "Subir archivo"
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 3. DATOS ACADÉMICOS (Glass Cards)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Información Académica", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 15),
                    
                    _buildInfoTile(Icons.email_outlined, "Correo Institucional", email),
                    const SizedBox(height: 15),
                    _buildInfoTile(Icons.school_outlined, "Carrera", career),
                    const SizedBox(height: 15),
                    _buildInfoTile(Icons.badge_outlined, "Carnet", data['carnet'] ?? 'Sin asignar'),

                    const SizedBox(height: 40),
                    
                    // Botón Editar Info
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Próximamente: Editar Perfil")),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        child: const Text("Editar Información", style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // WIDGET: Estado cuando NO hay CV (Diseño de carga)
  Widget _buildCvEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, color: Colors.white.withValues(alpha: 0.5), size: 30),
        const SizedBox(height: 8),
        Text("Toca para subir tu CV (PDF)", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
      ],
    );
  }

  // WIDGET: Estado cuando SÍ hay CV (Con Botones de Acción)
  Widget _buildCvActiveState(String fileName) {
    return Row(
      children: [
        const SizedBox(width: 20),
        // Icono PDF Decorativo
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10)
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
        ),
        const SizedBox(width: 15),
        
        // Texto Nombre Archivo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text("Documento cargado", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
            ],
          ),
        ),

        // --- ACCIONES ---
        // 1. Reemplazar
        IconButton(
          onPressed: _uploadCV, 
          icon: const Icon(Icons.change_circle_outlined, color: Colors.blueAccent),
          tooltip: "Reemplazar archivo",
        ),
        
        // 2. Eliminar
        IconButton(
          onPressed: _deleteCV,
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          tooltip: "Eliminar archivo",
        ),
        
        const SizedBox(width: 10),
      ],
    );
  }

  // Widget Auxiliar para las tarjetas de información
  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }
}