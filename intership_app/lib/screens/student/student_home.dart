import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import 'profile_tab.dart';
import 'explore_tab.dart';
import 'applications_tab.dart';
import 'settings_screen.dart';
import 'package:intership_app/services/chat_utils.dart';
import '../notifications_screen.dart';
import '../Chat/ai_chatbot_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // --- COLORES PRE-COMPUTADOS ---
  static const Color _white05 = Color(0x0DFFFFFF);
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white08 = Color(0x14FFFFFF);
  static const Color _white50 = Color(0x80FFFFFF);
  static const Color _white60 = Color(0x99FFFFFF);
  static const Color _white90 = Color(0xE6FFFFFF);

  // --- STREAMS CACHEADOS ---
  late final User? _user;
  late final Stream<DocumentSnapshot>? _userDataStream;
  late final Stream<QuerySnapshot>? _notificationsStream;
  late final Stream<QuerySnapshot>? _applicationsStream;
  final ScrollController _scrollController =
      ScrollController(); // <-- NUEVO: Controlador para el Scrollbar

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      _userDataStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .snapshots();

      _notificationsStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots();

      _applicationsStream = FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: _user.uid)
          .snapshots();
    } else {
      _userDataStream = null;
      _notificationsStream = null;
      _applicationsStream = null;
    }
  }

  void _showApplicationSummary(
    BuildContext context,
    List<QueryDocumentSnapshot> docs,
  ) {
    int accepted = 0;
    int pending = 0;
    int rejected = 0;
    int reviewing = 0;

    for (var doc in docs) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']
              ?.toString()
              .toLowerCase() ??
          '';
      if (status.contains('aceptado') || status.contains('accepted')) {
        accepted++;
      } else if (status.contains('revisión') || status.contains('reviewing')) {
        reviewing++;
      } else if (status.contains('rechazado') || status.contains('rejected')) {
        rejected++;
      } else {
        pending++;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.35, // Altura reducida
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: _white10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Estado de tus Postulaciones",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Resumen rápido de tus postulaciones actuales.",
              style: TextStyle(color: _white60, fontSize: 14),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround, // Mejor distribución
              children: [
                _buildInsightItem("Aceptadas", accepted, Colors.greenAccent),
                _buildInsightItem(
                  "Pendientes",
                  pending + reviewing,
                  Colors.orangeAccent,
                ),
                _buildInsightItem("Rechazadas", rejected, Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            "$count",
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose(); // <-- IMPORTANTE: Liberar el controlador
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: _user == null
          ? const Center(
              child: Text(
                "No hay sesión activa",
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: _userDataStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return _buildDashboardUI(
                    context,
                    'Estudiante',
                    'Carrera no definida',
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final String firstName = userData['firstName'] ?? 'Estudiante';
                final String career = userData['career'] ?? 'UNIMET';

                return _buildDashboardUI(context, firstName, career);
              },
            ),
    );
  }

  Widget _buildDashboardUI(BuildContext context, String name, String career) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double halfCardWidth = (screenWidth - 70) / 2;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(10),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // --- HEADER CON EFECTO DE LUZ ---
            Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 100,
                          spreadRadius: 50,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                    top: 60, // Antes 70
                    left: 25,
                    right: 25,
                    bottom: 30, // Antes 40
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "¡Hola, $name!",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _white10,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  career.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsScreen(),
                                    ),
                                  );
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: _white05,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(
                                      BorderSide(color: _white10),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30), // Antes 40

                      Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _applicationsStream,
                              builder: (context, snapshot) {
                                String countStr = "0";
                                if (snapshot.hasData) {
                                  countStr = snapshot.data!.docs.length
                                      .toString();
                                }
                                return _InteractiveStatCard(
                                  value: countStr,
                                  label: "Postulaciones",
                                  icon: Icons.send_rounded,
                                  color: AppTheme.primaryOrange,
                                  onTap: () {
                                    if (snapshot.hasData &&
                                        snapshot.data!.docs.isNotEmpty) {
                                      _showApplicationSummary(
                                        context,
                                        snapshot.data!.docs,
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ApplicationsTab(),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Tarjeta 2: Notificaciones
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _notificationsStream,
                              builder: (context, snapshot) {
                                String countStr = "0";
                                if (snapshot.hasData) {
                                  countStr = snapshot.data!.docs.length
                                      .toString();
                                }
                                return _InteractiveStatCard(
                                  value: countStr,
                                  label: "Notificaciones",
                                  icon: Icons.notifications_active_rounded,
                                  color: Colors.blueAccent,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 15,
              ), // Antes all(25)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tu Próximo Paso",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18, // Antes 20
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12), // Antes 20

                  _InteractiveExploreCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExploreTab(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Accesos Rápidos",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _InteractiveActionCard(
                        width: halfCardWidth,
                        title: "Mis Solicitudes",
                        subtitle: "Ver estado",
                        icon: Icons.folder_open_rounded,
                        accentColor: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApplicationsTab(),
                            ),
                          );
                        },
                      ),
                      _InteractiveActionCard(
                        width: halfCardWidth,
                        title: "Mi Perfil y CV",
                        subtitle: "Editar datos",
                        icon: Icons.person_rounded,
                        accentColor: Colors.purpleAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileTab(),
                            ),
                          );
                        },
                      ),

                      // 🤖 UNIBOT - Asistente IA
                      _InteractiveActionCard(
                        width: double.infinity,
                        title: "UniBot IA ✨",
                        subtitle: "Asistente inteligente de pasantías",
                        icon: Icons.auto_awesome_rounded,
                        accentColor: const Color(0xFFFF6F00),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AiChatbotScreen(
                                userRole: 'student',
                                userName: name,
                              ),
                            ),
                          );
                        },
                      ),

                      _InteractiveActionCard(
                        width: double.infinity,
                        title: "Soporte Técnico",
                        subtitle: "Consultas directas y ayuda",
                        icon: Icons.support_agent_rounded,
                        accentColor: Colors.tealAccent.shade400,
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Conectando con soporte..."),
                            ),
                          );

                          try {
                            final querySnapshot = await FirebaseFirestore
                                .instance
                                .collection('users')
                                .where(
                                  'role',
                                  whereIn: ['coordinador', 'coordinator'],
                                )
                                .limit(1)
                                .get();

                            if (!context.mounted) return;

                            if (querySnapshot.docs.isNotEmpty) {
                              final coordDoc = querySnapshot.docs.first;
                              final coordData = coordDoc.data();

                              String coordName =
                                  "${coordData['firstName'] ?? ''} ${coordData['lastName'] ?? ''}"
                                      .trim();
                              if (coordName.isEmpty) coordName = "Coordinador";

                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();

                              iniciarOabrirChat(
                                context: context,
                                currentUserId: _user?.uid ?? '',
                                otherUserId: coordDoc.id,
                                otherUserName: coordName,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "No se encontró un coordinador activo.",
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CLASES INTERACTIVAS (ANIMADAS) ---

class _InteractiveStatCard extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _InteractiveStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_InteractiveStatCard> createState() => _InteractiveStatCardState();
}

class _InteractiveStatCardState extends State<_InteractiveStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
        setState(() => _isHovering = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _isHovering = false);
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isHovering = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _isHovering ? const Color(0xFF2D3748) : const Color(0xFF1E293B),
                widget.color.withValues(alpha: _isHovering ? 0.4 : 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovering
                  ? widget.color.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              if (_isHovering)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.label,
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveExploreCard extends StatefulWidget {
  final VoidCallback onTap;

  const _InteractiveExploreCard({required this.onTap});

  @override
  State<_InteractiveExploreCard> createState() =>
      _InteractiveExploreCardState();
}

class _InteractiveExploreCardState extends State<_InteractiveExploreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

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
        setState(() => _isHovering = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _isHovering = false);
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isHovering = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _isHovering
                    ? AppTheme.primaryOrange
                    : AppTheme.primaryOrange.withValues(alpha: 0.9),
                _isHovering
                    ? AppTheme.primaryOrange.withValues(alpha: 0.8)
                    : AppTheme.primaryOrange.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withValues(
                  alpha: _isHovering ? 0.4 : 0.3,
                ),
                blurRadius: _isHovering ? 30 : 20,
                offset: Offset(0, _isHovering ? 15 : 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(height: 15),
              const Text(
                "Explorar Ofertas",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Encuentra la pasantía ideal para tu carrera hoy mismo.",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Buscar Ahora",
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final double? width;

  const _InteractiveActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.width,
  });

  @override
  State<_InteractiveActionCard> createState() => _InteractiveActionCardState();
}

class _InteractiveActionCardState extends State<_InteractiveActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
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
        setState(() => _isHovering = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _isHovering = false);
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isHovering = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          height: 160,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _isHovering ? const Color(0xFF2D3748) : const Color(0xFF1E293B),
                widget.accentColor.withValues(alpha: _isHovering ? 0.3 : 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _isHovering
                  ? widget.accentColor.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              if (_isHovering)
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 26),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0x4DFFFFFF),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
