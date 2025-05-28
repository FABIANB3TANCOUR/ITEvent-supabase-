import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModifPerfil extends StatefulWidget {
  final int adminId;
  final String rol; // 'staff' o 'invitado'

  const ModifPerfil({
    super.key,
    required this.adminId,
    required this.rol,
  });

  @override
  State<ModifPerfil> createState() => _ModifPerfilState();
}

class _ModifPerfilState extends State<ModifPerfil> {
  final supabase = Supabase.instance.client;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _fotoUrlController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final tabla = widget.rol == 'staff' ? 'organizadores' : 'usuarios';

    final response = await supabase
        .from(tabla)
        .select('nombre, correo, foto_url')
        .eq('id', widget.adminId)
        .maybeSingle();

    if (response != null) {
      _nombreController.text = response['nombre'] ?? '';
      _correoController.text = response['correo'] ?? '';
      _fotoUrlController.text = response['foto_url'] ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _guardarCambios() async {
    final tabla = widget.rol == 'staff' ? 'organizadores' : 'usuarios';

    try {
      await supabase.from(tabla).update({
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'foto_url': _fotoUrlController.text.trim(),
      }).eq('id', widget.adminId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fotoUrlController,
              decoration: const InputDecoration(labelText: 'Foto URL'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardarCambios,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
