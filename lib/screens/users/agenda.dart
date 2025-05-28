import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventActivitiesPage extends StatefulWidget {
  final int eventId;
  final String userId; // Id del usuario actual

  const EventActivitiesPage({
    super.key,
    required this.eventId,
    required this.userId,
  });

  @override
  State<EventActivitiesPage> createState() => _EventActivitiesPageState();
}

class _EventActivitiesPageState extends State<EventActivitiesPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> activities = [];
  Set<int> userAgendaActivityIds = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchActivitiesAndAgenda();
  }

  Future<void> fetchActivitiesAndAgenda() async {
    setState(() {
      loading = true;
    });

    try {
      // Traer actividades relacionadas al evento
      final fetchedActivities = await supabase
          .from('activities')
          .select()
          .eq('event_id', widget.eventId) as List<dynamic>;

      // Traer actividades agendadas por el usuario
      final fetchedUserAgenda = await supabase
          .from('user_agendas')
          .select('activity_id')
          .eq('user_id', widget.userId) as List<dynamic>;

      setState(() {
        activities = fetchedActivities;
        userAgendaActivityIds =
            fetchedUserAgenda.map<int>((e) => e['activity_id'] as int).toSet();
        loading = false;
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar actividades: $error')));
    }
  }

  Future<void> toggleAgenda(int activityId) async {
    final isAdded = userAgendaActivityIds.contains(activityId);

    try {
      if (isAdded) {
        // Quitar la actividad de la agenda del usuario
        await supabase
            .from('user_agendas')
            .delete()
            .eq('user_id', widget.userId)
            .eq('activity_id', activityId);
      } else {
        // Agregar la actividad a la agenda del usuario
        await supabase.from('user_agendas').insert({
          'user_id': widget.userId,
          'activity_id': activityId,
        });
      }

      setState(() {
        if (isAdded) {
          userAgendaActivityIds.remove(activityId);
        } else {
          userAgendaActivityIds.add(activityId);
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar agenda: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades del Evento'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                final activityId = activity['id'] as int;
                final isAdded = userAgendaActivityIds.contains(activityId);

                return ListTile(
                  title: Text(activity['name'] ?? 'Actividad sin nombre'),
                  subtitle: Text(activity['description'] ?? ''),
                  trailing: IconButton(
                    icon: Icon(
                      isAdded ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isAdded ? Colors.green : null,
                    ),
                    onPressed: () => toggleAgenda(activityId),
                  ),
                );
              },
            ),
    );
  }
}
