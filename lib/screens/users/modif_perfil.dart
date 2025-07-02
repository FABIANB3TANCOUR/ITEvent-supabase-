import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final supabase = Supabase.instance.client;

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fotoUrlController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _notaController = TextEditingController();
  final _presentateController = TextEditingController();
  final _redesController = TextEditingController();

  bool _autorizacionDatos = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final matricula = prefs.getInt('matricula');
    if (matricula == null) return;

    final data = await supabase
        .from('usuarios')
        .select()
        .eq('matricula', matricula)
        .maybeSingle();

    if (data != null) {
      _nombreController.text = data['nombre'] ?? '';
      _apellidoController.text = data['apellido'] ?? '';
      _correoController.text = data['correo'] ?? '';
      _telefonoController.text = data['telefono'] ?? '';
      _fotoUrlController.text = data['foto_url'] ?? '';
      _notaController.text = data['nota'] ?? '';
      _matriculaController.text = data['matricula']?.toString() ?? '';
      _presentateController.text = data['presentate'] ?? '';
      _redesController.text = data['redes_sociales'] ?? '';
      _autorizacionDatos = data['autoriza_datos'] ?? false;

      setState(() {});
    }
  }

  Future<void> _guardarCambios() async {
    final prefs = await SharedPreferences.getInstance();
    final matricula = prefs.getInt('matricula');
    if (matricula == null) return;

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'correo': _correoController.text.trim(),
        'telefono': _telefonoController.text.trim().isNotEmpty
            ? _telefonoController.text.trim()
            : null,
        'foto_url': _fotoUrlController.text.trim().isNotEmpty
            ? _fotoUrlController.text.trim()
            : null,
        'nota': _notaController.text.trim().isNotEmpty
            ? _notaController.text.trim()
            : null,
        'presentate': _presentateController.text.trim().isNotEmpty
            ? _presentateController.text.trim()
            : null,
        'redes_sociales': _redesController.text.trim().isNotEmpty
            ? _redesController.text.trim()
            : null,
        'autoriza_datos': _autorizacionDatos,
      };

      if (_passwordController.text.trim().isNotEmpty) {
        updateData['contraseña'] = _passwordController.text.trim();
      }

      await supabase.from('usuarios').update(updateData).eq('matricula', matricula);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: maxLines,
        readOnly: readOnly,
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
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF162A87), Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    width: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField('Matrícula', _matriculaController, readOnly: true),
                        _buildTextField('Nombre', _nombreController),
                        _buildTextField('Apellido', _apellidoController),
                        _buildTextField('Correo', _correoController),
                        _buildTextField('Teléfono', _telefonoController),
                        _buildTextField('Nota', _notaController, maxLines: 3),
                        _buildTextField('Presentación (opcional)', _presentateController, maxLines: 3),
                        _buildTextField('Redes sociales (opcional)', _redesController),
                        _buildTextField('Nueva Contraseña (opcional)', _passwordController, obscure: true),
                        const Text(
                          'Foto de perfil (opcional):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _fotoUrlController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'URL de foto',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_fotoUrlController.text.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Image.network(
                                _fotoUrlController.text.trim(),
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Text(
                                  'No se pudo cargar la imagen',
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _autorizacionDatos,
                              onChanged: (value) {
                                setState(() {
                                  _autorizacionDatos = value ?? false;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Autorizo mostrar mi número de teléfono y correo electrónico públicamente.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _guardarCambios,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3966CC),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text(
                            'Guardar Cambios',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _fotoUrlController.dispose();
    _matriculaController.dispose();
    _notaController.dispose();
    _presentateController.dispose();
    _redesController.dispose();
    super.dispose();
  }
}
