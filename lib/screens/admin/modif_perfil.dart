import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModifPerfil extends StatefulWidget {
  const ModifPerfil({Key? key}) : super(key: key);

  @override
  _ModifPerfilState createState() => _ModifPerfilState();
}

class _ModifPerfilState extends State<ModifPerfil> {
  final supabase = Supabase.instance.client;

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();

  bool _isLoading = false;
  int? _adminId;

  @override
  void initState() {
    super.initState();
    _inicializarPerfil();
  }

  Future<void> _inicializarPerfil() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getInt('adminId');

    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el ID del admin')),
      );
      setState(() => _isLoading = false);
      return;
    }

    _adminId = adminId;
    await _cargarDatos();
    setState(() => _isLoading = false);
  }

  Future<void> _cargarDatos() async {
    final adminId = _adminId; // Copia a una variable local

    if (adminId == null) return; // Asegúrate de que no sea null

    try {
      final data =
          await supabase
              .from('administradores')
              .select()
              .eq('id', adminId) // Ya no hay error porque es no-null aquí
              .maybeSingle();

      if (data != null) {
        _nombreController.text = data['nombre'] ?? '';
        _correoController.text = data['correo'] ?? '';
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $error')));
    }
  }

  Future<void> _guardarPerfil() async {
    final adminId = _adminId; // <- variable local
    if (adminId == null) return;

    setState(() => _isLoading = true);

    try {
      await supabase
          .from('administradores')
          .update({
            'nombre': _nombreController.text,
            'correo': _correoController.text,
          })
          .eq('id', adminId)
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
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos personales',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Nombre', _nombreController),
                      _buildTextField('Correo', _correoController),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3966CC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
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
    _nombreController.dispose();
    _correoController.dispose();
    super.dispose();
  }
}
