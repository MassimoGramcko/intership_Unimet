import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart'; // IMPORTANTE
import 'package:latlong2/latlong.dart';       // IMPORTANTE
import '../../config/theme.dart';
import 'explore_tab.dart'; 

class JobDetailsScreen extends StatefulWidget {
  final JobOffer offer; 

  const JobDetailsScreen({super.key, required this.offer});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isApplying = false;
  bool _hasApplied = false;

  @override
  void initState() {
    super.initState();
    _checkIfApplied();
  }

  void _checkIfApplied() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('applications')
          .where('offerId', isEqualTo: widget.offer.id)
          .where('studentId', isEqualTo: user.uid)
          .get();

      if (query.docs.isNotEmpty && mounted) {
        setState(() => _hasApplied = true);
      }
    } catch (e) {
      print("Error verificando postulación: $e");
    }
  }

  void _applyToJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isApplying = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {}; 

      await FirebaseFirestore.instance.collection('applications').add({
        'offerId': widget.offer.id,
        'jobTitle': widget.offer.title,
        'company': widget.offer.company,
        'studentId': user.uid,
        'studentName': "${userData['firstName'] ?? 'Estudiante'} ${userData['lastName'] ?? ''}",
        'studentEmail': userData['email'] ?? user.email,
        'status': 'Pendiente',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _hasApplied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ ¡Solicitud enviada con éxito!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al postularse: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. HEADER
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppTheme.backgroundDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
                              widget.offer.brandColor.withOpacity(0.8),
                              AppTheme.backgroundDark,
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Hero(
                          tag: "list_${widget.offer.id}", 
                          child: Icon(Icons.business_rounded, size: 80, color: Colors.white.withOpacity(0.9)),
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
                      Text(widget.offer.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(widget.offer.company, style: const TextStyle(color: AppTheme.primaryOrange, fontSize: 18, fontWeight: FontWeight.w500)),
                      
                      const SizedBox(height: 25),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildInfoChip(Icons.location_on_outlined, widget.offer.location),
                          _buildInfoChip(Icons.work_outline, widget.offer.type),
                          _buildInfoChip(Icons.monetization_on_outlined, widget.offer.wage),
                          if (widget.offer.isRemote) _buildInfoChip(Icons.wifi, "Remoto"),
                        ],
                      ),

                      const SizedBox(height: 35),

                      const Text("Descripción del Puesto", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          widget.offer.description,
                          style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15),
                        ),
                      ),
                      
                      const SizedBox(height: 35),

                      // --- NUEVO: SECCIÓN DEL MAPA ---
                      _buildMapSection(),
                      // -------------------------------

                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. BOTÓN FLOTANTE
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: (_hasApplied || _isApplying) ? null : _applyToJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasApplied ? Colors.green.withOpacity(0.8) : AppTheme.primaryOrange,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 10,
                  shadowColor: AppTheme.primaryOrange.withOpacity(0.5),
                ),
                child: _isApplying
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_hasApplied ? Icons.check_circle_rounded : Icons.rocket_launch_rounded, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _hasApplied ? "YA TE HAS POSTULADO" : "POSTULARME AHORA",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DEL MAPA ---
  Widget _buildMapSection() {
    // Si la oferta no tiene coordenadas, no mostramos nada
    if (widget.offer.latitude == null || widget.offer.longitude == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ubicación Exacta", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(widget.offer.latitude!, widget.offer.longitude!),
                initialZoom: 15.0,
                // Bloqueamos la interacción para que no interrumpa el scroll de la página
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.unimet.intership_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(widget.offer.latitude!, widget.offer.longitude!),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}