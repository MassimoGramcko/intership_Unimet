import 'package:flutter/material.dart';
import '../config/theme.dart';

class CreateOfferScreen extends StatefulWidget {
  // Variables opcionales para cuando queremos EDITAR
  final String? currentTitle;
  final String? currentCompany;
  final String? currentDescription;

  const CreateOfferScreen({
    super.key, 
    this.currentTitle, 
    this.currentCompany,
    this.currentDescription
  });

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  // Controladores para manejar el texto
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    // Si recibimos datos (Editar), los ponemos en el controlador. Si no, texto vacío (Crear).
    _titleController = TextEditingController(text: widget.currentTitle ?? "");
    _companyController = TextEditingController(text: widget.currentCompany ?? "");
    _descController = TextEditingController(text: widget.currentDescription ?? "");
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si tenemos título, estamos EDITANDO. Si no, estamos CREANDO.
    final isEditing = widget.currentTitle != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Título dinámico
        title: Text(
          isEditing ? "Editar Oferta" : "Nueva Oferta", 
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Información de la Pasantía", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)
            ),
            const SizedBox(height: 20),
            
            // Usamos los controladores en cada campo
            _buildTextField("Título del Puesto", "Ej: Auditor Junior", controller: _titleController),
            const SizedBox(height: 16),
            _buildTextField("Empresa", "Ej: KPMG", controller: _companyController),
            const SizedBox(height: 16),
            _buildTextField("Ubicación", "Ej: Caracas - Las Mercedes"), // Podrías agregar controlador aquí también
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildTextField("Modalidad", "Ej: Híbrido")),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField("Duración", "Ej: 6 meses")),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField("Descripción", "Detalles de la oferta...", maxLines: 4, controller: _descController),
            const SizedBox(height: 16),
            _buildTextField("Requisitos", "Lista de requisitos...", maxLines: 3),
            
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEditing ? "Cambios guardados" : "Oferta publicada")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEditing ? "Guardar Cambios" : "Publicar Oferta", 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Actualizamos el widget para aceptar el controlador
  Widget _buildTextField(String label, String hint, {int maxLines = 1, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // Asignamos el controlador aquí
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
      ],
    );
  }
}