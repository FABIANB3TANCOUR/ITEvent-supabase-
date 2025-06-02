import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditEventScreen extends StatefulWidget {
  final int eventId;

  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final supabase = Supabase.instance.client;

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cupoController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _portadaUrlController = TextEditingController();
  final _estadoController = TextEditingController();
  final _municipioController = TextEditingController();
  List<dynamic> _organizadores = [];
  int? _organizadorSeleccionado;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      final data =
          await supabase
              .from('eventos')
              .select()
              .eq('id', widget.eventId)
              .maybeSingle();

      final organizadoresData = await supabase
          .from('organizadores')
          .select('id, nombre');

      if (data != null) {
        _nombreController.text = data['nombre_evento'] ?? '';
        _descripcionController.text = data['descripcion'] ?? '';
        _cupoController.text = (data['cupo_total'] ?? '').toString();
        _logoUrlController.text = data['logo_url'] ?? '';
        _portadaUrlController.text = data['portada_url'] ?? '';
        _estadoController.text = data['estado'] ?? '';
        _municipioController.text = data['municipio'] ?? '';
        _organizadorSeleccionado = data['organizador_id'];
        _fechaInicio = DateTime.tryParse(data['fecha_inicio'] ?? '');
        _fechaFin = DateTime.tryParse(data['fecha_fin'] ?? '');
      }

      _organizadores = organizadoresData;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar el evento: $e')));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateEvent() async {
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona ambas fechas.')));
      return;
    }

    try {
      await supabase
          .from('eventos')
          .update({
            'nombre_evento': _nombreController.text,
            'descripcion': _descripcionController.text,
            'cupo_total': int.tryParse(_cupoController.text) ?? 0,
            'logo_url': _logoUrlController.text,
            'portada_url': _portadaUrlController.text,
            'fecha_inicio': _fechaInicio!.toIso8601String(),
            'fecha_fin': _fechaFin!.toIso8601String(),
            'estado': _estadoController.text,
            'municipio': _municipioController.text,
            'organizador_id': _organizadorSeleccionado,
          })
          .eq('id', widget.eventId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento actualizado correctamente')),
        );
        Navigator.pop(context, true); // Para refrescar si lo necesitas
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    }
  }

  Future<void> _pickDate({required bool isInicio}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          isInicio
              ? (_fechaInicio ?? DateTime.now())
              : (_fechaFin ?? DateTime.now()),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modificar datos',
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        width: 400,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Agregar imagen o logo:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 20),
                            const Text(
                              'Agregar imagen de portada:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
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

                            const SizedBox(height: 10),
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
                              onPressed: _updateEvent,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3966CC),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Actualizar',
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

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _cupoController.dispose();
    _logoUrlController.dispose();
    _portadaUrlController.dispose();
    super.dispose();
  }
}
