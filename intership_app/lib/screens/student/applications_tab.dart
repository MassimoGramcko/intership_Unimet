import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Si te da error esta línea, comenta el import y usa Colors.orange en su lugar
// import '../../config/theme.dart'; 
//comentario de prueba

class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({super.key});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  String _selectedFilter = 'Todos';

  // Configuración visual según el estado ESTANDARIZADO
  final Map<String, dynamic> statusConfig = {
    'pending': {'color': Colors.blue, 'label': 'Enviado', 'step': 1},
    'reviewing': {'color': Colors.orange, 'label': 'En Revisión', 'step': 2},
    'accepted': {'color': const Color(0xFF22C55E), 'label': 'Aceptado', 'step': 3}, // Verde fuerte
    'rejected': {'color': const Color(0xFFEF4444), 'label': 'No seleccionado', 'step': 3}, // Rojo
  };

  // --- FUNCIÓN CRÍTICA: NORMALIZA EL ESTADO ---
  // Convierte "Aceptado", "Approved", "accepted" -> "accepted"
  String _getStatusKey(String? rawStatus) {
    String status = (rawStatus ?? '').toLowerCase();
    
    if (status.contains('aceptado') || status.contains('accepted') || status.contains('aprobado')) {
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
    final user = FirebaseAuth.instance.currentUser;
    // Color principal seguro (por si no tienes el archivo theme)
    const Color primaryColor = Color(0xFFFF6B00); 

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
          // 1. FILTROS
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

          // 2. LISTA DE SOLICITUDES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('studentId', isEqualTo: user?.uid)
                  .orderBy('appliedAt', descending: true) // Asegúrate de tener índice compuesto si esto falla
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                var docs = snapshot.data!.docs;

                // Filtrado manual usando la llave normalizada
                if (_selectedFilter != 'Todos') {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // Usamos la función traductora aquí también
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

  // --- WIDGETS AUXILIARES ---

  Widget _buildFilterChip(String label, Color activeColor, {String? dbKey}) {
    final valueToSet = dbKey ?? 'Todos';
    final isSelected = _selectedFilter == valueToSet;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = valueToSet),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withOpacity(0.1),
          ),
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
    // 1. OBTENER LA LLAVE CORRECTA (pending, accepted, rejected)
    final statusKey = _getStatusKey(data['status']);
    
    // 2. OBTENER CONFIGURACIÓN
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
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // Parte Superior
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
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

          // Parte Inferior: Timeline
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Progreso:", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                    Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      _buildProgressSegment(isActive: currentStep >= 1, color: statusColor, isFirst: true),
                      const SizedBox(width: 4),
                      _buildProgressSegment(isActive: currentStep >= 2, color: statusColor),
                      const SizedBox(width: 4),
                      // Si está rechazado, el paso 3 se pinta también (rojo), si es aceptado (verde)
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
            "No hay solicitudes aquí",
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}