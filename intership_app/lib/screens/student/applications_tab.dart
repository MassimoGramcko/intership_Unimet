import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // ¡Ahora sí lo usaremos!
import '../../config/theme.dart';

class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({super.key});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  String _selectedFilter = 'Todos'; // Filtro seleccionado por defecto

  // Configuración de colores y textos según el estado
  final Map<String, dynamic> statusConfig = {
    'pending': {'color': Colors.blue, 'label': 'Enviado', 'step': 1},
    'reviewing': {'color': Colors.orange, 'label': 'En Revisión', 'step': 2},
    'accepted': {'color': Colors.greenAccent, 'label': 'Aceptado', 'step': 3},
    'rejected': {'color': Colors.redAccent, 'label': 'No seleccionado', 'step': 3},
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Mis Postulaciones", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. FILTROS (Cápsulas)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildFilterChip("Todos"),
                const SizedBox(width: 10),
                _buildFilterChip("Pendiente", dbValue: "pending"),
                const SizedBox(width: 10),
                _buildFilterChip("En Revisión", dbValue: "reviewing"),
                const SizedBox(width: 10),
                _buildFilterChip("Aceptado", dbValue: "accepted"),
                const SizedBox(width: 10),
                _buildFilterChip("Rechazado", dbValue: "rejected"),
              ],
            ),
          ),

          // 2. LISTA DE SOLICITUDES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('studentId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Filtrado manual (para evitar crear múltiples índices en Firestore por ahora)
                var docs = snapshot.data!.docs;
                if (_selectedFilter != 'Todos') {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['status'] ?? 'pending') == _selectedFilter;
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

  // --- WIDGETS AUXILIARES ---

  Widget _buildFilterChip(String label, {String? dbValue}) {
    final isSelected = dbValue == null ? _selectedFilter == 'Todos' : _selectedFilter == dbValue;
    final valueToSet = dbValue ?? 'Todos';

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = valueToSet),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: AppTheme.primaryOrange.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> data) {
    final statusKey = data['status'] ?? 'pending';
    final config = statusConfig[statusKey] ?? statusConfig['pending'];
    final Color statusColor = config['color'];
    final String statusLabel = config['label'];
    final int currentStep = config['step']; // 1, 2, o 3

    // --- AQUÍ USAMOS INTL PARA LA FECHA ---
    String dateStr = "Reciente";
    if (data['appliedAt'] != null) {
      try {
        DateTime date = (data['appliedAt'] as Timestamp).toDate();
        // Formato: 29 Ene, 05:30 PM
        dateStr = DateFormat('dd MMM, hh:mm a').format(date); 
      } catch (e) {
        dateStr = "Fecha desconocida";
      }
    }
    // --------------------------------------

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // Parte Superior: Info Empresa
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono decorativo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.business, color: statusColor, size: 28),
                ),
                const SizedBox(width: 15),
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['jobTitle'] ?? 'Puesto',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['company'] ?? 'Empresa',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Badge de estado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.05), height: 1),

          // Parte Inferior: Barra de Progreso
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Progreso de solicitud", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                    // Mostramos la fecha formateada aquí
                    Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                // Timeline Visual
                SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      _buildProgressSegment(isActive: currentStep >= 1, color: statusColor, isFirst: true),
                      const SizedBox(width: 4),
                      _buildProgressSegment(isActive: currentStep >= 2, color: statusColor),
                      const SizedBox(width: 4),
                      _buildProgressSegment(isActive: currentStep >= 3, color: statusColor, isLast: true),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProgressSegment({required bool isActive, required Color color, bool isFirst = false, bool isLast = false}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white.withOpacity(0.1),
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
          Icon(Icons.folder_off_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 15),
          Text(
            "No hay solicitudes en '$_selectedFilter'",
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}