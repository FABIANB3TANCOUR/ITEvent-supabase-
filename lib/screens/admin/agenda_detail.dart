import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:itevent/screens/admin/actividad.dart';
import 'package:itevent/screens/admin/main_navigator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgendaEventoScreen extends StatefulWidget {
  final int idEvento;

  const AgendaEventoScreen({super.key, required this.idEvento});

  @override
  State<AgendaEventoScreen> createState() => _AgendaEventoScreenState();
}

class _AgendaEventoScreenState extends State<AgendaEventoScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> actividades = [];
  List<String> diasUnicos = [];
  String? diaSeleccionado;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    setState(() => isLoading = true);
    final response = await supabase
        .from('actividad')
        .select()
        .eq('id_evento', widget.idEvento)
        .order('hora_inicio');

    actividades = List<Map<String, dynamic>>.from(response);

    final dias = actividades.map((a) => a['fecha'].toString()).toSet().toList();
    dias.sort();

    setState(() {
      diasUnicos = dias;
      diaSeleccionado = diasUnicos.isNotEmpty ? diasUnicos.first : null;
      isLoading = false;
    });
  }

  String _formatearHora(String horaStr) {
    final dt = DateTime.parse('2000-01-01 $horaStr');
    return DateFormat.jm().format(dt); // ej: 7:30 A.M.
  }

  String _formatearBloqueHora(String horaStr) {
    final dt = DateTime.parse('2000-01-01 $horaStr');
    final hora = TimeOfDay.fromDateTime(dt);
    return '${hora.hour.toString().padLeft(2, '0')}:00 A.M.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Agenda del evento',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        centerTitle: true,
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : actividades.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Por el momento no cuentas con\nninguna actividad para este evento.\nAgrega alguna actividad',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => const NuevoEventoScreen(),
                        //   ),
                        // );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Agregar Actividad',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Barra de días
                  Container(
                    color: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            diasUnicos.map((dia) {
                              final fecha = DateTime.parse(dia);
                              final formato = DateFormat('dd MMM', 'es');
                              final seleccionado = dia == diaSeleccionado;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: ChoiceChip(
                                  label: Text(formato.format(fecha)),
                                  selected: seleccionado,
                                  selectedColor: const Color(0xFF3966CC),
                                  labelStyle: TextStyle(
                                    color:
                                        seleccionado
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  onSelected: (_) {
                                    setState(() => diaSeleccionado = dia);
                                  },
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),

                  // Lista de actividades
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _cargarActividades,
                      child: Builder(
                        builder: (context) {
                          final actividadesDelDia =
                              actividades
                                  .where(
                                    (a) =>
                                        a['fecha'].toString() ==
                                        diaSeleccionado,
                                  )
                                  .toList();

                          if (actividadesDelDia.isEmpty) {
                            return const Center(
                              child: Text('No hay actividades para este día.'),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: actividadesDelDia.length,
                            itemBuilder: (context, index) {
                              final actividad = actividadesDelDia[index];
                              final horaInicio = actividad['hora_inicio'];
                              final horaFin = actividad['hora_fin'];
                              final bloque = _formatearBloqueHora(horaInicio);

                              final mostrarBloque =
                                  index == 0 ||
                                  _formatearBloqueHora(
                                        actividadesDelDia[index -
                                            1]['hora_inicio'],
                                      ) !=
                                      bloque;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (mostrarBloque)
                                    Container(
                                      width: double.infinity,
                                      color: Colors.grey[300],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        bloque,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => DetalleActividadScreen(
                                                idActividad: actividad['id'],
                                              ),
                                        ),
                                      );
                                    },

                                    child: Container(
                                      width:
                                          double
                                              .infinity, // 🔵 para ocupar todo el ancho
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        // puedes quitar borderRadius si no lo necesitas
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Columna izquierda con las horas
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatearHora(horaInicio),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                _formatearHora(horaFin),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),

                                          // Columna principal con el contenido
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  actividad['nombre'] ??
                                                      'Sin nombre',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                if (actividad['lugar'] != null)
                                                  Text(
                                                    'Lugar: ${actividad['lugar']}',
                                                  ),
                                                if (actividad['descripcion'] !=
                                                    null)
                                                  Text(
                                                    'Nombre: ${actividad['descripcion']}',
                                                  ),
                                              ],
                                            ),
                                          ),

                                          // Icono de flecha
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

      // Botón flotante para agregar actividad
      floatingActionButton:
          actividades.isNotEmpty
              ? FloatingActionButton(
                backgroundColor: const Color(0xFF3966CC),
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => AgregarActividadScreen(idEvento: widget.idEvento),
                  //   ),
                  // );
                },
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => navigateToPage(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Asistentes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Comunidad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
        ],
      ),
    );
  }
}
