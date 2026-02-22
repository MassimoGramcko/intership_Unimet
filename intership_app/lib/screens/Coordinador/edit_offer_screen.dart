import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditOfferScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const EditOfferScreen({super.key, required this.docId, required this.currentData});

  @override
  State<EditOfferScreen> createState() => _EditOfferScreenState();
}

class _EditOfferScreenState extends State<EditOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos de texto
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _wageController;
  late TextEditingController _descriptionController;

  // Variables de estado para selectores
  String _selectedModality = 'Presencial';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    // Cargar los datos actuales en los controladores
    _titleController = TextEditingController(text: widget.currentData['title'] ?? '');
    _companyController = TextEditingController(text: widget.currentData['company'] ?? '');
    _locationController = TextEditingController(text: widget.currentData['location'] ?? '');
    _wageController = TextEditingController(text: widget.currentData['wage'] ?? '');
    _descriptionController = TextEditingController(text: widget.currentData['description'] ?? '');
    
    _selectedModality = widget.currentData['modality'] ?? 'Presencial';
    _isActive = widget.currentData['isActive'] ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _wageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateOffer() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('job_offers').doc(widget.docId).update({
          'title': _titleController.text.trim(),
          'company': _companyController.text.trim(),
          'location': _locationController.text.trim(),
          'wage': _wageController.text.trim(),
          'description': _descriptionController.text.trim(),
          'modality': _selectedModality,
          'isActive': _isActive,
          // 'updatedAt': FieldValue.serverTimestamp(), // Opcional: si quieres rastrear ediciones
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Oferta actualizada con éxito!")),
          );
          Navigator.pop(context); // Volver atrás
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: $e")),
        );
      }
    }
  }

  Future<void> _deleteOffer() async {
    // Diálogo de confirmación extra por seguridad
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("¿Eliminar definitivamente?", style: TextStyle(color: Colors.white)),
        content: const Text("Esta acción no se puede deshacer.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text("Cancelar"), 
            onPressed: () => Navigator.pop(context, false)
          ),
          TextButton(
            child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent)), 
            onPressed: () => Navigator.pop(context, true)
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('job_offers').doc(widget.docId).delete();
      if (mounted) Navigator.pop(context); // Cierra la pantalla de editar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Editar Oferta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.3,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Información General"),
                const SizedBox(height: 15),
                _buildCustomTextField(controller: _titleController, label: "Título del Puesto", icon: Icons.work_outline),
                const SizedBox(height: 15),
                _buildCustomTextField(controller: _companyController, label: "Empresa", icon: Icons.business_rounded),
                
                const SizedBox(height: 30),
                _buildSectionTitle("Detalles del Trabajo"),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildCustomTextField(controller: _locationController, label: "Ubicación", icon: Icons.location_on_outlined)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildDropdownModality()),
                  ],
                ),
                const SizedBox(height: 15),
                _buildCustomTextField(controller: _wageController, label: "Remuneración (Opcional)", icon: Icons.attach_money_rounded),
                
                const SizedBox(height: 30),
                _buildSectionTitle("Descripción"),
                const SizedBox(height: 15),
                _buildCustomTextField(controller: _descriptionController, label: "Descripción detallada", icon: Icons.description_outlined, maxLines: 5),

                const SizedBox(height: 30),
                _buildSectionTitle("Estado de la Oferta"),
                const SizedBox(height: 10),
                _buildSwitchTile(),

                const SizedBox(height: 50),
                
                // --- BOTÓN GUARDAR ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _updateOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 10,
                      shadowColor: Colors.orangeAccent.withOpacity(0.4),
                    ),
                    child: const Text("Guardar Cambios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 20),

                // --- BOTÓN ELIMINAR (Lo que pediste) ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: TextButton.icon(
                    onPressed: _deleteOffer,
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    label: const Text("Eliminar Oferta", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0, textBaseline: TextBaseline.alphabetic),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        validator: (value) => value!.isEmpty ? "Campo requerido" : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white54),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownModality() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedModality,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
          style: const TextStyle(color: Colors.white),
          items: ["Presencial", "Remoto", "Híbrido"].map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedModality = val!),
        ),
      ),
    );
  }

  Widget _buildSwitchTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _isActive ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _isActive ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isActive ? "Oferta Visible (Activa)" : "Oferta Oculta (Inactiva)",
            style: TextStyle(
              color: _isActive ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          Switch(
            value: _isActive,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.greenAccent,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.redAccent.withOpacity(0.5),
            onChanged: (val) => setState(() => _isActive = val),
          ),
        ],
      ),
    );
  }
}