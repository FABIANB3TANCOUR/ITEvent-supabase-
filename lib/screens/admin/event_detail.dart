import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'event_edit.dart';

class EventDetailAdmin extends StatefulWidget {
  final int eventId;

  const EventDetailAdmin({super.key, required this.eventId});

  @override
  State<EventDetailAdmin> createState() => _EventDetailAdminState();
}

class _EventDetailAdminState extends State<EventDetailAdmin> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventDetail();
  }

  Future<void> _loadEventDetail() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await supabase
              .from('eventos')
              .select('''
            id,
            nombre_evento,
            cupo_total,
            fecha_inicio,
            fecha_fin,
            logo_url,
            created_at,
            descripcion,
            organizadores (
              nombre
            )
          ''')
              .eq('id', widget.eventId)
              .maybeSingle();

      setState(() {
        event = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar el evento: $e')));
    }
  }

  Future<void> _eliminarEvento() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar evento'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este evento?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('eventos').delete().eq('id', widget.eventId);
      Navigator.pop(context); // Volver atrás después de eliminar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar evento: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
        title: Text(
          event?['nombre_evento'] ?? 'Detalle del Evento',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : event == null
              ? const Center(child: Text('Evento no encontrado'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    if (event!['logo_url'] != null)
                      Center(
                        child: Image.network(event!['logo_url'], height: 120),
                      ),
                    const SizedBox(height: 16),
                    _infoTile('Nombre del evento', event!['nombre_evento']),
                    _infoTile(
                      'Organizador',
                      event!['organizadores']?['nombre'],
                    ),
                    _infoTile('Cupo total', event!['cupo_total'].toString()),
                    _infoTile('Fecha de inicio', event!['fecha_inicio']),
                    _infoTile('Fecha de fin', event!['fecha_fin']),
                    _infoTile('Creado en', event!['created_at']),
                    _infoTile(
                      'Descripcion',
                      event!['descripcion'] ?? 'Sin descripción',
                    ),

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Modificar'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        EditEventScreen(eventId: event!['id']),
                              ),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar'),
                          onPressed: _eliminarEvento,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _infoTile(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        tileColor: Colors.grey[100],
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value ?? 'No disponible'),
      ),
    );
  }
}
