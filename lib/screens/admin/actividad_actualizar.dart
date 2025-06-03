import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditActividadScreen extends StatefulWidget {
  final int actividadId;

  const EditActividadScreen({super.key, required this.actividadId});

  @override
  State<EditActividadScreen> createState() => _EditActividadScreenState();
}

class _EditActividadScreenState extends State<EditActividadScreen> {
  final supabase = Supabase.instance.client;

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _capacidadController = TextEditingController();
  final _lugarController = TextEditingController();
  final _lugarUrlController = TextEditingController();
  final _portadaUrlController = TextEditingController();

  DateTime? _fecha;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActividad();
  }

  Future<void> _loadActividad() async {
    try {
      final data =
          await supabase
              .from('actividad')
              .select()
              .eq('id', widget.actividadId)
              .maybeSingle();

      if (data != null) {
        _nombreController.text = data['nombre'] ?? '';
        _descripcionController.text = data['descripcion'] ?? '';
        _capacidadController.text = (data['capacidad'] ?? '').toString();
        _lugarController.text = data['lugar'] ?? '';
        _lugarUrlController.text = data['lugar_url'] ?? '';
        _portadaUrlController.text = data['portada_url'] ?? '';
        _fecha = DateTime.tryParse(data['fecha']);
        _horaInicio = TimeOfDay.fromDateTime(
          DateTime.parse('2000-01-01T${data['hora_inicio']}'),
        );
        _horaFin = TimeOfDay.fromDateTime(
          DateTime.parse('2000-01-01T${data['hora_fin']}'),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la actividad: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _updateActividad() async {
    if (_fecha == null || _horaInicio == null || _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa fecha y horario.')),
      );
      return;
    }

    try {
      final horaInicioStr = _horaInicio!.format(context);
      final horaFinStr = _horaFin!.format(context);

      await supabase
          .from('actividad')
          .update({
            'nombre': _nombreController.text.trim(),
            'descripcion': _descripcionController.text.trim(),
            'capacidad': int.tryParse(_capacidadController.text) ?? 0,
            'lugar': _lugarController.text.trim(),
            'lugar_url': _lugarUrlController.text.trim(),
            'portada_url': _portadaUrlController.text.trim(),
            'fecha': _fecha!.toIso8601String().split('T').first,
            'hora_inicio':
                '${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}',
            'hora_fin':
                '${_horaFin!.hour.toString().padLeft(2, '0')}:${_horaFin!.minute.toString().padLeft(2, '0')}',
          })
          .eq('id', widget.actividadId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actividad actualizada correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    }
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickHora({required bool esInicio}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          esInicio
              ? (_horaInicio ?? TimeOfDay.now())
              : (_horaFin ?? TimeOfDay.now()),
    );
    if (picked != null)
      setState(() => esInicio ? _horaInicio = picked : _horaFin = picked);
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
        title: const Text('Editar Actividad'),
        backgroundColor: const Color(0xFF3966CC),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Nombre', _nombreController),
                    _buildTextField(
                      'Descripcion',
                      _descripcionController,
                      maxLines: 3,
                    ),
                    _buildTextField('Capacidad', _capacidadController),
                    _buildTextField('Lugar', _lugarController),
                    _buildTextField('URL de lugar', _lugarUrlController),
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Image.network(
                            _portadaUrlController.text,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    const Text('No se pudo cargar la portada'),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _pickFecha,
                          child: const Text('Seleccionar Fecha'),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _fecha != null
                              ? '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}'
                              : 'Sin fecha',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _pickHora(esInicio: true),
                          child: const Text('Hora Inicio'),
                        ),
                        const SizedBox(width: 8),
                        Text(_horaInicio?.format(context) ?? 'No definido'),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => _pickHora(esInicio: false),
                          child: const Text('Hora Fin'),
                        ),
                        const SizedBox(width: 8),
                        Text(_horaFin?.format(context) ?? 'No definido'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateActividad,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3966CC),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text(
                        'Actualizar Actividad',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _capacidadController.dispose();
    _lugarController.dispose();
    _lugarUrlController.dispose();
    _portadaUrlController.dispose();
    super.dispose();
  }
}
