import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import '../auth/login_screen.dart';
import 'create_offer_screen.dart';
import 'manage_offers_screen.dart'; 
import 'coordinator_applications_screen.dart';

class CoordinatorHome extends StatefulWidget {
  const CoordinatorHome({super.key});

  @override
  State<CoordinatorHome> createState() => _CoordinatorHomeState();
}

class _CoordinatorHomeState extends State<CoordinatorHome> {
  
  // Color principal naranja
  final Color primaryOrange = const Color(0xFFFF6B00);
  
  // Variable de estado para el filtro
  String _filtroStatus = 'Todos'; 

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- NUEVA FUNCIÓN: Obtener Iniciales ---
  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    
    // Divide el nombre por espacios y elimina espacios vacíos extras
    List<String> nameParts = name.trim().split(RegExp(r'\s+'));
    
    if (nameParts.isEmpty) return "?";

    String initials = nameParts[0][0]; // Primera letra del primer nombre
    if (nameParts.length > 1) {
      initials += nameParts.last[0]; // Primera letra del último apellido
    }

    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), 
      body: Stack(
        children: [
          // CAPA 1: Fondo
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
            ),
          ),

          // CAPA 2: Contenido
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Hola, Coordinador 👋",
                            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _logout(context),
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 35),

                  // TARJETAS KPI
                  Row(
                    children: [
                      _buildModernKpiCard(
                        title: "Solicitudes",
                        collectionName: "applications",
                        icon: Icons.people_alt_rounded,
                        accentColor: Colors.orangeAccent,
                        gradientColors: [primaryOrange.withOpacity(0.8), Colors.orange[800]!],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CoordinatorApplicationsScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 15),
                      _buildModernKpiCard(
                        title: "Ofertas Activas",
                        collectionName: "job_offers",
                        icon: Icons.business_center_rounded,
                        accentColor: Colors.blueAccent,
                        gradientColors: [Colors.blueAccent.withOpacity(0.8), Colors.blue[800]!],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ManageOffersScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),
                  
                  // TÍTULO SECCIÓN + MENU DE FILTRO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Actividad Reciente", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_horiz_rounded, color: Colors.white.withOpacity(0.7)),
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                        onSelected: (String valor) {
                          setState(() {
                            _filtroStatus = valor;
                          });
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          _buildPopupItem("Todos", Icons.dashboard_customize_outlined),
                          const PopupMenuDivider(height: 1),
                          _buildPopupItem("Pendiente", Icons.hourglass_empty_rounded, Colors.orangeAccent),
                          _buildPopupItem("Aceptado", Icons.check_circle_outline_rounded, Colors.greenAccent),
                          _buildPopupItem("Rechazado", Icons.cancel_outlined, Colors.redAccent),
                        ],
                      ),
                    ],
                  ),

                  // Indicador visual de filtro activo
                  if (_filtroStatus != 'Todos')
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 5),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt_outlined, size: 14, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 5),
                          Text("Filtrando por: ", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                          Text(_filtroStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => setState(() => _filtroStatus = 'Todos'),
                            child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 15),

                  // LISTA DE ACTIVIDAD
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('applications')
                        .orderBy('appliedAt', descending: true)
                        .limit(20) 
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: primaryOrange),
                        ));
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildModernEmptyState("No hay actividad reciente");
                      }

                      var docs = snapshot.data!.docs;

                      if (_filtroStatus != 'Todos') {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? '').toString();
                          return status.toLowerCase() == _filtroStatus.toLowerCase();
                        }).toList();
                      }

                      if (docs.isEmpty) {
                         return _buildModernEmptyState("No hay solicitudes $_filtroStatus");
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return _buildModernReviewTile(data);
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 80), 
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const CreateOfferScreen())
            );
          },
          backgroundColor: primaryOrange,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          label: const Text("Crear Oferta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---

  PopupMenuItem<String> _buildPopupItem(String text, IconData icon, [Color? color]) {
    return PopupMenuItem<String>(
      value: text,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 18),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color ?? Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildModernKpiCard({
    required String title,
    required String collectionName,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    VoidCallback? onTap, 
  }) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
        builder: (context, snapshot) {
          int count = 0;
          if (snapshot.hasData) {
            if (collectionName == 'job_offers') {
               count = snapshot.data!.docs.where((doc) => doc['isActive'] == true).length;
            } else if (collectionName == 'applications') {
               count = snapshot.data!.docs.where((doc) => doc['status'] == 'Pendiente').length;
            } else {
               count = snapshot.data!.docs.length;
            }
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
                    gradientColors[0].withOpacity(0.2),
                    gradientColors[1].withOpacity(0.1),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(icon, size: 100, color: accentColor.withOpacity(0.05)),
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
                            color: accentColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: accentColor, size: 24),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$count",
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                            ),
                          ],
                        )
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

  Widget _buildModernReviewTile(Map<String, dynamic> data) {
    String status = (data['status'] ?? 'Pendiente').toString().toLowerCase();
    String studentName = data['studentName'] ?? 'Estudiante';
    String initials = _getInitials(studentName); // Obtener iniciales

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

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // --- AVATAR CON INICIALES ---
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue[400]!, Colors.purple[400]!]
              ),
              shape: BoxShape.circle,
              boxShadow: [
                 BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
              ]
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 18,
                letterSpacing: 1.0
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.work_outline_rounded, color: Colors.white.withOpacity(0.5), size: 14),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        data['jobTitle'] ?? 'Puesto desconocido', 
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
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
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: statusColor.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 8)]
            ),
            child: Text(
              statusText, 
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)
            ),
          )
        ],
      ),
    );
  }

  Widget _buildModernEmptyState([String message = "No hay nuevas solicitudes pendientes."]) {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.filter_list_off_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 20),
          const Text("Sin resultados", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}