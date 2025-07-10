import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddNotificacionScreen extends StatefulWidget {
  const AddNotificacionScreen({super.key});

  @override
  State<AddNotificacionScreen> createState() => _AddNotificacionScreenState();
}

class _AddNotificacionScreenState extends State<AddNotificacionScreen> {
  final supabase = Supabase.instance.client;
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _logoUrlController = TextEditingController();

  bool _isLoading = false;

  Future<void> _insertarNotificacion() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El titulo es obligatorio')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('notificaciones').insert({
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'logo_url': _logoUrlController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificacion registrada')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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
        title: const Text('Agregar Notificacion'),
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
                          _buildTextField('Titulo', _tituloController),
                          _buildTextField(
                            'Descripcion',
                            _descripcionController,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Agregar logo de la notificacion:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _logoUrlController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'URL de imagen',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (_logoUrlController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Image.network(
                                  _logoUrlController.text,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => const Text(
                                        'No se pudo cargar el logo',
                                      ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _insertarNotificacion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3966CC),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text(
                              'Registrar Notificacion',
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
    _tituloController.dispose();
    _descripcionController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }
}
