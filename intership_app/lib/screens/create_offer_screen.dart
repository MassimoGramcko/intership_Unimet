import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateOfferScreen extends StatefulWidget {
  // Variables opcionales: si llegan, estamos EDITANDO. Si no, estamos CREANDO.
  final String? docId; 
  final String? currentTitle;
  final String? currentCompany;
  final String? currentDescription;

  const CreateOfferScreen({
    super.key,
    this.docId,
    this.currentTitle,
    this.currentCompany,
    this.currentDescription,
  });

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _descriptionController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si recibimos datos (Modo Edición), rellenamos los campos. Si no, los dejamos vacíos.
    _titleController = TextEditingController(text: widget.currentTitle ?? '');
    _companyController = TextEditingController(text: widget.currentCompany ?? '');
    _descriptionController = TextEditingController(text: widget.currentDescription ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveOffer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (widget.docId == null) {
          // --- MODO CREAR: Usamos .add() ---
          await FirebaseFirestore.instance.collection('offers').add({
            'title': _titleController.text.trim(),
            'company': _companyController.text.trim(),
            'description': _descriptionController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });
        } else {
          // --- MODO EDITAR: Usamos .update() ---
          await FirebaseFirestore.instance.collection('offers').doc(widget.docId).update({
            'title': _titleController.text.trim(),
            'company': _companyController.text.trim(),
            'description': _descriptionController.text.trim(),
            // No actualizamos createdAt para mantener la fecha original
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.docId == null ? '¡Oferta creada!' : '¡Oferta actualizada!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Volver atrás
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cambiamos el título de la barra según el modo
    final isEditing = widget.docId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Pasantía" : "Nueva Pasantía"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  isEditing ? "Editar Detalles" : "Detalles de la Oferta",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 20),
                
                // Título
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Título del Puesto",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
                ),
                const SizedBox(height: 15),

                // Empresa
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: "Empresa",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
                ),
                const SizedBox(height: 15),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Descripción y Requisitos",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
                ),
                const SizedBox(height: 30),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _saveOffer,
                        icon: const Icon(Icons.save),
                        label: Text(
                          isEditing ? "GUARDAR CAMBIOS" : "PUBLICAR OFERTA", 
                          style: const TextStyle(fontSize: 16)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}