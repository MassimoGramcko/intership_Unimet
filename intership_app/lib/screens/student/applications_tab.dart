import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({super.key});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  String _selectedFilter = 'Todos';

  // --- COLORES PRE-COMPUTADOS ---
  static const Color _white05 = Color(0x0DFFFFFF);
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white20 = Color(0x33FFFFFF);
  static const Color _white40 = Color(0x66FFFFFF);
  static const Color _white50 = Color(0x80FFFFFF);
  static const Color _white60 = Color(0x99FFFFFF);
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
    final Color primaryColor = const Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
          "Mis Postulaciones",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildFilterChip("Todos", primaryColor),
                const SizedBox(width: 10),
                _buildFilterChip("Pendiente", primaryColor, dbKey: "pending"),
                const SizedBox(width: 10),
                _buildFilterChip("Aceptado", primaryColor, dbKey: "accepted"),
                const SizedBox(width: 10),
                _buildFilterChip("Rechazado", primaryColor, dbKey: "rejected"),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _applicationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                var docs = snapshot.data!.docs;

                if (_selectedFilter != 'Todos') {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _getStatusKey(data['status']) == _selectedFilter;
                  }).toList();
                }

                if (docs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildApplicationCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Color activeColor, {String? dbKey}) {
    final valueToSet = dbKey ?? 'Todos';
    final isSelected = _selectedFilter == valueToSet;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = valueToSet),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : _white05,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? activeColor : _white10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> data) {
    final statusKey = _getStatusKey(data['status']);

    final config = statusConfig[statusKey]!;
    final Color statusColor = config['color'];
    final String statusLabel = config['label'];
    final int currentStep = config['step'];

    String dateStr = "Reciente";
    if (data['appliedAt'] != null) {
      try {
        DateTime date = (data['appliedAt'] as Timestamp).toDate();
        dateStr = DateFormat('dd MMM, hh:mm a').format(date);
      } catch (e) {
        dateStr = "Fecha desconocida";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _white05),
        boxShadow: const [
          BoxShadow(color: _black20, blurRadius: 10, offset: Offset(0, 5)),
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
                        data['jobTitle'] ?? 'Puesto',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['company'] ?? 'Empresa',
                        style: const TextStyle(color: _white60, fontSize: 13),
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

          const Divider(color: _white05, height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progreso:",
                      style: TextStyle(color: _white40, fontSize: 11),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(color: _white40, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      _buildProgressSegment(
                        isActive: currentStep >= 1,
                        color: statusColor,
                        isFirst: true,
                      ),
                      const SizedBox(width: 4),
                      _buildProgressSegment(
                        isActive: currentStep >= 2,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      _buildProgressSegment(
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
          color: isActive ? color : _white10,
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
          Icon(Icons.folder_off_outlined, size: 80, color: _white20),
          const SizedBox(height: 15),
          Text("No hay solicitudes aquí", style: TextStyle(color: _white50)),
        ],
      ),
    );
  }
}
