import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventsListAdmin extends StatefulWidget {
  const EventsListAdmin({super.key});

  @override
  State<EventsListAdmin> createState() => _EventsListAdminState();
}

class _EventsListAdminState extends State<EventsListAdmin> {
  final supabase = Supabase.instance.client;
  List<dynamic> eventos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase.from('eventos').select().order('fecha_inicio');
      setState(() {
        eventos = data;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar eventos: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _agregarEvento() async {
    final nombreController = TextEditingController();
    final cupoController = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuevo Evento'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del evento'),
                ),
                TextField(
                  controller: cupoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cupo total'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      fechaInicio = picked.start;
                      fechaFin = picked.end;
                    }
                  },
                  child: const Text('Seleccionar rango de fechas'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isEmpty || cupoController.text.isEmpty || fechaInicio == null || fechaFin == null) {
                  return;
                }

                await supabase.from('eventos').insert({
                  'nombre_evento': nombreController.text,
                  'organizador_id': 1, // reemplaza según login
                  'cupo_total': int.parse(cupoController.text),
                  'fecha_inicio': fechaInicio!.toIso8601String(),
                  'fecha_fin': fechaFin!.toIso8601String(),
                });

                Navigator.pop(context);
                _cargarEventos();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _agregarEvento,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : eventos.isEmpty
              ? const Center(child: Text('No hay eventos disponibles.'))
              : ListView.builder(
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    return ListTile(
                      title: Text(evento['nombre_evento']),
                      subtitle: Text('${evento['fecha_inicio']} - ${evento['fecha_fin']}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Aquí iría navegación a event_detail si lo deseas
                      },
                    );
                  },
                ),
    );
  }
}
