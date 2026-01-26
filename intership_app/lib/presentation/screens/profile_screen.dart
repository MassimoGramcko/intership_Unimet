import 'package:flutter/material.dart';
import 'package:intership_app/presentation/screens/edit_profile_screen.dart';
import 'package:intership_app/presentation/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (onBack != null) onBack!();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- CABECERA CON BOTÓN EDITAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF003399)),
                      tooltip: "Editar Perfil",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),

                // 1. FOTO Y DATOS BÁSICOS
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF003399),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Massimo Gramcko",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003399)),
                ),
                const Text(
                  "Ingeniería de Sistemas",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge_outlined, size: 18, color: Colors.grey),
                      SizedBox(width: 5),
                      Text(
                        "Carnet: 20211120035",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // 2. BIOGRAFÍA (BIO)
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Estudiante apasionado por el desarrollo móvil y Flutter. Buscando oportunidades para aprender y crecer profesionalmente.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 3. NUEVO: HABILIDADES (SKILLS)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Habilidades",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800]),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0, // Espacio horizontal entre chips
                  runSpacing: 8.0, // Espacio vertical entre líneas
                  children: [
                    _buildSkillChip("Flutter"),
                    _buildSkillChip("Dart"),
                    _buildSkillChip("Firebase"),
                    _buildSkillChip("Inglés B2"),
                    _buildSkillChip("Git / GitHub"),
                    _buildSkillChip("UI Design"),
                  ],
                ),

                const SizedBox(height: 25),

                // 4. NUEVO: CURRICULUM VITAE (CV)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Hoja de Vida",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800]),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf,
                          color: Colors.red, size: 30),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CV_Massimo_2025.pdf",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003399)),
                            ),
                            Text("Subido el 24 Ene 2025",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye,
                            color: Colors.grey),
                        onPressed: () {}, // Acción ver
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () {}, // Acción borrar
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 5. ESTADÍSTICAS RÁPIDAS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard("Postulaciones", "4"),
                    _buildStatCard("Vistas", "15"),
                  ],
                ),
                const SizedBox(height: 30),

                // 6. MIS POSTULACIONES
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Historial de Postulaciones",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800]),
                  ),
                ),
                const SizedBox(height: 15),

                _buildApplicationItem("Desarrollador Flutter Jr",
                    "Tech Solutions", "En revisión", Colors.orange),
                _buildApplicationItem(
                    "Analista de Datos", "Polar", "Visto", Colors.blue),
                _buildApplicationItem("Diseñador UI/UX", "StartUp Vzla",
                    "Rechazado", Colors.red),
                _buildApplicationItem("Asistente TI", "Banco Mercantil",
                    "Enviado", Colors.grey),

                const SizedBox(height: 30),

                // 7. BOTÓN CERRAR SESIÓN
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text("Cerrar Sesión",
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para los Chips de habilidades
  Widget _buildSkillChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Color(0xFF003399), fontSize: 12),
      ),
      backgroundColor: const Color(0xFFE3F2FD), // Azul muy clarito
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003399))),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildApplicationItem(
      String title, String company, String status, Color statusColor) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.business_center_outlined,
              color: Color(0xFF003399)),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(company),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
                color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}