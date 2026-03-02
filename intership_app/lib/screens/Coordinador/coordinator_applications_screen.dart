import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import 'student_profile_view.dart';

// --- MODELO AJUSTADO ---
class JobApplication {
  final String id;
  final String jobTitle;
  final String company;
  final String status;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String offerId;
  final Timestamp appliedAt;

  JobApplication({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.status,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.offerId,
    required this.appliedAt,
  });

  factory JobApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobApplication(
      id: doc.id,
      jobTitle: data['jobTitle'] ?? 'Puesto',
      company: data['company'] ?? 'Empresa',
      status: data['status'] ?? 'Pendiente',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Estudiante',
      studentEmail: data['studentEmail'] ?? 'Sin correo',
      offerId: data['offerId'] ?? '',
      appliedAt: data['appliedAt'] ?? Timestamp.now(),
    );
  }
}

class CoordinatorApplicationsScreen extends StatefulWidget {
  const CoordinatorApplicationsScreen({super.key});

  @override
  State<CoordinatorApplicationsScreen> createState() =>
      _CoordinatorApplicationsScreenState();
}

class _CoordinatorApplicationsScreenState
    extends State<CoordinatorApplicationsScreen> {
  String _selectedStatus = 'Todas';
  String _searchQuery = ''; // Variable para almacenar la búsqueda
  final TextEditingController _searchController = TextEditingController(); // Controlador del buscador
  final ScrollController _scrollController = ScrollController(); // <-- Controlador para la barra de desplazamiento

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- COLORES PRE-COMPUTADOS ---
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white24 = Color(0x3DFFFFFF);
  static const Color _white30 = Color(0x4DFFFFFF);
  static const Color _white50 = Color(0x80FFFFFF);
  static const Color _white60 = Color(0x99FFFFFF);

  // --- STREAM SE RECREA SOLO AL CAMBIAR FILTRO ---
  Stream<QuerySnapshot> _getStream() {
    final collection = FirebaseFirestore.instance.collection('applications');
    if (_selectedStatus == 'Todas') {
      return collection.orderBy('appliedAt', descending: true).snapshots();
    } else {
      return collection
          .where('status', isEqualTo: _selectedStatus)
          .orderBy('appliedAt', descending: true)
          .snapshots();
    }
  }

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

  Future<void> _updateStatus(JobApplication app, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(app.id)
          .update({'status': newStatus});

      // --- NUEVA LÓGICA: Notificación al Estudiante (HU-10) ---
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': app.studentId, // ID del estudiante
        'type': 'status_change',
        'title': 'Actualización de Postulación',
        'body': 'Tu estado en ${app.jobTitle} ha cambiado a $newStatus',
        'applicationId': app.id,
        'offerId': app.offerId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // --- FIN NUEVA LÓGICA ---

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Estado actualizado a: $newStatus"),
            backgroundColor: newStatus == 'Aceptado'
                ? Colors.green
                : Colors.redAccent,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Solicitudes",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todas', 'Todas'),
                    const SizedBox(width: 10),
                    _buildFilterChip('Pendientes', 'Pendiente'),
                    const SizedBox(width: 10),
                    _buildFilterChip('Aceptadas', 'Aceptado'),
                    const SizedBox(width: 10),
                    _buildFilterChip('Rechazadas', 'Rechazado'),
                  ],
                ),
              ),
            ),

            // --- BARRA DE BÚSQUEDA ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E202B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _white10),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Buscar por nombre u oferta...",
                    hintStyle: const TextStyle(color: _white50, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryOrange, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.close, color: _white50, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Filtrado por estado realizado por Firestore o localmente si es necesario
                var docs = snapshot.data!.docs;

                // Filtrado local por búsqueda
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final student = (data['studentName'] ?? '').toString().toLowerCase();
                    final job = (data['jobTitle'] ?? '').toString().toLowerCase();
                    return student.contains(_searchQuery) || job.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                final apps = docs
                    .map((doc) => JobApplication.fromFirestore(doc))
                    .toList();

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: apps.length,
                    itemBuilder: (context, index) =>
                        _buildApplicationCard(apps[index]),
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

  Widget _buildFilterChip(String text, String value) {
    final isSelected = _selectedStatus == value;
    final primaryColor = AppTheme.primaryOrange;
    
    return FilterChip(
      label: Text(text),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : _white60,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedStatus = value;
          });
        }
      },
      backgroundColor: Colors.transparent,
      selectedColor: primaryColor.withValues(alpha: 0.8),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? primaryColor : _white24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      showCheckmark: false, // Mantiene el diseño minimalista sin el checkmark por defecto
    );
  }

  Widget _buildApplicationCard(JobApplication app) {
    final cardColor = const Color(0xFF1E202B);
    final brandColor = Colors.blueAccent;

    String initials = _getInitials(app.studentName);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.work_outline, color: brandColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.jobTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.company,
                      style: const TextStyle(color: _white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(app.appliedAt.toDate()),
                style: const TextStyle(color: _white30, fontSize: 12),
              ),
            ],
          ),

          const Divider(color: _white10, height: 25),

        // --- ENLACE A STUDENT PROFILE (HU-21) ---
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentProfileView(studentId: app.studentId),
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      app.studentEmail,
                      style: const TextStyle(color: _white50, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: _white30, size: 14),
            ],
          ),
        ),
        // --- FIN ENLACE ---

        const SizedBox(height: 20),

          if (app.status == 'Pendiente')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(app, 'Rechazado'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Rechazar"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(app, 'Aceptado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Aprobar"),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: (app.status == 'Aceptado' ? Colors.green : Colors.red)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (app.status == 'Aceptado' ? Colors.green : Colors.red)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  app.status == 'Aceptado'
                      ? "Candidato Aprobado"
                      : "Candidato Rechazado",
                  style: TextStyle(
                    color: app.status == 'Aceptado'
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 60, color: _white10),
          const SizedBox(height: 15),
          Text(
            _selectedStatus == 'Todas'
                ? "No hay solicitudes"
                : "No hay solicitudes en estado ${_selectedStatus.toLowerCase()}",
            style: const TextStyle(color: _white50),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return "${diff.inDays}d";
    if (diff.inHours > 0) return "${diff.inHours}h";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "Ahora";
  }
}
