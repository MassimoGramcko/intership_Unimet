import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // --- NUEVOS CONTROLADORES ---
  // Usamos 'name' para Nombres (Estudiante) o Razón Social (Empresa)
  final TextEditingController _nameController = TextEditingController();
  // Este es solo para Apellidos (Estudiante)
  final TextEditingController _lastNameController = TextEditingController();
  // Este es para Cédula o RIF
  final TextEditingController _idDocumentController = TextEditingController();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String? _selectedRole; 
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Podemos mostrar datos diferentes en el mensaje según el rol
      String identification = _selectedRole == 'Empresa' ? 'RIF' : 'Cédula';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro exitoso ($identification: ${_idDocumentController.text})'),
          backgroundColor: const Color(0xFFFF6600),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Variable auxiliar para saber si es empresa y limpiar el código visual
    final isCompany = _selectedRole == 'Empresa';

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Únete a UNIMET Internship',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF003399)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Completa tus datos para comenzar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // 1. SELECTOR DE ROL
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Soy...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'Estudiante', child: Text('Estudiante')),
                    DropdownMenuItem(value: 'Empresa', child: Text('Empresa / Aliado')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                  validator: (value) => value == null ? 'Por favor selecciona tu rol' : null,
                ),
                const SizedBox(height: 20),

                // 2. NOMBRE / RAZÓN SOCIAL
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: isCompany ? 'Razón Social' : 'Nombres',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. APELLIDOS (SOLO SI ES ESTUDIANTE O AÚN NO HA SELECCIONADO)
                // Usamos "Visibility" para ocultar este campo si es Empresa
                Visibility(
                  visible: !isCompany, 
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        // El validador solo funciona si el campo es visible
                        validator: (value) {
                          if (!isCompany && (value == null || value.isEmpty)) {
                            return 'Ingresa tus apellidos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // 4. CÉDULA / RIF (NUEVO CAMPO)
                TextFormField(
                  controller: _idDocumentController,
                  keyboardType: isCompany ? TextInputType.text : TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isCompany ? 'RIF (J-12345678-9)' : 'Cédula de Identidad',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.perm_identity),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Campo obligatorio';
                    // Validación simple para estudiante: solo números
                    if (!isCompany && int.tryParse(value) == null) {
                      return 'La cédula debe contener solo números';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 5. CORREO
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    hintText: 'ejemplo@unimet.edu.ve',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu correo';
                    if (!value.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 6. CONTRASEÑA
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // BOTÓN
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('REGISTRARSE', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}