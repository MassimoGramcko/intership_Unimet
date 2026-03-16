import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importación usando el nombre del paquete para evitar errores de ruta
import 'package:intership_app/services/chat_utils.dart';

// 1. CAMBIAMOS A STATEFUL WIDGET PARA MANEJAR EL ESTADO DEL BUSCADOR
class ListaUsuariosScreen extends StatefulWidget {
  const ListaUsuariosScreen({super.key});

  @override
  State<ListaUsuariosScreen> createState() => _ListaUsuariosScreenState();
}

class _ListaUsuariosScreenState extends State<ListaUsuariosScreen> {
  // 2. CONTROLADORES PARA LA BÚSQUEDA
  final TextEditingController _searchController = TextEditingController();
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Estudiantes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- 3. BARRA DE BÚSQUEDA ---
          Container(
            color: const Color(
              0xFF1E293B,
            ), // Fondo para que se mezcle con el AppBar
            padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Buscar por nombre o carrera...",
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.blueAccent,
                  ),
                  // Botón para borrar el texto si hay algo escrito
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
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
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _searchQuery.isNotEmpty
                              ? "No se encontraron resultados"
                              : "No hay estudiantes registrados.",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (context, index) {
                    final userDoc = users[index];

                    final Map<String, dynamic> data =
                        userDoc.data() as Map<String, dynamic>;

                    final String firstName =
                        data['firstName']?.toString() ?? '';
                    final String lastName = data['lastName']?.toString() ?? '';
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
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          career,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
