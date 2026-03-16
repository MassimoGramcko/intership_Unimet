import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importación usando el nombre del paquete para evitar errores de ruta
import 'package:intership_app/services/chat_utils.dart';
import '../../config/theme.dart';

// 1. CAMBIAMOS A STATEFUL WIDGET PARA MANEJAR EL ESTADO DEL BUSCADOR
class ListaUsuariosScreen extends StatefulWidget {
  const ListaUsuariosScreen({super.key});

  @override
  State<ListaUsuariosScreen> createState() => _ListaUsuariosScreenState();
}

class _ListaUsuariosScreenState extends State<ListaUsuariosScreen> {
  // 2. CONTROLADORES PARA LA BÚSQUEDA
  // 2. CONTROLADORES
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  // Stream cacheado
  late final Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    // Cacheamos el stream para no recrearlo al buscar
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Función para obtener iniciales (Ej: "Alessandro Gramcko" -> "AG")
  String _getTwoInitials(String fullName) {
    if (fullName.isEmpty) return "??";
    List<String> nameParts = fullName.trim().split(RegExp(r'\s+'));
    if (nameParts.isEmpty || nameParts[0].isEmpty) return "??";

    String initials = nameParts[0][0];
    if (nameParts.length > 1) {
      initials += nameParts.last[0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          // --- HEADER PREMIUM (Estilo UniBot IA) ---
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A237E), Color(0xFF283593)], // Indigo/Blue Premium
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Glow Blob (Aesthetic touch)
                Positioned(
                  top: -50,
                  right: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        // Avatar Icon estilo UniBot
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mensajes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Directorio de Estudiantes",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BARRA DE BÚSQUEDA FLOTANTE ---
          Transform.translate(
            offset: const Offset(0, -15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
                    hintText: "Buscar por nombre o carrera...",
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.blueAccent,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- 4. LISTA DE ESTUDIANTES ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }

                // Filtramos primero para no aparecer nosotros mismos
                var users = snapshot.data!.docs
                    .where((doc) => doc.id != currentUserId)
                    .toList();

                // 5. LÓGICA DEL BUSCADOR
                if (_searchQuery.isNotEmpty) {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final firstName =
                        data['firstName']?.toString().toLowerCase() ?? '';
                    final lastName =
                        data['lastName']?.toString().toLowerCase() ?? '';
                    final fullName = '$firstName $lastName'.trim();
                    final career =
                        data['career']?.toString().toLowerCase() ?? '';

                    // Comprueba si la búsqueda coincide con el nombre O la carrera
                    return fullName.contains(_searchQuery) ||
                        career.contains(_searchQuery);
                  }).toList();
                }

                // Manejo de estado vacío (cuando no hay nadie o la búsqueda no arroja resultados)
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 60,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _searchQuery.isNotEmpty
                              ? "No se encontraron resultados"
                              : "No hay estudiantes registrados.",
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: users.length,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemBuilder: (context, index) {
                      final userDoc = users[index];

                      final Map<String, dynamic> data =
                          userDoc.data() as Map<String, dynamic>;

                      final String firstName =
                          data['firstName']?.toString() ?? '';
                      final String lastName =
                          data['lastName']?.toString() ?? '';
                      final String userName =
                          '$firstName $lastName'.trim().isEmpty
                          ? 'Estudiante'
                          : '$firstName $lastName'.trim();
                      final String career =
                          data['career']?.toString() ?? 'Sin carrera';
                      final String iniciales = _getTwoInitials(userName);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blueAccent.shade400,
                                  Colors.purpleAccent.shade400,
                                ],
                              ),
                            ),
                            child: Text(
                              iniciales,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            career,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          onTap: () {
                            // Abrir chat usando la utilidad
                            iniciarOabrirChat(
                              context: context,
                              currentUserId: currentUserId,
                              otherUserId: userDoc.id,
                              otherUserName: userName,
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
