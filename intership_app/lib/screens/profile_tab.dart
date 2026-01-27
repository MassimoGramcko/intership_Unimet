import 'package:flutter/material.dart';
import '../config/theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. CABECERA DE DATOS PERSONALES [cite: 191]
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryOrange,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            "Alejandro Martínez", // Nombre simulado
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Ingeniería de Producción", // Carrera simulada
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const Text(
            "Carnet: 202411100", // Carnet simulado
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),

          // 2. GESTOR DE DOCUMENTOS [cite: 192]
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Documentos Requeridos",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: AppTheme.secondaryBlue
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          // Advertencia visual (Regla de negocio: Sin CV no hay oferta) [cite: 195]
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryOrange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Debes subir tus documentos para poder postularte a las ofertas.",
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TARJETA 1: CURRICULUM (PDF) [cite: 193]
          _buildDocCard(
            title: "Curriculum Vitae (PDF)",
            subtitle: "No cargado",
            icon: Icons.picture_as_pdf,
            isUploaded: false,
            onTap: () {
              // Acción futura: Abrir selector de archivos
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Abrir selector de archivos PDF..."))
              );
            },
          ),

          // TARJETA 2: CONSTANCIA DE NOTAS [cite: 194]
          _buildDocCard(
            title: "Constancia de Notas",
            subtitle: "Archivo cargado: notas_2024.pdf",
            icon: Icons.assignment_outlined,
            isUploaded: true, // Simulamos que este ya lo subió
            onTap: () {},
          ),

          const SizedBox(height: 40),
          
          // BOTÓN CERRAR SESIÓN
          OutlinedButton.icon(
            onPressed: () {
               // Volver al Login
               Navigator.pushReplacementNamed(context, '/'); 
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          )
        ],
      ),
    );
  }

  // Widget auxiliar para las tarjetas de documentos
  Widget _buildDocCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUploaded ? Colors.green[50] : Colors.red[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon, 
            color: isUploaded ? Colors.green : Colors.red
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle, 
          style: TextStyle(
            color: isUploaded ? Colors.green[700] : Colors.red[700],
            fontSize: 12
          )
        ),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isUploaded ? Colors.grey[300] : AppTheme.secondaryBlue,
            foregroundColor: isUploaded ? Colors.black54 : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(isUploaded ? "Actualizar" : "Subir"),
        ),
      ),
    );
  }
}