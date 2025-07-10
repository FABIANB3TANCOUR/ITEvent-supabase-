import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddActividadScreen extends StatefulWidget {
  final int idEvento;
  const AddActividadScreen({super.key, required this.idEvento});

  @override
  State<AddActividadScreen> createState() => _AddActividadScreenState();
}

class _AddActividadScreenState extends State<AddActividadScreen> {
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
  bool _isLoading = false;

  Future<void> _insertarActividad() async {
    if (_fecha == null || _horaInicio == null || _horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa fecha y horario.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.from('actividad').insert({
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
        'id_evento': widget.idEvento,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actividad registrada correctamente')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
    } finally {
      setState(() => _isLoading = false);
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
        title: const Text('Agregar Actividad'),
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
                                      (_, __, ___) => const Text(
                                        'No se pudo cargar la portada',
                                      ),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _pickHora(esInicio: true),
                                    child: const Text('Hora Inicio'),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _horaInicio?.format(context) ??
                                        'No definido',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _pickHora(esInicio: false),
                                    child: const Text('Hora Fin'),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _horaFin?.format(context) ?? 'No definido',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _insertarActividad,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3966CC),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text(
                              'Registrar Actividad',
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
    _descripcionController.dispose();
    _capacidadController.dispose();
    _lugarController.dispose();
    _lugarUrlController.dispose();
    _portadaUrlController.dispose();
    super.dispose();
  }
}
