import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final String guestEmail; // email invitado para agendar

  const EventDetailPage({
    super.key,
    required this.event,
    this.guestEmail = 'invitado@example.com',
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;

  Future<void> scheduleEvent() async {
    setState(() {
      isLoading = true;
    });

    final res = await supabase.from('guest_schedules').insert({
      'guest_email': widget.guestEmail,
      'event_id': widget.event['id'],
      'created_at': DateTime.now().toIso8601String(),
    });

    setState(() {
      isLoading = false;
    });

    if (res.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento agendado correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agendar evento: ${res.error!.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Scaffold(
      appBar: AppBar(title: Text(event['title'] ?? 'Detalle del evento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['title'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Fecha: ${event['date'] ?? ''}'),
            const SizedBox(height: 10),
            Text(event['description'] ?? ''),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : scheduleEvent,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Agendar evento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
