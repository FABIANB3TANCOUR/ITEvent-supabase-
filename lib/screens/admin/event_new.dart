import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NuevoEventoScreen extends StatefulWidget {
  const NuevoEventoScreen({super.key});

  @override
  State<NuevoEventoScreen> createState() => _NuevoEventoScreenState();
}

class _NuevoEventoScreenState extends State<NuevoEventoScreen> {
  final supabase = Supabase.instance.client;

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cupoController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _portadaUrlController = TextEditingController();
  final _estadoController = TextEditingController();
  final _municipioController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  List<dynamic> _organizadores = [];
  int? _organizadorSeleccionado;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizadores();
  }

  String? limpiarTexto(TextEditingController controller) {
    final texto = controller.text.trim();
    return texto.isEmpty ? null : texto;
  }

  Future<void> _loadOrganizadores() async {
    try {
      final data = await supabase.from('organizadores').select('id, nombre');
      _organizadores = data;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar organizadores: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createEvent() async {
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona ambas fechas.')));
      return;
    }

    try {
      await supabase.from('eventos').insert({
        'nombre_evento': limpiarTexto(_nombreController),
        'descripcion': limpiarTexto(_descripcionController),
        'cupo_total': int.tryParse(_cupoController.text) ?? 0,
        'logo_url': limpiarTexto(_logoUrlController),
        'portada_url': limpiarTexto(_portadaUrlController),
        'fecha_inicio': _fechaInicio?.toIso8601String(),
        'fecha_fin': _fechaFin?.toIso8601String(),
        'estado': limpiarTexto(_estadoController),
        'municipio': limpiarTexto(_municipioController),
        'organizador_id': _organizadorSeleccionado,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento creado correctamente')),
        );
        Navigator.pop(context, true); // volver
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear evento: $e')));
    }
  }

  Future<void> _pickDate({required bool isInicio}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = selected;
        } else {
          _fechaFin = selected;
        }
      });
    }
  }

  Widget _buildDatePicker(String label, bool isInicio) {
    final selectedDate = isInicio ? _fechaInicio : _fechaFin;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(isInicio: isInicio),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedDate != null
                      ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
                      : 'Seleccionar fecha',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? type,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: type ?? TextInputType.text,
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
    _descripcionController.dispose();
    _cupoController.dispose();
    _logoUrlController.dispose();
    _portadaUrlController.dispose();
    _estadoController.dispose();
    _municipioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agregar evento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF3966CC),
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
                            const Text(
                              'Agregar imagen o logo:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextField(
                              controller: _logoUrlController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'URL del logo',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_logoUrlController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Center(
                                  child: Image.network(
                                    _logoUrlController.text,
                                    height: 80,
                                    errorBuilder:
                                        (_, __, ___) => const Text(
                                          'No se pudo cargar la imagen',
                                        ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            const Text(
                              'Agregar imagen de portada:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextField(
                              controller: _portadaUrlController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'URL de portada',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_portadaUrlController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Center(
                                  child: Image.network(
                                    _portadaUrlController.text,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Text(
                                          'No se pudo cargar la portada',
                                        ),
                                  ),
                                ),
                              ),
                            _buildTextField(
                              'Nombre del evento',
                              _nombreController,
                            ),
                            _buildDatePicker('Fecha de inicio', true),
                            _buildDatePicker('Fecha de termino', false),
                            _buildTextField(
                              'Capacidad',
                              _cupoController,
                              type: TextInputType.number,
                            ),
                            _buildTextField(
                              'Descripción',
                              _descripcionController,
                              maxLines: 3,
                            ),
                            _buildTextField('Estado', _estadoController),
                            _buildTextField('Municipio', _municipioController),
                            const SizedBox(height: 10),
                            const Text(
                              'Organizador:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<int>(
                              isExpanded: true,
                              value: _organizadorSeleccionado,
                              hint: const Text('Selecciona un organizador'),
                              items:
                                  _organizadores
                                      .map<DropdownMenuItem<int>>(
                                        (org) => DropdownMenuItem(
                                          value: org['id'],
                                          child: Text(org['nombre']),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _organizadorSeleccionado = value;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _createEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3966CC),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Agregar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Volver',
                                  style: TextStyle(color: Colors.black),
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
