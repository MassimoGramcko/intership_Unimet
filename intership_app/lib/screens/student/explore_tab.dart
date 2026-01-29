import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import 'job_details_screen.dart'; // 1. IMPORT NECESARIO

// MODELO DE DATOS
class JobOffer {
  final String id;
  final String title;
  final String company;
  final String location;
  final String type;
  final String wage;
  final bool isRemote;
  final bool isFeatured;
  final Color brandColor;
  final Timestamp? postedAt;

  JobOffer({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.wage,
    required this.isRemote,
    required this.isFeatured,
    required this.brandColor,
    this.postedAt,
  });

  factory JobOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobOffer(
      id: doc.id,
      title: data['title'] ?? 'Sin título',
      company: data['company'] ?? 'Empresa Confidencial',
      location: data['location'] ?? 'Ubicación no especificada',
      type: data['type'] ?? 'Pasantía',
      wage: data['wage'] ?? 'A convenir',
      isRemote: data['isRemote'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      postedAt: data['postedAt'],
      brandColor: _parseColor(data['colorHex']),
    );
  }

  static Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.grey;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_offers')
            .orderBy('postedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
          }

          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final allDocs = snapshot.data!.docs;
          
          final featuredOffers = allDocs
              .map((doc) => JobOffer.fromFirestore(doc))
              .where((offer) => offer.isFeatured)
              .toList();

          final recentOffers = allDocs
              .map((doc) => JobOffer.fromFirestore(doc))
              .where((offer) => !offer.isFeatured)
              .toList();

          return Stack(
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
                  
                  // BARRA SUPERIOR
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
                        shadows: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ]
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _buildIconButton(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),

                  // BUSCADOR
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Container(
                        height: 55,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ]
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 15),
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Buscar empleo...",
                                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // SECCIÓN DESTACADOS
                  if (featuredOffers.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                        child: const Text("Destacado para ti", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 190,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 20),
                          itemCount: featuredOffers.length,
                          itemBuilder: (context, index) => _buildFeaturedCard(featuredOffers[index]),
                        ),
                      ),
                    ),
                  ],

                  // SECCIÓN RECIENTES
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                      child: Text(
                        recentOffers.isEmpty ? "Todas las ofertas" : "Agregados Recientemente", 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),

                  // LISTA VERTICAL
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildVerticalCard(recentOffers[index]),
                      childCount: recentOffers.length,
                    ),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.work_off_outlined, color: Colors.grey, size: 50),
          SizedBox(height: 10),
          Text("No hay ofertas disponibles aún", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08), 
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.05))
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  // 2. MODIFICACIÓN: Tarjeta destacada con GestureDetector y Hero
  Widget _buildFeaturedCard(JobOffer offer) {
    return GestureDetector( // <--- ENVOLVIMOS TODO EN GESTUREDETECTOR
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
                  // AQUÍ AGREGAMOS EL HERO
                  child: Hero(
                    tag: offer.id, 
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

  // 3. MODIFICACIÓN: Tarjeta vertical con GestureDetector
  Widget _buildVerticalCard(JobOffer offer) {
    return GestureDetector( // <--- ENVOLVIMOS TODO EN GESTUREDETECTOR
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
          ]
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
              child: Icon(Icons.work_outline, color: offer.brandColor),
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