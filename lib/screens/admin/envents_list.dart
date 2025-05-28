import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_detail_admin.dart';

class EventsListAdmin extends StatefulWidget {
  const EventsListAdmin({super.key});

  @override
  State<EventsListAdmin> createState() => _EventsListAdminState();
}

class _EventsListAdminState extends State<EventsListAdmin> {
  final supabase = Supabase.instance.client;

  List<dynamic> eventos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('eventos')
          .select()
          .order('fecha', ascending: true)
          .limit(100);
      setState(() {
        eventos = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar eventos: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos (Admin)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : eventos.isEmpty
              ? const Center(child: Text('No hay eventos disponibles.'))
              : ListView.builder(
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final event = eventos[index];
                    return ListTile(
                      title: Text(event['nombre'] ?? 'Sin nombre'),
                      subtitle: Text(event['descripcion'] ?? ''),
                      trailing: Text(event['fecha']?.toString() ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EventDetailAdmin(eventId: event['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
