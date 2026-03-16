import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import 'explore_tab.dart'; // Asegúrate de que esta ruta sea correcta para tu modelo JobOffer

class JobDetailsScreen extends StatefulWidget {
  final JobOffer offer;

  const JobDetailsScreen({super.key, required this.offer});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;
  late final String applicationId;
  late final Stream<DocumentSnapshot>? _applicationStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    applicationId = user != null ? '${user!.uid}_${widget.offer.id}' : 'guest';
    if (user != null) {
      _applicationStream = FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .snapshots();
    } else {
      _applicationStream = null;
    }
  }

  // --- 1. LÓGICA PRINCIPAL (POSTULAR O RETIRAR) ---
  Future<void> _handleApplicationButton(bool isApplied) async {
    if (user == null) return;

    // ID ÚNICO: Combina ID estudiante + ID oferta
    final String applicationId = '${user!.uid}_${widget.offer.id}';
    final docRef = FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId);

    if (isApplied) {
      // --- CASO A: YA ESTÁ POSTULADO -> RETIRAR ---
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceLight,
          title: const Text(
            "Retirar Postulación",
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: const Text(
            "¿Estás seguro de que deseas cancelar tu postulación? Perderás tu lugar.",
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Retirar",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          await docRef.delete();
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Has retirado tu postulación."),
                backgroundColor: Colors.orange,
              ),
            );
        } catch (e) {
          _showError("Error al retirar: $e");
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } else {
      // --- CASO B: NO ESTÁ POSTULADO -> POSTULARSE ---
      setState(() => _isLoading = true);
      try {
        // 1. Verificamos cupos en tiempo real
        final snap = await FirebaseFirestore.instance
            .collection('applications')
            .where('offerId', isEqualTo: widget.offer.id)
            .get();

        final int currentApplicants = snap.docs.length;
        final int vacancies = widget.offer.vacancies;

        if (vacancies > 0 && currentApplicants >= vacancies) {
          _showError(
            "⚠️ Lo sentimos, esta oferta ya ha alcanzado su límite de cupos.",
          );
          return;
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        final userData = userDoc.data() ?? {};
        final studentName =
            "${userData['firstName'] ?? 'Estudiante'} ${userData['lastName'] ?? ''}"
                .trim();

        await docRef.set({
          'offerId': widget.offer.id,
          'jobTitle': widget.offer.title,
          'company': widget.offer.company,
          'studentId': user!.uid,
          'studentName': studentName,
          'studentEmail': userData['email'] ?? user!.email,
          'status': 'Pendiente',
          'appliedAt': FieldValue.serverTimestamp(),
        });

        // Notificaciones...
        final coordinatorsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['coordinator', 'coordinador', 'admin'])
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (var coordDoc in coordinatorsSnapshot.docs) {
          final notifRef = FirebaseFirestore.instance
              .collection('notifications')
              .doc();
          batch.set(notifRef, {
            'userId': coordDoc.id,
            'type': 'application',
            'title': 'Nueva Postulación: ${widget.offer.title}',
            'body': '$studentName se ha postulado a tu oferta.',
            'applicationId': applicationId,
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();

        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ ¡Solicitud enviada con éxito!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
      } catch (e) {
        _showError("Error al postularse: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 6,
            radius: const Radius.circular(10),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 1. HEADER (Igual a tu código)
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  backgroundColor: AppTheme.backgroundLight,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.iconColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                widget.offer.brandColor.withValues(alpha: 0.8),
                                AppTheme.backgroundLight,
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Hero(
                            tag: "list_${widget.offer.id}",
                            child: Icon(
                              Icons.business_rounded,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. CONTENIDO
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.offer.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.offer.company,
                          style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 25),

                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('applications')
                              .where('offerId', isEqualTo: widget.offer.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            int currentApps = snapshot.hasData
                                ? snapshot.data!.docs.length
                                : 0;
                            String vacanciesText = widget.offer.vacancies > 0
                                ? "$currentApps / ${widget.offer.vacancies} Cupos"
                                : "Cupos Ilimitados";

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildInfoChip(
                                  Icons.location_on_outlined,
                                  widget.offer.location,
                                ),
                                _buildInfoChip(
                                  Icons.work_outline,
                                  widget.offer.type,
                                ),
                                _buildInfoChip(
                                  Icons.monetization_on_outlined,
                                  widget.offer.wage,
                                ),
                                _buildInfoChip(
                                  Icons.people_outline,
                                  vacanciesText,
                                ),
                                if (widget.offer.isRemote)
                                  _buildInfoChip(Icons.wifi, "Remoto"),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 35),

                        const Text(
                          "Descripción del Puesto",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            widget.offer.description,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.6,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),

                        // MAPA
                        _buildMapSection(),

                        const SizedBox(
                          height: 100,
                        ), // Espacio para el botón flotante
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ), // cierre Scrollbar
          // 3. BOTÓN FLOTANTE (CON STREAMBUILDER)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: user == null
                ? const SizedBox.shrink()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('applications')
                        .where('offerId', isEqualTo: widget.offer.id)
                        .snapshots(),
                    builder: (context, appsSnapshot) {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: _applicationStream,
                        builder: (context, userAppSnapshot) {
                          if (_isLoading) {
                            return _buildLoadingButton();
                          }

                          bool isApplied =
                              userAppSnapshot.hasData &&
                              userAppSnapshot.data!.exists;
                          int currentApps = appsSnapshot.hasData
                              ? appsSnapshot.data!.docs.length
                              : 0;
                          int vacancies = widget.offer.vacancies;
                          bool isFull =
                              vacancies > 0 && currentApps >= vacancies;

                          // Caso 1: Ya postulado -> Botón Rojo "Retirar"
                          if (isApplied) {
                            return _buildActionButton(
                              label: "RETIRAR POSTULACIÓN",
                              icon: Icons.delete_forever_rounded,
                              color: Colors.redAccent,
                              onPressed: () => _handleApplicationButton(true),
                            );
                          }

                          // Caso 2: No postulado pero oferta LLENA -> Botón Rojo "Lleno"
                          if (isFull) {
                            return _buildActionButton(
                              label: "OFERTA LLENA (SIN CUPOS)",
                              icon: Icons.block_rounded,
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              onPressed: null, // Deshabilitado
                            );
                          }

                          // Caso 3: No postulado y hay cupos -> Botón Naranja "Postularme"
                          return _buildActionButton(
                            label: "POSTULARME AHORA",
                            icon: Icons.rocket_launch_rounded,
                            color: AppTheme.primaryOrange,
                            onPressed: () => _handleApplicationButton(false),
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

  // --- WIDGETS AUXILIARES ---
  Widget _buildLoadingButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const CircularProgressIndicator(color: AppTheme.primaryOrange),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: onPressed == null ? 0 : 10,
          shadowColor: color.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    if (widget.offer.latitude == null || widget.offer.longitude == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ubicación Exacta",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  widget.offer.latitude!,
                  widget.offer.longitude!,
                ),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.unimet.intership_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        widget.offer.latitude!,
                        widget.offer.longitude!,
                      ),
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.redAccent,
                        size: 45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
