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
  final _correoController = TextEditingController();
  final _fotoUrlController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getInt('adminId');
    if (adminId == null) return;

    final data =
        await supabase
            .from('administradores')
            .select()
            .eq('id', adminId)
            .maybeSingle();

    if (data != null) {
      _nombreController.text = data['nombre'] ?? '';
      _correoController.text = data['correo'] ?? '';
      _fotoUrlController.text = data['foto_url'] ?? '';
      // No se debe cargar la contraseña por seguridad
    }
  }

  Future<void> _guardarCambios() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getInt('adminId');
    if (adminId == null) return;

    setState(() => _isLoading = true);

    try {
      final updateData = {
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'foto_url': _fotoUrlController.text.trim(),
      };

      // Solo actualizar password si se escribió una nueva
      if (_passwordController.text.trim().isNotEmpty) {
        updateData['password'] = _passwordController.text.trim();
      }

      await supabase
          .from('administradores')
          .update(updateData)
          .eq('id', adminId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
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
        child:
            _isLoading
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
                          _buildTextField('Nombre', _nombreController),
                          _buildTextField('Correo', _correoController),
                          _buildTextField(
                            'Nueva Contraseña (opcional)',
                            _passwordController,
                            obscure: true,
                          ),
                          const Text(
                            'Foto de perfil:',
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
                          if (_fotoUrlController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Image.network(
                                  _fotoUrlController.text,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => const Text(
                                        'No se pudo cargar la imagen',
                                      ),
                                ),
                              ),
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
    _correoController.dispose();
    _fotoUrlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
