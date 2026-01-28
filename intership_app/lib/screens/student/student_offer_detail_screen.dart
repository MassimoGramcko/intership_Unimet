import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentOfferDetailScreen extends StatefulWidget {
  final String offerId;
  final Map<String, dynamic> data;

  const StudentOfferDetailScreen({
    super.key,
    required this.offerId,
    required this.data,
  });

  @override
  State<StudentOfferDetailScreen> createState() => _StudentOfferDetailScreenState();
}

class _StudentOfferDetailScreenState extends State<StudentOfferDetailScreen> {
  bool _isApplying = false;

  void _applyToJob() async {
    setState(() {
      _isApplying = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Verificar si ya se postuló antes (opcional, pero buena práctica)
      final existingApp = await FirebaseFirestore.instance
          .collection('applications')
          .where('offerId', isEqualTo: widget.offerId)
          .where('studentId', isEqualTo: user.uid)
          .get();

      if (existingApp.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ya te has postulado a esta oferta anteriormente."), backgroundColor: Colors.orange),
          );
          setState(() => _isApplying = false);
        }
        return;
      }

      // 2. Guardar la postulación en la colección 'applications'
      await FirebaseFirestore.instance.collection('applications').add({
        'offerId': widget.offerId,
        'offerTitle': widget.data['title'],
        'company': widget.data['company'],
        'studentId': user.uid,
        'status': 'En revisión', // Estado inicial
        'appliedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Postulación enviada con éxito! 🚀"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volver al inicio
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al postular: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['company'] ?? "Detalle"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono grande
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.business, size: 40, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            
            // Título
            Text(
              widget.data['title'] ?? "Puesto sin título",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.data['company'] ?? "Empresa",
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            
            const Divider(height: 40),
            
            const Text(
              "Descripción del puesto",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.data['description'] ?? "Sin descripción disponible.",
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
            
            // Botón Postularme
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isApplying ? null : _applyToJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isApplying 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("POSTULARME AHORA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}