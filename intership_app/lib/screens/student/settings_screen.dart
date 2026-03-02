import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import '../../services/chat_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController(); // <-- Controlador para el Scrollbar
  bool _isLoading = false;
  bool _pushNotifications = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- Lógica: Cargar configuración desde Firestore ---
  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _pushNotifications = data['settings_push'] ?? true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar configuración: $e");
    }
  }

  // --- Lógica: Guardar configuración en Firestore ---
  Future<void> _updateSetting(String field, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Actualizamos el estado local inmediatamente para fluidez
    setState(() {
      if (field == 'settings_push') _pushNotifications = value;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        field: value,
      });
    } catch (e) {
      if (mounted) {
        _showMessage("Error al guardar preferencia.", isError: true);
        // Revertimos en caso de error
        setState(() {
          if (field == 'settings_push') _pushNotifications = !value;
        });
      }
    }
  }

  // --- Lógica: Enviar correo de cambio de contraseña ---
  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          _showMessage(
            "Se ha enviado un enlace a ${user.email} para cambiar tu contraseña.",
            isError: false,
          );
        }
      } catch (e) {
        if (mounted) {
          _showMessage("Error al intentar enviar el correo.", isError: true);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- Lógica: Abrir Chat de Soporte ---
  void _openSupportChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['coordinador', 'coordinator'])
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isNotEmpty) {
        final coordDoc = querySnapshot.docs.first;
        final coordData = coordDoc.data();
        String coordName = "${coordData['firstName'] ?? ''} ${coordData['lastName'] ?? ''}".trim();
        if (coordName.isEmpty) coordName = "Coordinador";

        iniciarOabrirChat(
          context: context,
          currentUserId: user.uid,
          otherUserId: coordDoc.id,
          otherUserName: coordName,
        );
      } else {
        _showMessage("Soporte no disponible en este momento.", isError: true);
      }
    } catch (e) {
      _showMessage("Error al conectar con soporte.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Lógica: Mostrar Panel Legal ---
  void _showLegalSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Entendido", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Lógica: Cerrar Sesión ---
  void _logout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.white)),
        content: const Text("¿Estás seguro de que deseas salir de tu cuenta?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: const StadiumBorder(),
            ),
            child: const Text("Sí, Salir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Configuración", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(10),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24.0),
            children: [
              // SECCIÓN: PERSONALIZACIÓN
              _buildSectionTitle("Personalización"),
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                iconColor: Colors.purpleAccent,
                title: "Notificaciones Push",
                subtitle: "Alertas sobre nuevas ofertas de pasantías",
                value: _pushNotifications,
                onChanged: (val) => _updateSetting('settings_push', val),
              ),

              const SizedBox(height: 30),
              // SECCIÓN: SEGURIDAD
              _buildSectionTitle("Seguridad"),
              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                iconColor: Colors.orangeAccent,
                title: "Cambiar Contraseña",
                subtitle: "Te enviaremos un correo de recuperación",
                onTap: _resetPassword,
              ),

              const SizedBox(height: 30),
              // SECCIÓN: LEGAL Y SOPORTE
              _buildSectionTitle("Legal y Soporte"),
              _buildSettingsTile(
                icon: Icons.support_agent_rounded,
                iconColor: Colors.blueAccent,
                title: "Centro de Ayuda",
                subtitle: "Chatea con un coordinador",
                onTap: _openSupportChat,
              ),
              _buildSettingsTile(
                icon: Icons.description_outlined,
                iconColor: Colors.amberAccent,
                title: "Términos y Condiciones",
                subtitle: "Uso legal de la plataforma",
                onTap: () => _showLegalSheet(
                  "Términos y Condiciones",
                  "Al usar esta plataforma de pasantías de la UNIMET, el estudiante se compromete a proporcionar información veraz en su perfil y postulaciones. La institución actúa como mediador entre las empresas y los estudiantes para facilitar el proceso académico-profesional.",
                ),
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.greenAccent,
                title: "Política de Privacidad",
                subtitle: "Cómo protegemos tus datos",
                onTap: () => _showLegalSheet(
                  "Privacidad de Datos",
                  "Toda la información académica y profesional cargada en esta aplicación está protegida bajo los protocolos de la UNIMET. Solo las empresas a las que postules tendrán acceso a tu CV y datos de contacto para fines de selección.",
                ),
              ),

              const SizedBox(height: 30),
              // SECCIÓN: SESIÓN
              _buildSectionTitle("Sesión"),
              _buildSettingsTile(
                icon: Icons.logout_rounded,
                iconColor: Colors.redAccent,
                title: "Cerrar Sesión",
                subtitle: "Salir de tu cuenta en este dispositivo",
                isDestructive: true,
                onTap: _logout,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color itemColor = isDestructive ? Colors.redAccent : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: itemColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}
