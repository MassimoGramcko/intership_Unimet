import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_offer_screen.dart';
import 'candidates_screen.dart';

class ManageOffersScreen extends StatefulWidget {
  const ManageOffersScreen({super.key});

  @override
  State<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends State<ManageOffersScreen> {
  // --- COLORES PRE-COMPUTADOS ---
  static const Color _surfaceDark = Color(0xFF1E293B);
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white50 = Color(0x80FFFFFF);

  // --- CONTROLADORES ---
  late final Stream<QuerySnapshot> _offersStream;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _offersStream = FirebaseFirestore.instance
        .collection('job_offers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Mis Ofertas Activas",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _white10, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.3,
            colors: [_surfaceDark, _bgDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- BUSCADOR ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _white10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Buscar oferta o empresa...',
                      hintStyle: const TextStyle(color: _white50, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _white50, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: _white50, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              // --- LISTA ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _offersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.orangeAccent),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Filtrar por búsqueda
                    var docs = snapshot.data!.docs.where((doc) {
                      if (_searchQuery.isEmpty) return true;
                      final data = doc.data() as Map<String, dynamic>;
                      final title =
                          (data['title'] ?? '').toString().toLowerCase();
                      final company =
                          (data['company'] ?? '').toString().toLowerCase();
                      return title.contains(_searchQuery) ||
                          company.contains(_searchQuery);
                    }).toList();

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 60, color: _white10),
                            const SizedBox(height: 15),
                            Text(
                              'Sin resultados para "$_searchQuery"',
                              style: const TextStyle(
                                  color: _white50, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(10),
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final docId = docs[index].id;
                          return _OfferCard(data: data, docId: docId);
                        },
                      ),
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
          Icon(Icons.folder_off_outlined, size: 100, color: _white10),
          const SizedBox(height: 20),
          const Text(
            "No tienes ofertas creadas",
            style: TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Tus nuevas vacantes aparecerán aquí.",
            style: TextStyle(color: _white50),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  // --- COLORES PRE-COMPUTADOS ---
  static const Color _surfaceDark = Color(0xFF1E293B);
  static const Color _white08 = Color(0x14FFFFFF);
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white40 = Color(0x66FFFFFF);
  static const Color _white60 = Color(0x99FFFFFF);

  const _OfferCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    bool isActive = data['isActive'] ?? false;
    String title = data['title'] ?? 'Sin título';
    String type = data['type'] ?? data['modality'] ?? 'Presencial';

    // Recuperamos el valor local solo como fallback u omitimos ya que usaremos un StreamBuilder real.
    // final int applicantsCount = (data['applicantsCount'] as int?) ?? 0;

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Eliminar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 32),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "¿Eliminar oferta?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Esta acción borrará la oferta permanentemente y no se puede deshacer.",
              style: TextStyle(color: Color(0xB3FFFFFF)),
            ),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  "Sí, Eliminar",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('job_offers')
                      .doc(docId)
                      .delete();
                  Navigator.of(ctx).pop(true);
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C3E50).withValues(alpha: 0.9),
              _surfaceDark.withValues(alpha: 0.95),
            ],
            stops: const [0.1, 0.9],
          ),
          border: Border.all(color: _white08, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.work_rounded,
                    color: Colors.blueAccent.shade200,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['company'] ?? 'Empresa',
                        style: const TextStyle(color: _white60, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.9,
                  child: Switch.adaptive(
                    value: isActive,
                    activeColor: Colors.orangeAccent,
                    activeTrackColor: Colors.orangeAccent.withValues(
                      alpha: 0.4,
                    ),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: _white10,
                    onChanged: (val) {
                      FirebaseFirestore.instance
                          .collection('job_offers')
                          .doc(docId)
                          .update({'isActive': val});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // RECUPERADO: StreamBuilder para contador en tiempo real de postulaciones
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('offerId', isEqualTo: docId)
                  .snapshots(),
              builder: (context, snapshot) {
                int applicantsCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                int vacancies = data['vacancies'] ?? 0;
                bool isFull = vacancies > 0 && applicantsCount >= vacancies;

                return Row(
                  children: [
                    _buildTag(
                      text: type,
                      icon: Icons.location_on_outlined,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: applicantsCount > 0
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminOfferCandidatesScreen(
                                    offerId: docId,
                                    offerTitle: title,
                                  ),
                                ),
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      child: _buildTag(
                        text: vacancies > 0
                            ? "$applicantsCount / $vacancies Postulados"
                            : applicantsCount > 0
                                ? "$applicantsCount Postulados"
                                : "Sin postulantes",
                        icon: applicantsCount > 0
                            ? Icons.people_alt_rounded
                            : Icons.person_off_outlined,
                        color: isFull
                            ? Colors.redAccent
                            : (applicantsCount > 0
                                ? Colors.orangeAccent
                                : const Color(0x61FFFFFF)),
                        isFilled: isFull,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            const Divider(color: Color(0x1AFFFFFF), thickness: 1),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: _white40,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Creado: ${_formatDate(data['createdAt'])}",
                      style: const TextStyle(color: _white40, fontSize: 12),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditOfferScreen(docId: docId, currentData: data),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          "Editar",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required String text,
    required IconData icon,
    required Color color,
    bool isFilled = false,
  }) {
    Color finalColor = color == const Color(0x61FFFFFF)
        ? const Color(0x99FFFFFF)
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isFilled
            ? finalColor.withValues(alpha: 0.25)
            : finalColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFilled
              ? Colors.transparent
              : finalColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isFilled ? Colors.white : finalColor, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isFilled ? Colors.white : finalColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }
    return "N/A";
  }
}
