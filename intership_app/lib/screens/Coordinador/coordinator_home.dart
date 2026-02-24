import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../notifications_screen.dart';
import 'coordinator_applications_screen.dart';
import 'coordinator_settings_screen.dart';
import 'create_offer_screen.dart';
import 'lista_usuarios_screen.dart';
import 'manage_offers_screen.dart';

class CoordinatorHome extends StatefulWidget {
  const CoordinatorHome({super.key});

  @override
  State<CoordinatorHome> createState() => _CoordinatorHomeState();
}

class _CoordinatorHomeState extends State<CoordinatorHome>
    with SingleTickerProviderStateMixin {
  // Color principal naranja
  static const Color primaryOrange = Color(0xFFFF6B00);

  // --- COLORES PRE-COMPUTADOS (evita .withOpacity en cada build) ---
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _surfaceDark = Color(0xFF1E293B);
  static const Color _white05 = Color(0x0DFFFFFF); // 0.05
  static const Color _white08 = Color(0x14FFFFFF); // 0.08
  static const Color _white10 = Color(0x1AFFFFFF); // 0.10
  static const Color _white50 = Color(0x80FFFFFF); // 0.50
  static const Color _white60 = Color(0x99FFFFFF); // 0.60
  static const Color _white70 = Color(0xB3FFFFFF); // 0.70
  static const Color _black20 = Color(0x33000000);
  static const Color _black40 = Color(0x66000000);

  // Variable de estado para el filtro
  String _filtroStatus = 'Todos';

  // Variables para la animación del Speed Dial
  late AnimationController _animationController;
  bool _isDialOpen = false;

  // --- STREAMS CACHEADOS (se crean UNA sola vez) ---
  late final String? _currentUserId;
  late final Stream<QuerySnapshot>? _notificationsStream;
  late final Stream<QuerySnapshot> _applicationsKpiStream;
  late final Stream<QuerySnapshot> _offersKpiStream;
  late final Stream<QuerySnapshot> _activityStream;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Cachear el userId
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Cachear todos los streams de Firestore una sola vez
    if (_currentUserId != null) {
      _notificationsStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .snapshots();
    } else {
      _notificationsStream = null;
    }

    _applicationsKpiStream = FirebaseFirestore.instance
        .collection('applications')
        .snapshots();

    _offersKpiStream = FirebaseFirestore.instance
        .collection('job_offers')
        .snapshots();

    _activityStream = FirebaseFirestore.instance
        .collection('applications')
        .orderBy('appliedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Función para abrir/cerrar el menú
  void _toggleDial() {
    setState(() {
      _isDialOpen = !_isDialOpen;
      if (_isDialOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // --- FUNCIÓN: Obtener Iniciales ---
  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    List<String> nameParts = name.trim().split(RegExp(r'\s+'));
    if (nameParts.isEmpty) return "?";
    String initials = nameParts[0][0];
    if (nameParts.length > 1) {
      initials += nameParts.last[0];
    }
    return initials.toUpperCase();
  }

  // --- FUNCIÓN: Archivar historial antiguo (OPTIMIZADA con WriteBatch + filtro) ---
  void _clearOldActivity() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "¿Limpiar historial?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Se ocultarán de esta vista las solicitudes 'Aceptadas' o 'Rechazadas'.\n\nNo te preocupes, los datos y contadores de la oferta seguirán intactos.",
          style: TextStyle(color: _white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              "Sí, Limpiar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // OPTIMIZADO: Solo traer documentos que necesitan actualizarse
      var snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('isArchived', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int archivedCount = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data();
        var status = (data['status'] ?? '').toString().toLowerCase();

        if (status == 'aceptado' ||
            status == 'rechazado' ||
            status == 'accepted' ||
            status == 'rejected') {
          batch.update(doc.reference, {'isArchived': true});
          archivedCount++;
        }
      }

      if (archivedCount > 0) {
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Limpieza exitosa: Se ocultaron $archivedCount registros.",
            ),
            backgroundColor: Colors.greenAccent.shade700,
          ),
        );
      }
    }
  }

  // --- WIDGET: Botón de Notificaciones con Badge ---
  Widget _buildNotificationButton() {
    if (_notificationsStream == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs.length;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _white05,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _white10),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // CAPA 1: Fondo
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [_surfaceDark, _bgDark],
              ),
            ),
          ),

          // CAPA 2: Contenido - AHORA USA CustomScrollView con Slivers
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: _white60,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_currentUserId != null) ...[
                                  const SizedBox(width: 10),
                                  _buildNotificationButton(),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Hola, Coordinador 👋",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CoordinatorSettingsScreen(),
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
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 35)),

                // TARJETAS KPI
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _buildModernKpiCard(
                          title: "Solicitudes",
                          stream: _applicationsKpiStream,
                          countFilter: (docs) => docs
                              .where((doc) => doc['status'] == 'Pendiente')
                              .length,
                          icon: Icons.people_alt_rounded,
                          accentColor: Colors.orangeAccent,
                          gradientColors: [
                            primaryOrange.withValues(alpha: 0.8),
                            Colors.orange[800]!,
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CoordinatorApplicationsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 15),
                        _buildModernKpiCard(
                          title: "Ofertas Activas",
                          stream: _offersKpiStream,
                          countFilter: (docs) => docs
                              .where((doc) => doc['isActive'] == true)
                              .length,
                          icon: Icons.business_center_rounded,
                          accentColor: Colors.blueAccent,
                          gradientColors: [
                            Colors.blueAccent.withValues(alpha: 0.8),
                            Colors.blue[800]!,
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManageOffersScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 35)),

                // TÍTULO SECCIÓN + MENU DE FILTRO
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Actividad Reciente",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: _white70,
                          ),
                          color: _surfaceDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: _white10),
                          ),
                          onSelected: (String valor) {
                            if (valor == 'Limpiar Historial') {
                              _clearOldActivity();
                            } else {
                              setState(() {
                                _filtroStatus = valor;
                              });
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                _buildPopupItem(
                                  "Todos",
                                  Icons.dashboard_customize_outlined,
                                ),
                                const PopupMenuDivider(height: 1),
                                _buildPopupItem(
                                  "Pendiente",
                                  Icons.hourglass_empty_rounded,
                                  Colors.orangeAccent,
                                ),
                                _buildPopupItem(
                                  "Aceptado",
                                  Icons.check_circle_outline_rounded,
                                  Colors.greenAccent,
                                ),
                                _buildPopupItem(
                                  "Rechazado",
                                  Icons.cancel_outlined,
                                  Colors.redAccent,
                                ),
                                const PopupMenuDivider(height: 1),
                                _buildPopupItem(
                                  "Limpiar Historial",
                                  Icons.delete_sweep_rounded,
                                  Colors.orangeAccent,
                                ),
                              ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (_filtroStatus != 'Todos')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_alt_outlined,
                            size: 14,
                            color: _white50,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Filtrando por: ",
                            style: TextStyle(color: _white50, fontSize: 12),
                          ),
                          Text(
                            _filtroStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () =>
                                setState(() => _filtroStatus = 'Todos'),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 15)),

                // LISTA DE ACTIVIDAD - AHORA COMO SliverList (lazy loading real)
                StreamBuilder<QuerySnapshot>(
                  stream: _activityStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: primaryOrange,
                            ),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildModernEmptyState(
                            "No hay actividad reciente",
                          ),
                        ),
                      );
                    }

                    var docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isArchived = data['isArchived'] ?? false;
                      return !isArchived;
                    }).toList();

                    if (_filtroStatus != 'Todos') {
                      docs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = (data['status'] ?? '').toString();
                        return status.toLowerCase() ==
                            _filtroStatus.toLowerCase();
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildModernEmptyState(
                            "No hay actividad reciente para mostrar.",
                          ),
                        ),
                      );
                    }

                    final displayDocs = docs.take(20).toList();

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == displayDocs.length) {
                              return const SizedBox(
                                height: 80,
                              ); // Espacio final
                            }
                            final doc = displayDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final docId = doc.id;
                            return _buildModernReviewTile(data, docId);
                          },
                          childCount:
                              displayDocs.length +
                              1, // +1 para el espacio final
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          if (_isDialOpen)
            GestureDetector(
              onTap: _toggleDial,
              child: Container(color: _black40),
            ),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  // --- Widget del Speed Dial ---
  Widget _buildSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // BOTÓN 1: CHAT
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _white10),
                ),
                child: const Text(
                  "Mensajes",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              FloatingActionButton.small(
                heroTag: "chat_btn",
                backgroundColor: Colors.blueAccent,
                onPressed: () {
                  _toggleDial();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ListaUsuariosScreen(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // BOTÓN 2: CREAR OFERTA
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _white10),
                ),
                child: const Text(
                  "Crear Oferta",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              FloatingActionButton.small(
                heroTag: "offer_btn",
                backgroundColor: primaryOrange,
                onPressed: () {
                  _toggleDial();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateOfferScreen(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // BOTÓN PRINCIPAL
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryOrange.withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: "main_btn",
            backgroundColor: primaryOrange,
            elevation: 0,
            onPressed: _toggleDial,
            child: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.125).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Widgets Auxiliares ---
  PopupMenuItem<String> _buildPopupItem(
    String text,
    IconData icon, [
    Color? color,
  ]) {
    return PopupMenuItem<String>(
      value: text,
      child: Row(
        children: [
          Icon(icon, color: color ?? _white70, size: 18),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color ?? _white70)),
        ],
      ),
    );
  }

  Widget _buildModernKpiCard({
    required String title,
    required Stream<QuerySnapshot> stream,
    required int Function(List<QueryDocumentSnapshot>) countFilter,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          int count = 0;
          if (snapshot.hasData) {
            count = countFilter(snapshot.data!.docs);
          }

          return GestureDetector(
            onTap: onTap,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColors[0].withValues(alpha: 0.2),
                    gradientColors[1].withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: _white08),
                boxShadow: const [
                  BoxShadow(
                    color: _black20,
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      icon,
                      size: 100,
                      color: accentColor.withValues(alpha: 0.05),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: accentColor, size: 24),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$count",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: const TextStyle(
                                color: _white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernReviewTile(Map<String, dynamic> data, String docId) {
    String status = (data['status'] ?? 'Pendiente').toString().toLowerCase();
    String studentName = data['studentName'] ?? 'Estudiante';
    String initials = _getInitials(studentName);

    Color statusColor;
    String statusText;

    if (status == 'pendiente' || status == 'reviewing') {
      statusColor = Colors.orange;
      statusText = 'Pendiente';
    } else if (status == 'aceptado' || status == 'accepted') {
      statusColor = Colors.greenAccent;
      statusText = 'Aceptado';
    } else if (status == 'rechazado' || status == 'rejected') {
      statusColor = Colors.redAccent;
      statusText = 'Rechazado';
    } else {
      statusColor = Colors.blue;
      statusText = 'Nuevo';
    }

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Ocultar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.visibility_off_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "¿Ocultar actividad?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Esta acción quitará el registro de tu historial, pero mantendrá la postulación en la base de datos de la oferta.",
              style: TextStyle(color: _white70),
            ),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  "Sí, Ocultar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('applications')
                      .doc(docId)
                      .update({'isArchived': true});
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceDark.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _white05),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[400]!, Colors.purple[400]!],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.work_outline_rounded,
                        color: _white50,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          data['jobTitle'] ?? 'Puesto desconocido',
                          style: const TextStyle(color: _white50, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyState([
    String message = "No hay nuevas solicitudes pendientes.",
  ]) {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _white05),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.filter_list_off_rounded,
            size: 60,
            color: Color(0x33FFFFFF),
          ),
          const SizedBox(height: 20),
          const Text(
            "Sin resultados",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _white50),
          ),
        ],
      ),
    );
  }
}
