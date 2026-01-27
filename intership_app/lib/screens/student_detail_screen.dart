import 'package:flutter/material.dart';
import '../config/theme.dart';

class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Perfil del Estudiante", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. FOTO Y NOMBRE
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage("https://i.pravatar.cc/300?img=33"), // Foto de ejemplo
                backgroundColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Alejandro Rodríguez",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
            ),
            const Text(
              "Estudiante de Ingeniería de Sistemas",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 2. DATOS ACADÉMICOS (Tarjetas)
            Row(
              children: [
                _buildStatCard("Índice", "16.5", Icons.school, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard("Semestre", "8vo", Icons.calendar_today, Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard("Créditos", "145", Icons.check_circle, Colors.green),
              ],
            ),
            const SizedBox(height: 30),

            // 3. SECCIÓN DE HABILIDADES
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Habilidades", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSkillChip("Python"),
                _buildSkillChip("Flutter"),
                _buildSkillChip("Inglés C1"),
                _buildSkillChip("Liderazgo"),
                _buildSkillChip("Scrum"),
              ],
            ),
            const SizedBox(height: 30),

            // 4. SOBRE MÍ
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Sobre mí", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ),
            const SizedBox(height: 8),
            Text(
              "Soy un estudiante apasionado por el desarrollo móvil y la inteligencia artificial. Busco una pasantía donde pueda aplicar mis conocimientos en Flutter y aprender sobre arquitecturas escalables.",
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
            
            const SizedBox(height: 40),

            // 5. BOTONES DE ACCIÓN (Descargar CV y Contactar)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Descargando CV..."))
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Ver CV"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppTheme.secondaryBlue,
                      side: const BorderSide(color: AppTheme.secondaryBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Abriendo correo..."))
                      );
                    },
                    icon: const Icon(Icons.email, color: Colors.white),
                    label: const Text("Contactar", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // WIDGET AUXILIAR PARA LAS TARJETAS DE MÉTRICAS
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // WIDGET AUXILIAR PARA LAS ETIQUETAS (CHIPS)
  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
      ),
    );
  }
}