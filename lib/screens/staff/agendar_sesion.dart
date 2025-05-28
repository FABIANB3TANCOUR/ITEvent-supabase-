import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgendaScreen extends StatefulWidget {
  final String userId;
  final String eventoId;

  const AgendaScreen({
    super.key,
    required this.userId,
    required this.eventoId,
  });

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<dynamic> _sesiones = [];
  Set<int> _agendadasIds = {}; // IDs de sesiones ya agendadas

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      // Obtener sesiones del evento
      final sesionesResponse = await supabase
          .from('sesiones')
          .select()
          .eq('evento_id', widget.eventoId)
          .order('hora_inicio', ascending: true);

      // Obtener sesiones agendadas por usuario
      final agendasResponse = await supabase
          .from('agendas')
          .select('sesion_id')
          .eq('usuario_id', widget.userId);

      setState(() {
        _sesiones = sesionesResponse;
        _agendadasIds =
            agendasResponse.map<int>((a) => a['sesion_id'] as int).toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Future<void> _toggleAgenda(int sesionId) async {
    final yaAgendada = _agendadasIds.contains(sesionId);

    setState(() => _isLoading = true);

    try {
      if (yaAgendada) {
        // Quitar agenda
        await supabase
            .from('agendas')
            .delete()
            .eq('usuario_id', widget.userId)
            .eq('sesion_id', sesionId);
        _agendadasIds.remove(sesionId);
      } else {
        // Agregar agenda
        await supabase.from('agendas').insert({
          'usuario_id': widget.userId,
          'sesion_id': sesionId,
          'fecha_agenda': DateTime.now().toIso8601String(),
        });
        _agendadasIds.add(sesionId);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar agenda: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Agenda')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sesiones.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Agenda')),
        body: Center(child: Text('No hay sesiones por el momento.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sesiones.length,
        itemBuilder: (context, index) {
          final sesion = _sesiones[index];
          final sesionId = sesion['id'] as int;
          final agendada = _agendadasIds.contains(sesionId);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(sesion['titulo'] ?? 'Sesión sin título'),
              subtitle: Text(
                  'Hora: ${sesion['hora_inicio'] ?? 'N/D'}\nLugar: ${sesion['lugar'] ?? 'N/D'}'),
              trailing: ElevatedButton(
                onPressed: () => _toggleAgenda(sesionId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: agendada ? Colors.red : Colors.blue,
                ),
                child: Text(agendada ? 'Quitar' : 'Agregar'),
              ),
            ),
          );
        },
      ),
    );
  }
}

