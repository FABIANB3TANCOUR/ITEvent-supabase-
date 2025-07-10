import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:itevent/screens/admin/actividad_actualizar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalleActividadScreen extends StatefulWidget {
  final int idActividad;

  const DetalleActividadScreen({super.key, required this.idActividad});

  @override
  State<DetalleActividadScreen> createState() => _DetalleActividadScreenState();
}

class _DetalleActividadScreenState extends State<DetalleActividadScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? actividad;
  Map<String, dynamic>? evento;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    try {
      final data =
          await supabase
              .from('actividad')
              .select(
                '*, eventos (nombre_evento, logo_url, fecha_inicio, estado, municipio)',
              )
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

    setState(() => isLoading = false);
  }

  String _formatearFecha(String fechaIso) {
    final fecha = DateTime.parse(fechaIso);
    return DateFormat("dd MMMM, yyyy", 'es').format(fecha);
  }

  String _formatearHora(String hora) {
    final dt = DateTime.parse('2000-01-01 $hora');
    return DateFormat.jm('es').format(dt); // Ej: 8:30 a. m.
  }

  void _confirmarEliminacion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('¿Eliminar actividad?'),
            content: const Text('Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmado == true) {
      try {
        await supabase.from('actividad').delete().eq('id', widget.idActividad);

        if (mounted) {
          Navigator.pop(context); // Volver atrás tras eliminar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Actividad eliminada correctamente.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Actividad'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : actividad == null
              ? const Center(child: Text('Actividad no encontrada'))
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen principal
                    if (actividad!['portada_url'] != null)
                      Image.network(
                        actividad!['portada_url'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Center(
                              child: Text('Imagen no disponible'),
                            ),
                      ),

                    const SizedBox(height: 16),

                    // Logo circular del evento
                    if (evento?['logo_url'] != null)
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(evento!['logo_url']),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Título, lugar, fecha, hora
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

                    // Lugar (texto)
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

                    // URL como texto
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

                    // Descripción
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
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botón Actualizar
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => EditActividadScreen(
                                        actividadId: widget.idActividad,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text(
                              'Editar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),

                          // Botón Eliminar
                          ElevatedButton.icon(
                            onPressed: _confirmarEliminacion,
                            icon: const Icon(Icons.delete),
                            label: const Text(
                              'Eliminar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
