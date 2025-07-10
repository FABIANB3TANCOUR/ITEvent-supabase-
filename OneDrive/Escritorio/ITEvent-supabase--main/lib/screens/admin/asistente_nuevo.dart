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

  List<dynamic> _roles = [];
  int? _rolSeleccionado;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final data = await supabase.from('roles').select('id, nombre');

      setState(() {
        _roles = data;
        _isLoading = false; // <- IMPORTANTE para salir del cargando
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar roles: $e')));
    }
  }

  Future<void> _crearUsuario() async {
    try {
      await supabase.from('usuarios').insert({
        'matricula': int.tryParse(_matriculaController.text),
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'correo': _correoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'password': _passwordController.text.trim(),
        'foto_url': _fotoUrlController.text.trim(),
        'rol_id': _rolSeleccionado,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear usuario: $e')));
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: type ?? TextInputType.text,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuevo Usuario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Container(
                        width: 400,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              'Matricula',
                              _matriculaController,
                              type: TextInputType.number,
                            ),
                            _buildTextField('Nombre', _nombreController),
                            _buildTextField('Apellido', _apellidoController),
                            _buildTextField(
                              'Correo',
                              _correoController,
                              type: TextInputType.emailAddress,
                            ),
                            _buildTextField(
                              'Telefono',
                              _telefonoController,
                              type: TextInputType.phone,
                            ),
                            _buildTextField('Password', _passwordController),
                            _buildTextField('Foto URL', _fotoUrlController),

                            const SizedBox(height: 10),
                            const Text(
                              'Rol:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            _roles.isEmpty
                                ? const Text('No hay roles disponibles')
                                : DropdownButton<int>(
                                  isExpanded: true,
                                  value: _rolSeleccionado,
                                  hint: const Text('Selecciona un rol'),
                                  items:
                                      _roles
                                          .map<DropdownMenuItem<int>>(
                                            (rol) => DropdownMenuItem(
                                              value: rol['id'],
                                              child: Text(rol['nombre']),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _rolSeleccionado = value;
                                    });
                                  },
                                ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _crearUsuario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3966CC),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Agregar Usuario',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
