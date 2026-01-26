import 'package:flutter/material.dart';

class CreateOfferScreen extends StatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  // 1. CONTROLADORES PARA CAPTURAR EL TEXTO
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    // Limpieza de memoria
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva Vacante"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF003399),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Detalles del Puesto",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003399)),
            ),
            const Text(
              "Completa la información para atraer a los mejores estudiantes.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // USAMOS LOS CONTROLADORES EN CADA CAMPO
            _buildTextField("Título del Puesto", "Ej. Desarrollador Web Junior", Icons.work_outline, _titleController),
            const SizedBox(height: 20),
            _buildTextField("Nombre de la Empresa", "Ej. Tech Solutions", Icons.business, _companyController),
            const SizedBox(height: 20),
            _buildTextField("Ubicación / Modalidad", "Ej. Caracas (Remoto)", Icons.location_on_outlined, _locationController),
            const SizedBox(height: 20),
            _buildTextField("Descripción de la Oferta", "Describe las responsabilidades...", Icons.description_outlined, _descriptionController, maxLines: 5),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // 2. VALIDACIÓN BÁSICA
                  if (_titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Por favor escribe al menos el título")),
                    );
                    return;
                  }

                  // 3. EMPAQUETAR LOS DATOS
                  final newOffer = {
                    'title': _titleController.text,
                    'candidates': "0 postulantes", // Empieza vacía
                    'isActive': true,
                  };

                  // 4. DEVOLVER DATOS Y CERRAR
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("¡Oferta publicada exitosamente!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Aquí pasamos 'newOffer' de vuelta a la pantalla anterior
                  Navigator.pop(context, newOffer); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "PUBLICAR OFERTA",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // Asignamos el controlador aquí
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }
}