import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'student_detail_screen.dart'; // Importamos el perfil para poder navegar

class AdminStudentsTab extends StatelessWidget {
  const AdminStudentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Directorio de Estudiantes",
          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Quitamos la flecha de atrás porque es una pestaña principal
      ),
      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar por nombre, carnet o carrera...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          const SizedBox(height: 10),

          // 2. LISTA DE ESTUDIANTES
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStudentCard(
                  context,
                  name: "Alejandro Rodríguez",
                  major: "Ing. Sistemas",
                  initial: "A",
                  status: "Buscando",
                  statusColor: Colors.orange,
                ),
                _buildStudentCard(
                  context,
                  name: "Maria Rodríguez",
                  major: "Ing. Sistemas",
                  initial: "M",
                  status: "Pasantía Activa",
                  statusColor: Colors.green,
                ),
                _buildStudentCard(
                  context,
                  name: "Carlos Pérez",
                  major: "Economía Empresarial",
                  initial: "C",
                  status: "Docs. Pendientes",
                  statusColor: Colors.red,
                ),
                _buildStudentCard(
                  context,
                  name: "Ana García",
                  major: "Psicología",
                  initial: "A",
                  status: "Buscando",
                  statusColor: Colors.orange,
                ),
                _buildStudentCard(
                  context,
                  name: "Luis Torres",
                  major: "Ing. Civil",
                  initial: "L",
                  status: "Finalizada",
                  statusColor: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, {
    required String name,
    required String major,
    required String initial,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // AQUÍ CONECTAMOS CON EL PERFIL
          // Al tocar cualquier estudiante, vamos al perfil de ejemplo
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentDetailScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar con inicial
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                radius: 24,
                child: Text(
                  initial,
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              
              // Nombre y Carrera
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      major,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Chip de Estado (Buscando, Activa, etc.)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1), // Fondo suave
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}