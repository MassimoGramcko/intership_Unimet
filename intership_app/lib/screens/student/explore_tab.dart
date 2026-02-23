import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import 'job_details_screen.dart'; 

// --- MODELO DE DATOS (Sin cambios) ---
class JobOffer {
  final String id;
  final String title;
  final String company;
  final String location;
  final String type;
  final String wage;
  final String description; 
  final bool isRemote;
  final bool isFeatured;
  final Color brandColor;
  final Timestamp? postedAt;
  final double? latitude;
  final double? longitude;

  JobOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.wage,
    required this.description,
    required this.isRemote,
    required this.isFeatured,
    required this.brandColor,
    this.postedAt,
    this.latitude,
    this.longitude,
  });

  factory JobOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobOffer(
      id: doc.id,
      title: data['title'] ?? 'Sin título',
      company: data['company'] ?? 'Empresa Confidencial',
      location: data['location'] ?? 'Caracas, Venezuela',
      type: data['modality'] ?? 'Pasantía', 
      wage: data['wage'] ?? 'A convenir',
      description: data['description'] ?? 'Sin descripción disponible.',
      isRemote: (data['modality'] == 'Remoto'),
      isFeatured: data['isFeatured'] ?? false,
      postedAt: data['postedAt'] ?? data['createdAt'], 
      brandColor: _parseColor(data['colorHex']),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  static Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.blueAccent;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.blueAccent;
    }
  }
}

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _calculateTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Reciente";
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 0) return "Hace ${diff.inDays}d";
    if (diff.inHours > 0) return "Hace ${diff.inHours}h";
    return "Hace ${diff.inMinutes}m";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // A. FONDO GLOW
          Positioned(
            top: -80,
            left: -20,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryOrange.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.3),
                    blurRadius: 120,
                    spreadRadius: 20,
                  )
                ],
              ),
            ),
          ),

          // B. CONTENIDO SCROLLABLE
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              
              // 1. APP BAR (Estática, no parpadea)
              SliverAppBar(
                backgroundColor: AppTheme.backgroundDark.withOpacity(0.9),
                floating: true,
                pinned: true,
                elevation: 0,
                centerTitle: true,
                expandedHeight: 70,
                title: const Text(
                  "Descubrir",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                // Botón de notificaciones eliminado de aquí
              ),

              // 2. BUSCADOR (Estático, mantiene el foco)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 15),
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Buscar empleo o empresa...",
                              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                              border: InputBorder.none,
                              suffixIcon: _searchQuery.isNotEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = "";
                                      });
                                    },
                                  )
                                : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. AQUÍ PONEMOS EL STREAMBUILDER (Dentro de los Slivers)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('job_offers')
                    .where('isActive', isEqualTo: true)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  // MIENTRAS CARGA LA PRIMERA VEZ
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                     return SliverToBoxAdapter(
                       child: Center(child: Text("Error de carga", style: TextStyle(color: Colors.white.withOpacity(0.5)))),
                     );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  // PROCESAR DATOS
                  final allDocs = snapshot.data!.docs;
                  final allOffers = allDocs.map((doc) => JobOffer.fromFirestore(doc)).toList();

                  // FILTRADO LOCAL
                  final filteredOffers = allOffers.where((offer) {
                    final query = _searchQuery.toLowerCase();
                    final title = offer.title.toLowerCase();
                    final company = offer.company.toLowerCase();
                    return title.contains(query) || company.contains(query);
                  }).toList();

                  final showFeatured = _searchQuery.isEmpty;
                  final featuredOffers = showFeatured ? allOffers.where((o) => o.isFeatured).take(3).toList() : <JobOffer>[];

                  // LA SOLUCIÓN DEFINITIVA: 
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // 1. Calcular índices
                        int currentIndex = index;
                        
                        // SECCIÓN A: DESTACADOS (Ocupa 1 espacio si existe)
                        bool hasFeatured = showFeatured && featuredOffers.isNotEmpty;
                        if (hasFeatured) {
                          if (currentIndex == 0) {
                             return Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 const Padding(
                                   padding: EdgeInsets.fromLTRB(20, 10, 20, 15),
                                   child: Text("Destacado para ti", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                 ),
                                 SizedBox(
                                    height: 190,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(left: 20),
                                      itemCount: featuredOffers.length,
                                      itemBuilder: (context, i) => _buildFeaturedCard(featuredOffers[i]),
                                    ),
                                 ),
                               ],
                             );
                          }
                          currentIndex--; 
                        }

                        // SECCIÓN B: TÍTULO LISTA (Ocupa 1 espacio)
                        if (currentIndex == 0) {
                           return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                            child: Text(
                              _searchQuery.isEmpty ? "Ofertas Recientes" : "Resultados (${filteredOffers.length})", 
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                          );
                        }
                        currentIndex--;

                        // SECCIÓN C: ITEMS DE LA LISTA O VACÍO
                        if (filteredOffers.isEmpty && _searchQuery.isNotEmpty) {
                           if (currentIndex == 0) {
                             return Container(
                                padding: const EdgeInsets.only(top: 50),
                                child: Column(
                                  children: [
                                     const Icon(Icons.search_off, size: 60, color: Colors.white24),
                                     const SizedBox(height: 10),
                                     Text('No encontramos "$_searchQuery"', style: const TextStyle(color: Colors.white54)),
                                  ],
                                ),
                              );
                           }
                           return null;
                        }

                        if (currentIndex < filteredOffers.length) {
                          return _buildVerticalCard(filteredOffers[currentIndex]);
                        }
                        
                        // Espacio final
                        if (currentIndex == filteredOffers.length) {
                          return const SizedBox(height: 100);
                        }

                        return null; // Fin de la lista
                      },
                      childCount: (showFeatured && featuredOffers.isNotEmpty ? 1 : 0) + 1 + (filteredOffers.isEmpty && _searchQuery.isNotEmpty ? 1 : filteredOffers.length) + 1,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.work_off_outlined, color: Colors.grey, size: 50),
            SizedBox(height: 10),
            Text("No hay ofertas disponibles aún", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(JobOffer offer) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailsScreen(offer: offer)),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2D3E), Color(0xFF1F212E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Hero(
                    tag: "featured_${offer.id}", 
                    child: Icon(Icons.business, color: offer.brandColor, size: 24)
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppTheme.primaryOrange.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(offer.wage, style: const TextStyle(color: AppTheme.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Spacer(),
            Text(offer.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Text(offer.company, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildTag(offer.type, Colors.purpleAccent),
                const SizedBox(width: 8),
                if (offer.isRemote) _buildTag("Remoto", Colors.tealAccent),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCard(JobOffer offer) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailsScreen(offer: offer)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: offer.brandColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Hero(
                tag: "list_${offer.id}", 
                child: Icon(Icons.work_outline, color: offer.brandColor)
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("${offer.company} • ${offer.location}", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_calculateTimeAgo(offer.postedAt), style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                const SizedBox(height: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16)
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}