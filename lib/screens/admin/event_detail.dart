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
  String localidad = '';

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
            portada_url,
            created_at,
            descripcion,
            estado,
            municipio,
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
      if (event!['municipio'] != null && event!['estado'] != null) {
        localidad = '${event!['municipio']}, ${event!['estado']}';
      } else {
        localidad = 'Ubicacion no disponible';
      }
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
        title: const Text(
          'Eventos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : event == null
              ? const Center(child: Text('Evento no encontrado'))
              : ListView(
                children: [
                  if (event!['portada_url'] != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: Image.network(
                        event!['portada_url'],
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event!['nombre_evento'] ?? 'Sin nombre',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          localidad,
                          style: TextStyle(color: Colors.grey[700]),
                        ),

                        Text(
                          _formatearFecha(event!['fecha_fin']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),
                        _seccionTitulo('Sobre el evento'),
                        const SizedBox(height: 12),
                        _infoCard([
                          _infoText('Descripción', event!['descripcion']),
                          _infoText(
                            'Organizador',
                            event!['organizadores']?['nombre'],
                          ),
                          _infoText(
                            'Cupo total',
                            event!['cupo_total'].toString(),
                          ),
                          _infoText(
                            'Fecha de inicio',
                            _formatearFecha(event!['fecha_inicio']),
                          ),
                          _infoText(
                            'Fecha de fin',
                            _formatearFecha(event!['fecha_fin']),
                          ),
                          _infoText(
                            'Creado en',
                            _formatearFecha(event!['created_at']),
                          ),
                        ]),
                        const SizedBox(height: 25),
                        _actionButton('Modificar datos', Colors.blue, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => EditEventScreen(eventId: event!['id']),
                            ),
                          );
                        }),
                        _actionButton(
                          'Agregar conferencias',
                          Colors.blue,
                          () {},
                        ),
                        _actionButton(
                          'Modificar conferencias',
                          Colors.blue,
                          () {},
                        ),
                        _actionButton(
                          'Eliminar Evento',
                          Colors.orange,
                          _eliminarEvento,
                          colorTexto: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  String _formatearFecha(String fechaISO) {
    try {
      final fecha = DateTime.parse(fechaISO);
      return '${fecha.day.toString().padLeft(2, '0')} ${_mesNombre(fecha.month)}, ${fecha.year}';
    } catch (_) {
      return fechaISO;
    }
  }

  String _mesNombre(int mes) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return meses[mes - 1];
  }

  Widget _seccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _infoText(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value ?? 'No disponible',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _actionButton(
    String texto,
    Color color,
    VoidCallback onPressed, {
    Color colorTexto = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: colorTexto,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: onPressed,
        child: Text(texto),
      ),
    );
  }
}
