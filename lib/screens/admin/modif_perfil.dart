import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModifPerfil extends StatefulWidget {
  final int adminId;
  const ModifPerfil({Key? key, required this.adminId}) : super(key: key);

  @override
  _ModifPerfilState createState() => _ModifPerfilState();
}

class _ModifPerfilState extends State<ModifPerfil> {
  final supabase = Supabase.instance.client;

  final _telefonoController = TextEditingController();
  final _celularController = TextEditingController();
  final _correoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _linkedinController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final data = await supabase
          .from('administradores')
          .select()
          .eq('id', widget.adminId)
          .maybeSingle();

      if (data != null) {
        _telefonoController.text = data['telefono'] ?? '';
        _celularController.text = data['celular'] ?? '';
        _correoController.text = data['correo'] ?? '';
        _direccionController.text = data['direccion'] ?? '';
        _linkedinController.text = data['linkedin'] ?? '';
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $error')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _guardarPerfil() async {
  setState(() => _isLoading = true);

  try {
    await supabase
        .from('administradores')
        .update({
          'telefono': _telefonoController.text,
          'celular': _celularController.text,
          'correo': _correoController.text,
          'direccion': _direccionController.text,
          'linkedin': _linkedinController.text,
        })
        .eq('id', widget.adminId)
        .select()
        .single();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado con éxito')),
    );
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al actualizar perfil: $error')),
    );
  }

  setState(() => _isLoading = false);
}


  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
        title: const Text(
          'Mi información de contacto',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mi información de contacto',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Esta información es privada a menos que intercambiemos información de contacto con alguien.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField('Número de teléfono', _telefonoController),
                    _buildTextField('Número de celular', _celularController),
                    _buildTextField('Correo', _correoController),
                    _buildTextField('Dirección', _direccionController),
                    _buildTextField('LinkedIn', _linkedinController),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3966CC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                        ),
                        onPressed: _guardarPerfil,
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _celularController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }
}
