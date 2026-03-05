import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../Chat/ai_chatbot_screen.dart';
import '../notifications_screen.dart';
import 'coordinator_applications_screen.dart';
import 'coordinator_settings_screen.dart';
import 'create_offer_screen.dart';
import 'lista_usuarios_screen.dart';
import 'manage_offers_screen.dart';
import 'student_profile_view.dart';

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

  // --- VARIABLES DE CONTROL ---
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // <-- Controlador para el Scrollbar
  String _searchQuery = '';

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

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

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
    _searchController.dispose();
    _scrollController.dispose(); // <-- Liberamos el controlador
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
      // OPTIMIZADO: Consultar todas para evitar omitir documentos que no tengan el campo isArchived
      var snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int archivedCount = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data();
        bool isArchived = data['isArchived'] ?? false;

        // Solo archivar si no está archivado previamente
        if (!isArchived) {
          var status = (data['status'] ?? '').toString().toLowerCase();

          if (status == 'aceptado' ||
              status == 'rechazado' ||
              status == 'accepted' ||
              status == 'rejected') {
            batch.update(doc.reference, {'isArchived': true});
            archivedCount++;
          }
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

          // CAPA 2: Contenido - AHORA CON SCROLLBAR
          SafeArea(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 6,
              radius: const Radius.circular(10),
              child: CustomScrollView(
                controller: _scrollController,
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
                                ],
                              ),
                              const SizedBox(height: 5),
                              const SizedBox(height: 5),
                              StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_currentUserId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  // Saludo simplificado para evitar overflow
                                  return const Text(
                                    "Hola, Coordinador 👋",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
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

                  // TARJETAS KPI (Primera fila: 2 columnas)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _InteractiveKpiCard(
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
                          _InteractiveKpiCard(
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

                  const SliverToBoxAdapter(child: SizedBox(height: 15)),

                  // TARJETA KPI (Segunda fila: 1 columna completa para Notificaciones)
                  if (_notificationsStream != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            _InteractiveKpiCard(
                              title: "Notificaciones Pendientes",
                              stream: _notificationsStream!,
                              countFilter: (docs) => docs.length,
                              icon: Icons.notifications_active_rounded,
                              accentColor: Colors.purpleAccent,
                              gradientColors: [
                                Colors.purpleAccent.withValues(alpha: 0.8),
                                Colors.purple[800]!,
                              ],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationsScreen(),
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
                            const Text(
                              "Filtrando por: ",
                              style: TextStyle(color: _white50, fontSize: 12),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (_filtroStatus == 'Pendiente'
                                            ? Colors.orangeAccent
                                            : _filtroStatus == 'Aceptado'
                                            ? Colors.greenAccent
                                            : Colors.redAccent)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      (_filtroStatus == 'Pendiente'
                                              ? Colors.orangeAccent
                                              : _filtroStatus == 'Aceptado'
                                              ? Colors.greenAccent
                                              : Colors.redAccent)
                                          .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _filtroStatus == 'Pendiente'
                                        ? Icons.hourglass_empty_rounded
                                        : _filtroStatus == 'Aceptado'
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.cancel_outlined,
                                    size: 14,
                                    color: _filtroStatus == 'Pendiente'
                                        ? Colors.orangeAccent
                                        : _filtroStatus == 'Aceptado'
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _filtroStatus,
                                    style: TextStyle(
                                      color: _filtroStatus == 'Pendiente'
                                          ? Colors.orangeAccent
                                          : _filtroStatus == 'Aceptado'
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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

                  // BARRA DE BÚSQUEDA
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        height: 45,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "Buscar estudiante u oferta...",
                            hintStyle: const TextStyle(
                              color: _white50,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: _white50,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: _white50,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: _white05,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: _white10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: _white10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                        ),
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

                      if (_searchQuery.isNotEmpty) {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final studentName = (data['studentName'] ?? '')
                              .toString()
                              .toLowerCase();
                          final jobTitle = (data['jobTitle'] ?? '')
                              .toString()
                              .toLowerCase();
                          return studentName.contains(_searchQuery) ||
                              jobTitle.contains(_searchQuery);
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
        // BOTÓN 0: UNIBOT IA
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
          child: _InteractiveDialButton(
            label: "UniBot IA ✨",
            icon: Icons.auto_awesome_rounded,
            backgroundColor: const Color(0xFF7B2FBE),
            onTap: () {
              _toggleDial();
              // Obtener nombre del coordinador actual
              final user = FirebaseAuth.instance.currentUser;
              String coordName = user?.displayName ?? 'Coordinador';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiChatbotScreen(
                    userRole: 'coordinator',
                    userName: coordName,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 15),

        // BOTÓN 1: CHAT
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
          child: _InteractiveDialButton(
            label: "Mensajes",
            icon: Icons.chat_bubble_rounded,
            backgroundColor: Colors.blueAccent,
            onTap: () {
              _toggleDial();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListaUsuariosScreen()),
              );
            },
          ),
        ),

        const SizedBox(height: 15),

        // BOTÓN 2: CREAR OFERTA
        ScaleTransition(
          scale: CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
          child: _InteractiveDialButton(
            label: "Crear Oferta",
            icon: Icons.add_business_rounded,
            backgroundColor: primaryOrange,
            onTap: () {
              _toggleDial();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateOfferScreen()),
              );
            },
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

  void _showOptionsBottomSheet(Map<String, dynamic> data, String docId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Opciones de Solicitud",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.blueAccent,
                    ),
                  ),
                  title: const Text(
                    "Ver información del estudiante",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (data['studentId'] != null &&
                        data['studentId'].toString().isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentProfileView(studentId: data['studentId']),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No se encontró el ID del estudiante"),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  title: const Text(
                    "Gestionar solicitud",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    "Ir al apartado de aceptar/rechazar",
                    style: TextStyle(color: _white50, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CoordinatorApplicationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showOptionsBottomSheet(data, docId),
          child: Container(
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
                              style: const TextStyle(
                                color: _white50,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
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

class _InteractiveKpiCard extends StatefulWidget {
  final String title;
  final Stream<QuerySnapshot> stream;
  final int Function(List<QueryDocumentSnapshot>) countFilter;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _InteractiveKpiCard({
    required this.title,
    required this.stream,
    required this.countFilter,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    this.onTap,
  });

  @override
  State<_InteractiveKpiCard> createState() => _InteractiveKpiCardState();
}

class _InteractiveKpiCardState extends State<_InteractiveKpiCard>
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
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: widget.stream,
        builder: (context, snapshot) {
          int count = 0;
          if (snapshot.hasData) {
            count = widget.countFilter(snapshot.data!.docs);
          }

          return GestureDetector(
            onTapDown: (_) {
              _controller.forward();
              setState(() => _isHovering = true);
            },
            onTapUp: (_) {
              _controller.reverse();
              setState(() => _isHovering = false);
              if (widget.onTap != null) widget.onTap!();
            },
            onTapCancel: () {
              _controller.reverse();
              setState(() => _isHovering = false);
            },
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.gradientColors[0].withValues(
                        alpha: _isHovering ? 0.4 : 0.2,
                      ),
                      widget.gradientColors[1].withValues(
                        alpha: _isHovering ? 0.3 : 0.1,
                      ),
                    ],
                  ),
                  border: Border.all(
                    color: _isHovering
                        ? widget.accentColor.withValues(alpha: 0.5)
                        : const Color(0x14FFFFFF),
                    width: _isHovering ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isHovering ? 0.4 : 0.2,
                      ),
                      blurRadius: _isHovering ? 20 : 15,
                      offset: Offset(0, _isHovering ? 12 : 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        widget.icon,
                        size: 100,
                        color: widget.accentColor.withValues(
                          alpha: _isHovering ? 0.1 : 0.05,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(
                                alpha: _isHovering ? 0.4 : 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isHovering
                                  ? [
                                      BoxShadow(
                                        color: widget.accentColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.accentColor,
                              size: 24,
                            ),
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
                                widget.title,
                                style: const TextStyle(
                                  color: Color(0xB3FFFFFF),
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
            ),
          );
        },
      ),
    );
  }
}

class _InteractiveDialButton extends StatefulWidget {
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  final String label;

  const _InteractiveDialButton({
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    required this.label,
  });

  @override
  State<_InteractiveDialButton> createState() => _InteractiveDialButtonState();
}

class _InteractiveDialButtonState extends State<_InteractiveDialButton>
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
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Etiqueta
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Botón con icono
        GestureDetector(
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isHovering
                    ? widget.backgroundColor.withValues(alpha: 0.8)
                    : widget.backgroundColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.4),
                    blurRadius: _isHovering ? 15 : 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}
