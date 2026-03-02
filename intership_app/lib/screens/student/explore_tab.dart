import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import 'job_details_screen.dart';

// --- MODELO DE DATOS (Sin cambios funcionales) ---
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
  final ScrollController _scrollController = ScrollController(); // <-- NUEVO: Controlador para el Scrollbar
  String _searchQuery = "";

  // --- COLORES PRE-COMPUTADOS ---
  static const Color _white03 = Color(0x08FFFFFF);
  static const Color _white05 = Color(0x0DFFFFFF);
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white24 = Color(0x3DFFFFFF);
  static const Color _white30 = Color(0x4DFFFFFF);
  static const Color _white50 = Color(0x80FFFFFF);
  static const Color _white60 = Color(0x99FFFFFF);
  static const Color _grey50 = Color(0x80808080);
  static const Color _black10 = Color(0x1A000000);
  static const Color _black30 = Color(0x4D000000);

  // --- STREAM CACHEADO ---
  late final Stream<QuerySnapshot> _offersStream;

  @override
  void initState() {
    super.initState();
    _offersStream = FirebaseFirestore.instance
        .collection('job_offers')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // <-- IMPORTANTE
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
                color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 120,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // B. CONTENIDO SCROLLABLE
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(10),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
              // 1. APP BAR
              SliverAppBar(
                backgroundColor: AppTheme.backgroundDark.withValues(alpha: 0.9),
                floating: true,
                pinned: true,
                elevation: 0,
                centerTitle: true,
                expandedHeight: 70,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  "Descubrir",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              // 2. BUSCADOR
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: _white05,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _white10),
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
                              hintStyle: const TextStyle(color: _grey50),
                              border: InputBorder.none,
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
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

              // 3. STREAM BUILDER con stream cacheado
              StreamBuilder<QuerySnapshot>(
                stream: _offersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          "Error de carga",
                          style: TextStyle(color: _white50),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  final allDocs = snapshot.data!.docs;
                  final allOffers = allDocs
                      .map((doc) => JobOffer.fromFirestore(doc))
                      .toList();

                  final filteredOffers = allOffers.where((offer) {
                    final query = _searchQuery.toLowerCase();
                    final title = offer.title.toLowerCase();
                    final company = offer.company.toLowerCase();
                    return title.contains(query) || company.contains(query);
                  }).toList();

                  final showFeatured = _searchQuery.isEmpty;
                  final featuredOffers = showFeatured
                      ? allOffers.where((o) => o.isFeatured).take(3).toList()
                      : <JobOffer>[];

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        int currentIndex = index;

                        bool hasFeatured =
                            showFeatured && featuredOffers.isNotEmpty;
                        if (hasFeatured) {
                          if (currentIndex == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(20, 10, 20, 15),
                                  child: Text(
                                    "Destacado para ti",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 190,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.only(left: 20),
                                    itemCount: featuredOffers.length,
                                    itemBuilder: (context, i) =>
                                        _InteractiveFeaturedCard(
                                            offer: featuredOffers[i]),
                                  ),
                                ),
                              ],
                            );
                          }
                          currentIndex--;
                        }

                        if (currentIndex == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? "Ofertas Recientes"
                                  : "Resultados (${filteredOffers.length})",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        currentIndex--;

                        if (filteredOffers.isEmpty && _searchQuery.isNotEmpty) {
                          if (currentIndex == 0) {
                            return Container(
                              padding: const EdgeInsets.only(top: 50),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    size: 60,
                                    color: _white24,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No encontramos "$_searchQuery"',
                                    style: const TextStyle(
                                      color: Color(0x8AFFFFFF),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return null;
                        }

                        if (currentIndex < filteredOffers.length) {
                          return _InteractiveVerticalCard(
                            offer: filteredOffers[currentIndex],
                          );
                        }

                        if (currentIndex == filteredOffers.length) {
                          return const SizedBox(height: 100);
                        }

                        return null;
                      },
                      childCount:
                          (showFeatured && featuredOffers.isNotEmpty ? 1 : 0) +
                          1 +
                          (filteredOffers.isEmpty && _searchQuery.isNotEmpty
                              ? 1
                              : filteredOffers.length) +
                          1,
                    ),
                  );
                },
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.only(top: 50),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, color: Colors.grey, size: 50),
            SizedBox(height: 10),
            Text(
              "No hay ofertas disponibles aún",
              style: TextStyle(color: Color(0xB3FFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CLASES INTERACTIVAS (ANIMADAS) ---

class _InteractiveFeaturedCard extends StatefulWidget {
  final JobOffer offer;
  const _InteractiveFeaturedCard({required this.offer});

  @override
  State<_InteractiveFeaturedCard> createState() =>
      _InteractiveFeaturedCardState();
}

class _InteractiveFeaturedCardState extends State<_InteractiveFeaturedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _isPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(offer: widget.offer),
          ),
        );
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isPressed = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280,
          margin: const EdgeInsets.only(right: 15, bottom: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _isPressed ? const Color(0xFF32364A) : const Color(0xFF2A2D3E),
                _isPressed ? const Color(0xFF252838) : const Color(0xFF1F212E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isPressed
                  ? widget.offer.brandColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.4 : 0.3),
                blurRadius: _isPressed ? 20 : 15,
                offset: Offset(0, _isPressed ? 12 : 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Hero(
                      tag: "featured_${widget.offer.id}",
                      child: Icon(
                        Icons.business,
                        color: widget.offer.brandColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.offer.wage,
                      style: const TextStyle(
                        color: AppTheme.primaryOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.offer.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                widget.offer.company,
                style: const TextStyle(
                    color: Color(0x99FFFFFF), fontSize: 14),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildTag(widget.offer.type, Colors.purpleAccent),
                  const SizedBox(width: 8),
                  if (widget.offer.isRemote)
                    _buildTag("Remoto", Colors.tealAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InteractiveVerticalCard extends StatefulWidget {
  final JobOffer offer;
  const _InteractiveVerticalCard({required this.offer});

  @override
  State<_InteractiveVerticalCard> createState() =>
      _InteractiveVerticalCardState();
}

class _InteractiveVerticalCardState extends State<_InteractiveVerticalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _controller.reverse();
        setState(() => _isPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(offer: widget.offer),
          ),
        );
      },
      onTapCancel: () {
        _controller.reverse();
        setState(() => _isPressed = false);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isPressed ? const Color(0xFF2D3748) : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? widget.offer.brandColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.03),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.2 : 0.1),
                blurRadius: _isPressed ? 10 : 5,
                offset: Offset(0, _isPressed ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.offer.brandColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Hero(
                  tag: "list_${widget.offer.id}",
                  child: Icon(Icons.work_outline, color: widget.offer.brandColor),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.offer.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${widget.offer.company} • ${widget.offer.location}",
                      style: const TextStyle(
                        color: Color(0x80FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _calculateTimeAgo(widget.offer.postedAt),
                    style: const TextStyle(
                      color: Color(0x4DFFFFFF),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0x3DFFFFFF),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Reciente";
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inDays > 0) return "Hace ${diff.inDays}d";
    if (diff.inHours > 0) return "Hace ${diff.inHours}h";
    return "Hace ${diff.inMinutes}m";
  }
}
