import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';

class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({super.key});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final ScrollController _scrollController = ScrollController();
  final ScrollController _filtersScrollController =
      ScrollController(); // para los chips horizontales

  // --- COLORES PRE-COMPUTADOS ---
  static const Color _black20 = Color(0x33000000);

  final Map<String, dynamic> statusConfig = {
    'pending': {'color': Colors.blue, 'label': 'Enviado', 'step': 1},
    'reviewing': {'color': Colors.orange, 'label': 'En Revisión', 'step': 2},
    'accepted': {
      'color': const Color(0xFF22C55E),
      'label': 'Aceptado',
      'step': 3,
    },
    'rejected': {
      'color': const Color(0xFFEF4444),
      'label': 'No seleccionado',
      'step': 3,
    },
  };

  // --- STREAM CACHEADO ---
  late final Stream<QuerySnapshot>? _applicationsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _applicationsStream = FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: user.uid)
          .orderBy('appliedAt', descending: true)
          .snapshots();
    } else {
      _applicationsStream = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _filtersScrollController.dispose();
    super.dispose();
  }

  String _getStatusKey(String? rawStatus) {
    String status = (rawStatus ?? '').toLowerCase();

    if (status.contains('aceptado') ||
        status.contains('accepted') ||
        status.contains('aprobado')) {
      return 'accepted';
    } else if (status.contains('rechazado') || status.contains('rejected')) {
      return 'rejected';
    } else if (status.contains('revisión') || status.contains('reviewing')) {
      return 'reviewing';
    } else {
      return 'pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Mis Postulaciones"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. BARRA DE BÚSQUEDA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Buscar por cargo o empresa...",
                    hintStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            // 2. FILTROS (CHIPS) con scrollbar horizontal
            Container(
              height: 52,
              child: ListView(
                controller: _filtersScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                children: [
                  _buildInteractiveFilterChip("Todos", primaryColor),
                  const SizedBox(width: 8),
                  _buildInteractiveFilterChip(
                    "Pendiente",
                    primaryColor,
                    dbKey: "pending",
                  ),
                  const SizedBox(width: 8),
                  _buildInteractiveFilterChip(
                    "Aceptado",
                    primaryColor,
                    dbKey: "accepted",
                  ),
                  const SizedBox(width: 8),
                  _buildInteractiveFilterChip(
                    "Rechazado",
                    primaryColor,
                    dbKey: "rejected",
                  ),
                ],
              ),
            ),

            // 3. LISTA CON SCROLLBAR
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _applicationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  var docs = snapshot.data!.docs;

                  // Aplicar Filtro de Estado
                  if (_selectedFilter != 'Todos') {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _getStatusKey(data['status']) == _selectedFilter;
                    }).toList();
                  }

                  // Aplicar Filtro de Búsqueda
                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String jobTitle = (data['jobTitle'] ?? '')
                          .toString()
                          .toLowerCase();
                      final String company = (data['company'] ?? '')
                          .toString()
                          .toLowerCase();
                      return jobTitle.contains(_searchQuery) ||
                          company.contains(_searchQuery);
                    }).toList();
                  }

                  if (docs.isEmpty) return _buildEmptyState();

                  return Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(10),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _InteractiveApplicationCard(
                          data: data,
                          statusConfig: statusConfig,
                          getStatusKey: _getStatusKey,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveFilterChip(
    String label,
    Color activeColor, {
    String? dbKey,
  }) {
    final valueToSet = dbKey ?? 'Todos';
    final isSelected = _selectedFilter == valueToSet;

    return _AnimatedFilterChip(
      label: label,
      isSelected: isSelected,
      activeColor: activeColor,
      onTap: () => setState(() => _selectedFilter = valueToSet),
    );
  }

  Widget _buildProgressSegment({
    required bool isActive,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: isActive ? color : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(5) : Radius.zero,
            right: isLast ? const Radius.circular(5) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 15),
          Text(
            _searchQuery.isEmpty
                ? "No hay solicitudes aquí"
                : "No se encontraron coincidencias para '$_searchQuery'",
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- CLASES INTERACTIVAS (ANIMADAS) ---

class _AnimatedFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _AnimatedFilterChip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_AnimatedFilterChip> createState() => _AnimatedFilterChipState();
}

class _AnimatedFilterChipState extends State<_AnimatedFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.activeColor
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.isSelected
                  ? widget.activeColor
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              if (widget.isSelected)
                BoxShadow(
                  color: widget.activeColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isSelected
                    ? Colors.white
                    : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: widget.isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveApplicationCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> statusConfig;
  final String Function(String?) getStatusKey;

  const _InteractiveApplicationCard({
    required this.data,
    required this.statusConfig,
    required this.getStatusKey,
  });

  @override
  State<_InteractiveApplicationCard> createState() =>
      _InteractiveApplicationCardState();
}

class _InteractiveApplicationCardState
    extends State<_InteractiveApplicationCard>
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
    final statusKey = widget.getStatusKey(widget.data['status']);
    final config = widget.statusConfig[statusKey]!;
    final Color statusColor = config['color'];
    final String statusLabel = config['label'];
    final int currentStep = config['step'];

    String dateStr = "Reciente";
    if (widget.data['appliedAt'] != null) {
      try {
        DateTime date = (widget.data['appliedAt'] as Timestamp).toDate();
        dateStr = DateFormat('dd MMM, hh:mm a').format(date);
      } catch (e) {
        dateStr = "Fecha desconocida";
      }
    }

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _isPressed = false);
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isPressed = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _isPressed ? const Color(0xFFF1F5F9) : AppTheme.surfaceLight,
                statusColor.withValues(alpha: _isPressed ? 0.15 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? statusColor.withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.1 : 0.05),
                blurRadius: _isPressed ? 15 : 10,
                offset: Offset(0, _isPressed ? 8 : 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.business, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data['jobTitle'] ?? 'Puesto',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.data['company'] ?? 'Empresa',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Progreso:",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          _buildSegment(
                            isActive: currentStep >= 1,
                            color: statusColor,
                            isFirst: true,
                          ),
                          const SizedBox(width: 4),
                          _buildSegment(
                            isActive: currentStep >= 2,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          _buildSegment(
                            isActive: currentStep >= 3,
                            color: statusColor,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment({
    required bool isActive,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: isActive ? color : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(5) : Radius.zero,
            right: isLast ? const Radius.circular(5) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
