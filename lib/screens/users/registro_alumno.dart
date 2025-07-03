import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NuevoUsuarioScreen extends StatefulWidget {
  const NuevoUsuarioScreen({super.key});

  @override
  State<NuevoUsuarioScreen> createState() => _NuevoUsuarioScreenState();
}

class _NuevoUsuarioScreenState extends State<NuevoUsuarioScreen> {
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

  Future<void> _registrarUsuario() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final correo = _correoController.text.trim();
    final telefono = _telefonoController.text.trim();
    final password = _passwordController.text.trim();
    final fotoUrl = _fotoUrlController.text.trim();
    final matricula = int.tryParse(_matriculaController.text.trim());
    final nota = _notaController.text.trim();
    final presentate = _presentateController.text.trim();
    final redesSociales = _redesController.text.trim();

    if (nombre.isEmpty ||
        apellido.isEmpty ||
        correo.isEmpty ||
        password.isEmpty ||
        matricula == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan campos obligatorios')),
      );
      return;
    }

    try {
      await supabase.from('usuarios').insert({
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'telefono': telefono.isNotEmpty ? telefono : null,
        'password': password,
        'foto_url': fotoUrl.isNotEmpty ? fotoUrl : null,
        'matricula': matricula,
        'nota': nota.isNotEmpty ? nota : null,
        'presentate': presentate.isNotEmpty ? presentate : null,
        'autoriza_datos': _autorizacionDatos,
        'redes_sociales': redesSociales.isNotEmpty ? redesSociales : null,
        // 'rol_id': se deja con valor por defecto
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario registrado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar nuevo usuario'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField('Nombre', _nombreController),
            _buildTextField('Apellido', _apellidoController),
            _buildTextField(
              'Correo',
              _correoController,
              type: TextInputType.emailAddress,
            ),
            _buildTextField(
              'Teléfono',
              _telefonoController,
              type: TextInputType.phone,
            ),
            _buildTextField(
              'Contraseña',
              _passwordController,
              obscure: true,
            ),
            _buildTextField(
              'Matrícula',
              _matriculaController,
              type: TextInputType.number,
            ),
            _buildTextField('URL de foto (opcional)', _fotoUrlController),
            _buildTextField('Nota (opcional)', _notaController),
            _buildTextField(
              'Preséntate (carrera, ciudad, edad...)',
              _presentateController,
              maxLines: 3,
            ),
            CheckboxListTile(
              title: const Text(
                  'Autorizo compartir mis datos personales (teléfono, correo)'),
              value: _autorizacionDatos,
              onChanged: (value) {
                setState(() {
                  _autorizacionDatos = value ?? false;
                });
              },
            ),
            _buildTextField(
              'Redes sociales (link opcional)',
              _redesController,
              type: TextInputType.url,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registrarUsuario,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
