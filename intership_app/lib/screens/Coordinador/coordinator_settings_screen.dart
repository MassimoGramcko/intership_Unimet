import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../auth/login_screen.dart';
import 'lista_usuarios_screen.dart'; // Importamos la lista de chats/estudiantes
import '../../services/chat_utils.dart';
import 'edit_coordinator_profile.dart';

class CoordinatorSettingsScreen extends StatefulWidget {
  const CoordinatorSettingsScreen({super.key});

  @override
  State<CoordinatorSettingsScreen> createState() =>
      _CoordinatorSettingsScreenState();
}

class _CoordinatorSettingsScreenState extends State<CoordinatorSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController =
      ScrollController(); // <-- NUEVO: Controlador para el Scrollbar
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN PARA ABRIR CHAT DE SOPORTE ---
  void _openSupportChat() async {
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // Para un coordinador, el soporte es un administrador del sistema
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isNotEmpty) {
        final adminDoc = querySnapshot.docs.first;
        final adminData = adminDoc.data();
        String adminName =
            "${adminData['firstName'] ?? ''} ${adminData['lastName'] ?? ''}"
                .trim();
        if (adminName.isEmpty) adminName = "Soporte Técnico";

        iniciarOabrirChat(
          context: context,
          currentUserId: user!.uid,
          otherUserId: adminDoc.id,
          otherUserName: adminName,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Soporte no disponible en este momento."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al conectar con soporte."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNCIÓN PARA CERRAR SESIÓN ---
  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Cerrar Sesión",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "¿Estás seguro de que deseas salir de tu cuenta de coordinador?",
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
            child: const Text(
              "Salir",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNCIÓN PARA MOSTRAR LEGALES ---
  void _showLegalSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
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
                  backgroundColor: AppTheme.primaryOrange.withValues(
                    alpha: 0.1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Entendido",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNCIÓN PARA CAMBIAR CONTRASEÑA ---
  Future<void> _resetPassword() async {
    if (user != null && user!.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Correo enviado! Revisa tu bandeja de entrada.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
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
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Perfil de Coordinación"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            );
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final String firstName = userData?['firstName'] ?? 'Coordinador';
          final String lastName = userData?['lastName'] ?? '';
          final String email =
              userData?['email'] ?? user?.email ?? 'Sin correo';

          return Stack(
            children: [
              Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(10),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- ENCABEZADO DE PERFIL ---
                      _buildProfileHeader(firstName, lastName, email),

                      const SizedBox(height: 35),

                      // --- SECCIÓN: PERSONALIZACIÓN ---
                      _buildSectionTitle("Personalización"),
                      const SizedBox(height: 15),
                      _buildSwitchTile(
                        title: "Notificaciones",
                        subtitle: "Recibir alertas de nuevas solicitudes",
                        icon: Icons.notifications_none_rounded,
                        value: _notificationsEnabled,
                        onChanged: (val) =>
                            setState(() => _notificationsEnabled = val),
                      ),

                      const SizedBox(height: 30),

                      // --- SECCIÓN: SEGURIDAD ---
                      _buildSectionTitle("Seguridad"),
                      const SizedBox(height: 15),
                      _AnimatedSettingsTile(
                        title: "Editar Perfil",
                        subtitle: "Cambia tu nombre y datos básicos",
                        icon: Icons.person_outline_rounded,
                        iconColor: Colors.blueAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EditCoordinatorProfileScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _AnimatedSettingsTile(
                        title: "Cambiar Contraseña",
                        subtitle: "Enlace de recuperación a tu correo",
                        icon: Icons.lock_reset_rounded,
                        iconColor: AppTheme.primaryOrange,
                        onTap: _resetPassword,
                      ),

                      const SizedBox(height: 30),

                      // --- SECCIÓN: LEGAL Y ASISTENCIA ---
                      _buildSectionTitle("Legal y Asistencia"),
                      const SizedBox(height: 15),
                      _AnimatedSettingsTile(
                        title: "Mensajes con Estudiantes",
                        subtitle: "Chats y consultas de alumnos",
                        icon: Icons.chat_bubble_rounded,
                        iconColor: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ListaUsuariosScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      _AnimatedSettingsTile(
                        title: "Términos y Condiciones",
                        subtitle: "Uso legal de la plataforma",
                        icon: Icons.description_outlined,
                        iconColor: Colors.amberAccent,
                        onTap: () => _showLegalSheet(
                          "Términos y Condiciones",
                          "Al usar esta plataforma de pasantías de la UNIMET, el personal se compromete a gestionar fielmente las solicitudes de los estudiantes. La institución actúa como mediador oficial entre las empresas y los estudiantes.",
                        ),
                      ),
                      const SizedBox(height: 15),
                      _AnimatedSettingsTile(
                        title: "Privacidad",
                        subtitle: "Tratamiento de datos personales",
                        icon: Icons.privacy_tip_outlined,
                        iconColor: Colors.greenAccent,
                        onTap: () => _showLegalSheet(
                          "Política de Privacidad",
                          "Toda la información académica y profesional gestionada en esta aplicación está protegida bajo los protocolos de la UNIMET. Solo el coordinador autorizado y el administrador tienen acceso a los datos sensibles.",
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- SECCIÓN: SESIÓN ---
                      _buildSectionTitle("Sesión"),
                      const SizedBox(height: 15),
                      _AnimatedSettingsTile(
                        title: "Cerrar Sesión",
                        subtitle: "Salir de tu panel de control",
                        icon: Icons.logout_rounded,
                        iconColor: Colors.redAccent,
                        isDestructive: true,
                        onTap: () => _logout(context),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildProfileHeader(String firstName, String lastName, String email) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryOrange.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.surfaceLight,
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : "C",
                style: const TextStyle(
                  fontSize: 40,
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "$firstName $lastName",
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Coordinador Académico",
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.primaryOrange,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.purpleAccent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryOrange,
          ),
        ],
      ),
    );
  }
}

class _AnimatedSettingsTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const _AnimatedSettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_AnimatedSettingsTile> createState() => _AnimatedSettingsTileState();
}

class _AnimatedSettingsTileState extends State<_AnimatedSettingsTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isPressed = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isPressed ? const Color(0xFFF1F5F9) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPressed
                  ? widget.iconColor.withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.05 : 0.02),
                blurRadius: _isPressed ? 15 : 10,
                offset: Offset(0, _isPressed ? 6 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.isDestructive
                            ? Colors.redAccent
                            : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _isPressed
                    ? AppTheme.textSecondary
                    : AppTheme.textSecondary.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
