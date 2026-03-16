import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import 'student_profile_view.dart';

// --- COLORES PRE-COMPUTADOS ---
const Color _bgDark = AppTheme.backgroundLight;
const Color _white10 = Color(0xFFE2E8F0);
const Color _white50 = AppTheme.textSecondary;

class AdminOfferCandidatesScreen extends StatefulWidget {
  final String offerId;
  final String offerTitle;

  const AdminOfferCandidatesScreen({
    super.key,
    required this.offerId,
    required this.offerTitle,
  });

  @override
  State<AdminOfferCandidatesScreen> createState() =>
      _AdminOfferCandidatesScreenState();
}

class _AdminOfferCandidatesScreenState
    extends State<AdminOfferCandidatesScreen> {
  Stream<QuerySnapshot> _getFilteredStream() {
    return FirebaseFirestore.instance
        .collection('applications')
        .where('offerId', isEqualTo: widget.offerId)
        .snapshots();
  }

  void _updateStatus(String applicationId, String newStatus) {
    FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: const Text("Candidatos"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: _bgDark),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                child: Text(
                  widget.offerTitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Expanded(
                child: StreamBuilder(
                  stream: _getFilteredStream(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.orangeAccent,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var application = snapshot.data!.docs[index];
                        var appData =
                            application.data() as Map<String, dynamic>;
                        return _CandidateCard(
                          appId: application.id,
                          appData: appData,
                          onUpdate: _updateStatus,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
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
          Icon(Icons.people_outline_rounded, size: 80, color: _white10),
          const SizedBox(height: 15),
          const Text(
            "Aún no hay postulantes",
            style: TextStyle(
              color: _white50,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final String appId;
  final Map<String, dynamic> appData;
  final Function(String, String) onUpdate;

  const _CandidateCard({
    required this.appId,
    required this.appData,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    String studentId = appData['studentId'];
    String status = appData['status'] ?? 'En revisión';
    bool isProcessed = status == 'Aceptado' || status == 'Rechazado';

    Color statusColor = Colors.orangeAccent;
    if (status == 'Aceptado') statusColor = Colors.greenAccent;
    if (status == 'Rechazado') statusColor = Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentProfileView(studentId: studentId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(studentId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(
                      child: LinearProgressIndicator(minHeight: 2),
                    );

                  var userData = snapshot.data?.data() as Map<String, dynamic>?;

                  // Intentamos obtener el nombre completo del documento de usuario
                  String? firstName = userData?['firstName'];
                  String? lastName = userData?['lastName'];

                  // Fallback al nombre que ya trae la postulación si el documento de usuario falla
                  String name = "Estudiante";
                  if (firstName != null || lastName != null) {
                    name = "${firstName ?? ''} ${lastName ?? ''}".trim();
                  } else if (appData['studentName'] != null) {
                    name = appData['studentName'];
                  }

                  String email =
                      userData?['email'] ??
                      appData['studentEmail'] ??
                      "Sin correo";

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: isProcessed ? 20 : 25,
                          backgroundColor: Colors.blueAccent.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: isProcessed ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: isProcessed ? 16 : 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isProcessed) ...[
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 15),

              if (!isProcessed)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onUpdate(appId, 'Rechazado'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Rechazar",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onUpdate(appId, 'Aceptado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.withValues(
                            alpha: 0.15,
                          ),
                          foregroundColor: Colors.greenAccent,
                          elevation: 0,
                          side: const BorderSide(
                            color: Colors.greenAccent,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Aceptar",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => onUpdate(appId, 'En revisión'),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      "Cambiar estado",
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
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
