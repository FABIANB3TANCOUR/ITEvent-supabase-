import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InternationalEventScreen extends StatefulWidget {
  final String userId;
  final String eventoId;

  const InternationalEventScreen({
    super.key,
    required this.userId,
    required this.eventoId,
  });

  @override
  State<InternationalEventScreen> createState() => _InternationalEventScreenState();
}

class _InternationalEventScreenState extends State<InternationalEventScreen> {
  final supabase = Supabase.instance.client;
  bool _asistiendo = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _verificarAsistencia();
  }

  Future<void> _verificarAsistencia() async {
    final asistencia = await supabase
        .from('asistencias')
        .select()
        .eq('user_id', widget.userId)
        .eq('evento_id', widget.eventoId)
        .maybeSingle();

    setState(() {
      _asistiendo = asistencia != null;
    });
  }

  Future<void> _registrarAsistencia() async {
    setState(() => _loading = true);

    try {
      await supabase.from('asistencias').insert({
        'user_id': widget.userId,
        'evento_id': widget.eventoId,
        'fecha_registro': DateTime.now().toIso8601String(),
      });

      setState(() {
        _asistiendo = true;
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Te has unido al evento!')),
      );
    } catch (e) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar asistencia: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evento Internacional'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Evento Escala',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16),
                  SizedBox(width: 4),
                  Text('Ensenada, Baja California'),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16),
                  SizedBox(width: 4),
                  Text('09 Mayo, 2025'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Utilización actual',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildUtilizationChart(),
            const SizedBox(height: 24),
            Center(
              child: _asistiendo
                  ? const Text('Ya estás registrado para asistir a este evento ✅')
                  : ElevatedButton.icon(
                      onPressed: _loading ? null : _registrarAsistencia,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Unirse al evento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
            ),
            const SizedBox(height: 40),
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilizationChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildChartBar(label: 'FONDO', value: 0.6),
          _buildChartBar(label: 'ADJUDICIO', value: 0.4),
          _buildChartBar(label: 'ATRAPORTOS', value: 0.8),
          _buildChartBar(label: 'PROGRESOS', value: 0.5),
          _buildChartBar(label: 'MANIFACACIÓN', value: 0.3),
        ],
      ),
    );
  }

  Widget _buildChartBar({required String label, required double value}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: 150 * value,
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Mis Eventos'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
      ],
      currentIndex: 2,
      selectedItemColor: Colors.blue,
    );
  }
}
