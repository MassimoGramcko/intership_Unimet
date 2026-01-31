import 'package:flutter/material.dart';
import '../../config/theme.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. FOTO Y NOMBRE DEL COORDINADOR
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.secondaryBlue,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              "Coordinación Académica",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryBlue,
              ),
            ),
            Text(
              "admin.pasantias@unimet.edu.ve",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // 2. OPCIONES DE GESTIÓN
            _buildProfileOption(
              icon: Icons.notifications_outlined, 
              text: "Notificaciones de Validaciones",
              subtitle: "Activas"
            ),
            _buildProfileOption(
              icon: Icons.settings_outlined, 
              text: "Configuración del Sistema",
            ),
            _buildProfileOption(
              icon: Icons.help_outline, 
              text: "Soporte Técnico",
            ),

            const SizedBox(height: 40),

            // 3. BOTÓN DE CERRAR SESIÓN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Volver a la pantalla de Login
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "CERRAR SESIÓN",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String text, String? subtitle}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.secondaryBlue),
      ),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.green)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {},
    );
  }
}