import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controladores de texto básico
  final _nameController = TextEditingController(text: "Massimo Gramcko");
  final _majorController = TextEditingController(text: "Ingeniería de Sistemas");
  final _carnetController = TextEditingController(text: "20211120035");
  final _bioController = TextEditingController(text: "Estudiante apasionado por el desarrollo móvil y Flutter.");

  // --- LÓGICA PARA HABILIDADES (SKILLS) ---
  final _skillController = TextEditingController(); // Para escribir la nueva habilidad
  // Lista inicial de habilidades
  final List<String> _skills = ["Flutter", "Dart", "Inglés B2", "Git"]; 

  void _addSkill() {
    if (_skillController.text.isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text);
        _skillController.clear(); // Limpiar el campo después de agregar
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }
  // ----------------------------------------

  // --- LÓGICA PARA EL CV ---
  String _cvFileName = "CV_Massimo_2025.pdf"; // Nombre del archivo actual

  void _uploadCV() {
    // Aquí iría la lógica real para abrir el selector de archivos
    setState(() {
      _cvFileName = "Nuevo_CV_Actualizado.pdf"; // Simulamos que cambió
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("¡PDF cargado exitosamente!")),
    );
  }
  // -------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF003399),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FOTO DE PERFIL
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF003399),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // DATOS BÁSICOS
            const Text("Información Personal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            _buildTextField("Nombre Completo", _nameController, Icons.person_outline),
            const SizedBox(height: 15),
            _buildTextField("Carrera / Profesión", _majorController, Icons.school_outlined),
            const SizedBox(height: 15),
            _buildTextField("Carnet", _carnetController, Icons.badge_outlined),
            const SizedBox(height: 15),
            _buildTextField("Sobre mí (Bio)", _bioController, Icons.info_outline, maxLines: 3),
            
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // --- SECCIÓN DE HABILIDADES ---
            const Text("Mis Habilidades", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            
            // Campo para agregar nueva
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: InputDecoration(
                      hintText: "Ej. Excel, Python...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _addSkill,
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF003399)),
                  icon: const Icon(Icons.add, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 15),

            // Lista de Chips (Habilidades agregadas)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: Colors.blue[50],
                  deleteIcon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onDeleted: () => _removeSkill(skill), // Acción borrar
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // --- SECCIÓN DE CURRICULUM ---
            const Text("Hoja de Vida (CV)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_cvFileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Text("PDF - 2.5 MB", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _uploadCV,
                    child: const Text("Cambiar"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BOTÓN GUARDAR
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("¡Perfil actualizado correctamente! ✅"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003399),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("GUARDAR CAMBIOS", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
    );
  }
}