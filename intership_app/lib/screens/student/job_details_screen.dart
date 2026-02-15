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

  // --- 1. LÓGICA PRINCIPAL (POSTULAR O RETIRAR) ---
  Future<void> _handleApplicationButton(bool isApplied) async {
    if (user == null) return;

    // ID ÚNICO: Combina ID estudiante + ID oferta
    final String applicationId = '${user!.uid}_${widget.offer.id}';
    final docRef = FirebaseFirestore.instance.collection('applications').doc(applicationId);

    if (isApplied) {
      // --- CASO A: YA ESTÁ POSTULADO -> RETIRAR ---
      // Mostramos alerta de confirmación
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text("Retirar Postulación", style: TextStyle(color: Colors.white)),
          content: const Text(
            "¿Estás seguro de que deseas cancelar tu postulación a esta oferta? Perderás tu lugar.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Retirar", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          await docRef.delete(); // BORRA EL DOCUMENTO
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Has retirado tu postulación."), backgroundColor: Colors.orange),
            );
          }
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
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        final userData = userDoc.data() ?? {};

        // Usamos .set() en lugar de .add() para usar nuestro ID personalizado
        await docRef.set({
          'offerId': widget.offer.id,
          'jobTitle': widget.offer.title,
          'company': widget.offer.company,
          'studentId': user!.uid,
          'studentName': "${userData['firstName'] ?? 'Estudiante'} ${userData['lastName'] ?? ''}",
          'studentEmail': userData['email'] ?? user!.email,
          'status': 'Pendiente',
          'appliedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ ¡Solicitud enviada con éxito!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        _showError("Error al postularse: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ID del documento para escuchar cambios en tiempo real
    final String applicationId = user != null ? '${user!.uid}_${widget.offer.id}' : 'guest';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. HEADER (Igual a tu código)
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

                      // MAPA
                      _buildMapSection(),

                      const SizedBox(height: 100), // Espacio para el botón flotante
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. BOTÓN FLOTANTE (CON STREAMBUILDER)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .doc(applicationId)
                  .snapshots(),
              builder: (context, snapshot) {
                // Verificar si existe el documento
                bool isApplied = snapshot.hasData && snapshot.data!.exists;
                
                // Si está cargando la acción del botón
                if (_isLoading) {
                  return SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const CircularProgressIndicator(color: AppTheme.primaryOrange),
                    ),
                  );
                }

                return SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => _handleApplicationButton(isApplied),
                    style: ElevatedButton.styleFrom(
                      // CAMBIO DE COLOR SEGÚN ESTADO
                      backgroundColor: isApplied ? Colors.redAccent.withOpacity(0.9) : AppTheme.primaryOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 10,
                      shadowColor: (isApplied ? Colors.red : AppTheme.primaryOrange).withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isApplied ? Icons.delete_forever_rounded : Icons.rocket_launch_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          isApplied ? "RETIRAR POSTULACIÓN" : "POSTULARME AHORA",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Igual a tu código) ---
  Widget _buildMapSection() {
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
                      child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 45),
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