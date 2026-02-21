import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 
import 'create_offer_screen.dart';
import 'manage_offers_screen.dart'; 
import 'coordinator_applications_screen.dart';
import 'coordinator_settings_screen.dart';

// NUEVO: Importamos la pantalla de Lista de Usuarios / Chats
// (Asegúrate de que el nombre del archivo y la carpeta sean correctos, si lo llamaste diferente, ajusta esta línea)
// Como están en la misma carpeta (Coordinador), puedes llamarlo directo así:
import 'lista_usuarios_screen.dart';

class CoordinatorHome extends StatefulWidget {
  const CoordinatorHome({super.key});

  @override
  State<CoordinatorHome> createState() => _CoordinatorHomeState();
}

class _CoordinatorHomeState extends State<CoordinatorHome> with SingleTickerProviderStateMixin {
  
  // Color principal naranja
  final Color primaryOrange = const Color(0xFFFF6B00);
  
  // Variable de estado para el filtro
  String _filtroStatus = 'Todos'; 

  // Variables para la animación del Speed Dial
  late AnimationController _animationController;
  bool _isDialOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
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

  // --- FUNCIÓN: Archivar historial antiguo ---
  void _clearOldActivity() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Limpiar historial?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Se ocultarán de esta vista las solicitudes 'Aceptadas' o 'Rechazadas'.\n\nNo te preocupes, los datos y contadores de la oferta seguirán intactos.", 
          style: TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(ctx).pop(false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: const StadiumBorder()),
            child: const Text("Sí, Limpiar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      var snapshot = await FirebaseFirestore.instance.collection('applications').get();
      int archivedCount = 0;
      
      for (var doc in snapshot.docs) {
        var data = doc.data();
        var status = (data['status'] ?? '').toString().toLowerCase();
        bool isArchived = data['isArchived'] ?? false;
        
        if (!isArchived && (status == 'aceptado' || status == 'rechazado' || status == 'accepted' || status == 'rejected')) {
          await doc.reference.update({'isArchived': true});
          archivedCount++;
        }
      }
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text("Limpieza exitosa: Se ocultaron $archivedCount registros."),
             backgroundColor: Colors.greenAccent.shade700,
           )
         );
      }
    }
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CoordinatorSettingsScreen()),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: const Icon(Icons.settings_outlined, color: Colors.white, size: 22), 
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
                          if (valor == 'Limpiar Historial') {
                            _clearOldActivity();
                          } else {
                            setState(() {
                              _filtroStatus = valor;
                            });
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          _buildPopupItem("Todos", Icons.dashboard_customize_outlined),
                          const PopupMenuDivider(height: 1),
                          _buildPopupItem("Pendiente", Icons.hourglass_empty_rounded, Colors.orangeAccent),
                          _buildPopupItem("Aceptado", Icons.check_circle_outline_rounded, Colors.greenAccent),
                          _buildPopupItem("Rechazado", Icons.cancel_outlined, Colors.redAccent),
                          const PopupMenuDivider(height: 1),
                          _buildPopupItem("Limpiar Historial", Icons.delete_sweep_rounded, Colors.orangeAccent), 
                        ],
                      ),
                    ],
                  ),

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
                        .limit(50) 
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

                      var docs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isArchived = data['isArchived'] ?? false;
                        return !isArchived; 
                      }).toList();

                      if (_filtroStatus != 'Todos') {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? '').toString();
                          return status.toLowerCase() == _filtroStatus.toLowerCase();
                        }).toList();
                      }

                      if (docs.isEmpty) {
                         return _buildModernEmptyState("No hay actividad reciente para mostrar.");
                      }

                      final displayDocs = docs.take(20).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayDocs.length,
                        itemBuilder: (context, index) {
                          final doc = displayDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final docId = doc.id; 
                          return _buildModernReviewTile(data, docId); 
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 80), 
                ],
              ),
            ),
          ),
          
          if (_isDialOpen)
            GestureDetector(
              onTap: _toggleDial,
              child: Container(
                color: Colors.black.withOpacity(0.4), 
              ),
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
        // BOTÓN 1: CHAT
        ScaleTransition(
          scale: CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Text("Mensajes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              FloatingActionButton.small(
                heroTag: "chat_btn",
                backgroundColor: Colors.blueAccent,
                onPressed: () {
                  _toggleDial();
                  // ¡AQUÍ HICIMOS EL CAMBIO! Navegamos a la lista de usuarios
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListaUsuariosScreen()), 
                  );
                },
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 15),

        // BOTÓN 2: CREAR OFERTA
        ScaleTransition(
          scale: CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Text("Crear Oferta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 15),
              FloatingActionButton.small(
                heroTag: "offer_btn",
                backgroundColor: primaryOrange,
                onPressed: () {
                  _toggleDial();
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const CreateOfferScreen())
                  );
                },
                child: const Icon(Icons.add_business_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 15),

        // BOTÓN PRINCIPAL
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryOrange.withOpacity(0.5),
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
                CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
            ),
          ),
        ),
      ],
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
          color: Colors.orangeAccent.withOpacity(0.9), 
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text("Ocultar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Icons.visibility_off_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("¿Ocultar actividad?", style: TextStyle(color: Colors.white)),
            content: const Text("Esta acción quitará el registro de tu historial, pero mantendrá la postulación en la base de datos de la oferta.", style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(ctx).pop(false)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: const StadiumBorder()),
                child: const Text("Sí, Ocultar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                onPressed: () {
                   FirebaseFirestore.instance.collection('applications').doc(docId).update({'isArchived': true});
                   Navigator.of(ctx).pop(true);
                }
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
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