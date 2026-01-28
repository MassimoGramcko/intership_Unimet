import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../admin/create_offer_screen.dart'; // Importamos para poder editar

class OfferDetailScreen extends StatelessWidget {
  const OfferDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detalle de Gestión", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Botón de eliminar en la esquina superior
          IconButton(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Oferta eliminada del sistema")),
               );
               Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CABECERA
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text("K", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Auditor Junior",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "KPMG Venezuela",
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. ETIQUETAS DE ESTADO
                  Row(
                    children: [
                      _buildTag("Activa", Colors.green),
                      const SizedBox(width: 8),
                      _buildTag("Presencial", Colors.grey),
                      const SizedBox(width: 8),
                      _buildTag("Tiempo Completo", Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 24),

                  // 3. INFORMACIÓN
                  _buildSectionTitle("Descripción"),
                  const SizedBox(height: 8),
                  Text(
                    "Esta es la información oficial que verán los estudiantes. El pasante apoyará en la revisión de estados financieros y control interno.",
                    style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 15),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Requisitos Internos"),
                  const SizedBox(height: 8),
                  _buildRequirement("• Estudiante activo de Contaduría."),
                  _buildRequirement("• Excel Avanzado."),
                  _buildRequirement("• Carga académica validada."),
                ],
              ),
            ),
          ),

          // 4. BOTÓN DE EDITAR (Aquí pasamos los datos)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navegar a la pantalla de crear/editar CON DATOS
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateOfferScreen(
                        // PASAMOS LA INFORMACIÓN PARA QUE EL FORMULARIO NO ESTÉ VACÍO
                        currentTitle: "Auditor Junior",
                        currentCompany: "KPMG Venezuela",
                        currentDescription: "Esta es la información oficial que verán los estudiantes. El pasante apoyará en la revisión de estados financieros y control interno.",
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryBlue, // Azul de gestión
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text("Editar Información", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondaryBlue),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
    );
  }
}