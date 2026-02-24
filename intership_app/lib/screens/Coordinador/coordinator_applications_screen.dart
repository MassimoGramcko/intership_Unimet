import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';

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
  String _selectedFilter = 'Pendiente';

  // --- COLORES PRE-COMPUTADOS ---
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white24 = Color(0x3DFFFFFF);
  static const Color _white30 = Color(0x4DFFFFFF);
  static const Color _white50 = Color(0x80FFFFFF);
  static const Color _white60 = Color(0x99FFFFFF);

  // --- STREAM SE RECREA SOLO AL CAMBIAR FILTRO ---
  Stream<QuerySnapshot> _getStream() {
    return FirebaseFirestore.instance
        .collection('applications')
        .where('status', isEqualTo: _selectedFilter)
        .orderBy('appliedAt', descending: true)
        .snapshots();
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

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(docId)
          .update({'status': newStatus});

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
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterBtn('Pendientes', 'Pendiente', Colors.orange),
                _buildFilterBtn('Aceptados', 'Aceptado', Colors.green),
                _buildFilterBtn('Rechazados', 'Rechazado', Colors.redAccent),
              ],
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

                final apps = snapshot.data!.docs
                    .map((doc) => JobApplication.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: apps.length,
                  itemBuilder: (context, index) =>
                      _buildApplicationCard(apps[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String text, String value, Color color) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : _white24),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? color : _white60,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
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

          Row(
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
            ],
          ),

          const SizedBox(height: 20),

          if (app.status == 'Pendiente')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(app.id, 'Rechazado'),
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
                    onPressed: () => _updateStatus(app.id, 'Aceptado'),
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
            "No hay solicitudes en ${_selectedFilter.toLowerCase()}",
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
