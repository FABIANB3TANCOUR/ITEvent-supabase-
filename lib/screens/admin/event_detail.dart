import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final data = await supabase
          .from('eventos')
          .select()
          .eq('id', widget.eventId)
          .single();

      setState(() {
        event = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el evento: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event?['nombre'] ?? 'Detalle del Evento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? const Center(child: Text('Evento no encontrado'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Text(
                        event!['nombre'] ?? '',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(event!['descripcion'] ?? ''),
                      const SizedBox(height: 12),
                      Text('Fecha: ${event!['fecha'] ?? ''}'),
                      const SizedBox(height: 12),
                      // Aquí puedes añadir botones para editar, borrar, etc.
                      ElevatedButton(
                        onPressed: () {
                          // Ejemplo: Navegar a pantalla editar evento
                        },
                        child: const Text('Editar Evento'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
