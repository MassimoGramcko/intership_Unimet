import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart'; // Ajusta la ruta si es necesario
import '../auth/login_screen.dart'; // Ajusta la ruta a tu pantalla de Login

class CoordinatorSettingsScreen extends StatefulWidget {
  const CoordinatorSettingsScreen({super.key});

  @override
  State<CoordinatorSettingsScreen> createState() =>
      _CoordinatorSettingsScreenState();
}

class _CoordinatorSettingsScreenState extends State<CoordinatorSettingsScreen> {
  // --- FUNCIÓN PARA CERRAR SESIÓN ---
  void _logout(BuildContext context) async {
    // Cuadro de diálogo de confirmación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Cerrar Sesión",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "¿Estás seguro de que deseas salir?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Salir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNCIÓN PARA CAMBIAR CONTRASEÑA ---
  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '¡Correo enviado! Revisa tu bandeja de entrada para cambiar tu contraseña.',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar el correo: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Configuración",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cuenta y Seguridad",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // --- BOTÓN: CAMBIAR CONTRASEÑA ---
            _buildSettingsTile(
              title: "Cambiar Contraseña",
              subtitle: "Se enviará un enlace a tu correo",
              icon: Icons.lock_reset_rounded,
              iconColor: AppTheme.primaryOrange,
              onTap: _resetPassword,
            ),
            const SizedBox(height: 15),

            // --- BOTÓN: CERRAR SESIÓN ---
            _buildSettingsTile(
              title: "Cerrar Sesión",
              subtitle: "Salir de tu cuenta de coordinador",
              icon: Icons.logout_rounded,
              iconColor: Colors.redAccent,
              isDestructive: true,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET REUTILIZABLE PARA LAS OPCIONES ---
  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.redAccent : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white30,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
