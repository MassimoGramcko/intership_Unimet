import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';

class StudentProfileView extends StatelessWidget {
  final String studentId;

  const StudentProfileView({super.key, required this.studentId});

  // --- FUNCIÓN CENTRAL (CRITERIO DE ACEPTACIÓN) ---
  String _getValidString(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return "Dato no registrado";
    }
    return value.toString().trim();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Perfil del Candidato"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Error al cargar el perfil del estudiante.",
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Variables parseadas con validación estricta "Dato no registrado"
          final rawFirstName = data['firstName'] ?? '';
          final rawLastName = data['lastName'] ?? '';
          final fullName = "$rawFirstName $rawLastName".trim();

          final displayFullName = fullName.isEmpty
              ? "Dato no registrado"
              : fullName;
          final displayEmail = _getValidString(data['email']);
          final displayCareer = _getValidString(data['career']);
          final displaySemester = _getValidString(data['semester']);
          final displayIndex = _getValidString(data['academicIndex']);
          final displayAbout = _getValidString(data['aboutMe']);

          final skillsRaw = data['skills'];
          List<String> displaySkills = [];
          if (skillsRaw is List) {
            displaySkills = skillsRaw.map((e) => e.toString()).toList();
          } else if (skillsRaw is String && skillsRaw.isNotEmpty) {
            displaySkills = skillsRaw.split(',').map((e) => e.trim()).toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- CABECERA ---
                Container(
                  width: 100,
                  height: 100,
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
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    _getInitials(displayFullName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 35,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  displayFullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  displayEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 25),

                // --- DETALLES ACADÉMICOS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      "Carrera",
                      displayCareer,
                      Icons.school,
                      Colors.blueAccent,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "Semestre",
                      displaySemester,
                      Icons.calendar_today,
                      Colors.orangeAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatCard(
                      "Índice Académico",
                      displayIndex,
                      Icons.workspace_premium,
                      Colors.greenAccent,
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                // --- SECCIÓN: SOBRE MÍ ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sobre mí",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    displayAbout,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- SECCIÓN: HABILIDADES ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Habilidades / Stack",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: displaySkills.isEmpty
                      ? const Text(
                          "Dato no registrado",
                          style: TextStyle(color: AppTheme.textSecondary),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: displaySkills
                              .map((skill) => _buildSkillChip(skill))
                              .toList(),
                        ),
                ),

                const SizedBox(height: 50),

                // --- ACCIÓN RÁPIDA ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Feedback rápido
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Volviendo a Solicitudes..."),
                          backgroundColor: Colors.white24,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.iconColor,
                    ),
                    label: const Text(
                      "Volver a Evaluaciones",
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppTheme.surfaceLight, // Un color muy neutro/dark
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.8), size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}
