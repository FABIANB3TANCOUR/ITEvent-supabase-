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

      if (data != null) {
        _nombreController.text = data['nombre_evento'] ?? '';
        _descripcionController.text = data['descripcion'] ?? '';
        _cupoController.text = (data['cupo_total'] ?? '').toString();
        _logoUrlController.text = data['logo_url'] ?? '';
        _fechaInicio = DateTime.tryParse(data['fecha_inicio'] ?? '');
        _fechaFin = DateTime.tryParse(data['fecha_fin'] ?? '');
      }
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
            'fecha_inicio': _fechaInicio!.toIso8601String(),
            'fecha_fin': _fechaFin!.toIso8601String(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
        title: const Text(
          'Editar Evento',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                    children: [
                      _buildTextField('Nombre del evento', _nombreController),
                      _buildTextField(
                        'Descripción',
                        _descripcionController,
                        maxLines: 4,
                      ),
                      _buildTextField(
                        'Cupo total',
                        _cupoController,
                        type: TextInputType.number,
                      ),
                      _buildTextField('Logo URL', _logoUrlController),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.date_range),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _pickDate(isInicio: true),
                            child: Text(
                              _fechaInicio == null
                                  ? 'Seleccionar fecha de inicio'
                                  : 'Inicio: ${_fechaInicio!.toLocal()}'.split(
                                    ' ',
                                  )[0],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.date_range),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _pickDate(isInicio: false),
                            child: Text(
                              _fechaFin == null
                                  ? 'Seleccionar fecha de fin'
                                  : 'Fin: ${_fechaFin!.toLocal()}'.split(
                                    ' ',
                                  )[0],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _updateEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3966CC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Guardar Cambios',
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
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _cupoController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }
}
