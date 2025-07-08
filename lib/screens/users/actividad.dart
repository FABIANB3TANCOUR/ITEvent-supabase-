import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalleActividadScreen extends StatefulWidget {
  final int idActividad;

  const DetalleActividadScreen({super.key, required this.idActividad});

  @override
  State<DetalleActividadScreen> createState() => _DetalleActividadScreenState();
}

class _DetalleActividadScreenState extends State<DetalleActividadScreen> {
  final supabase = Supabase.instance.client;
  late int matricula; // Ahora no es null
  Map<String, dynamic>? actividad;
  Map<String, dynamic>? evento;
  bool isLoading = true;
  bool estaInscrito = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    final matriculaGuardada = prefs.getInt('matricula');

    if (matriculaGuardada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se encontró la matrícula del alumno')),
      );
      return;
    }

    matricula = matriculaGuardada;
    await _cargarDetalle();
    await _verificarInscripcion();
    setState(() => isLoading = false);
  }

  Future<void> _cargarDetalle() async {
    try {
      final data = await supabase
          .from('actividad')
          .select('*, eventos (nombre_evento, logo_url, fecha_inicio, estado, municipio)')
          .eq('id', widget.idActividad)
          .maybeSingle();

      if (data != null) {
        actividad = data;
        evento = data['eventos'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la actividad: $e')),
      );
    }
  }

  Future<void> _verificarInscripcion() async {
    final inscripcion = await supabase
        .from('registro_actividades')
        .select()
        .eq('matricula', matricula)
        .eq('id_actividad', widget.idActividad)
        .maybeSingle();

    estaInscrito = inscripcion != null;
  }

  Future<void> _inscribirse() async {
    try {
      await supabase.from('registro_actividades').insert({
        'matricula': matricula,
        'id_actividad': widget.idActividad,
      });
      setState(() => estaInscrito = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te has inscrito correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al inscribirse: $e')),
      );
    }
  }

  Future<void> _desinscribirse() async {
    try {
      await supabase
          .from('registro_actividades')
          .delete()
          .eq('matricula', matricula)
          .eq('id_actividad', widget.idActividad);
      setState(() => estaInscrito = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has cancelado tu inscripción.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar inscripción: $e')),
      );
    }
  }

  String _formatearFecha(String fechaIso) {
    final fecha = DateTime.parse(fechaIso);
    return DateFormat("dd MMMM, yyyy", 'es').format(fecha);
  }

  String _formatearHora(String hora) {
    final dt = DateTime.parse('2000-01-01 $hora');
    return DateFormat.jm('es').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Actividad'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : actividad == null
              ? const Center(child: Text('Actividad no encontrada'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (actividad!['portada_url'] != null)
                        Image.network(
                          actividad!['portada_url'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('Imagen no disponible'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (evento?['logo_url'] != null)
                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(evento!['logo_url']),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              actividad!['nombre'] ?? 'Actividad sin título',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ubicación: ${evento?['estado'] ?? ''}, ${evento?['municipio'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (actividad!['fecha'] != null)
                              Text(
                                'Fecha: ${_formatearFecha(actividad!['fecha'])}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            const SizedBox(height: 4),
                            if (actividad!['hora_inicio'] != null &&
                                actividad!['hora_fin'] != null)
                              Text(
                                'Horario: ${_formatearHora(actividad!['hora_inicio'].toString())} - ${_formatearHora(actividad!['hora_fin'].toString())}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (actividad!['lugar'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.place, color: Colors.black54),
                              const SizedBox(width: 8),
                              Text(
                                'Lugar: ${actividad!['lugar']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (actividad!['lugar_url'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.link, color: Colors.black54),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'URL ubicación: ${actividad!['lugar_url']}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (actividad!['descripcion'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Descripción:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                actividad!['descripcion'],
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(estaInscrito ? Icons.cancel : Icons.check),
                          label: Text(estaInscrito
                              ? 'Cancelar inscripción'
                              : 'Inscribirme'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                estaInscrito ? Colors.red : Colors.green,
                          ),
                          onPressed: estaInscrito
                              ? _desinscribirse
                              : _inscribirse,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}
