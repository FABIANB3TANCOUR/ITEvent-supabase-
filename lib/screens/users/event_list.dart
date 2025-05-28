import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      final response = await supabase
          .from('events')
          .select()
          .order('date', ascending: true) as List<dynamic>;

      setState(() {
        events = response;
        loading = false;
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar eventos: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Disponibles'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  title: Text(event['name'] ?? 'Sin nombre'),
                  subtitle: Text(event['date'] ?? 'Sin fecha'),
                  onTap: () {
                    // Aquí puedes navegar a la pantalla de detalle del evento
                    // Navigator.push(...);
                  },
                );
              },
            ),
    );
  }
}
