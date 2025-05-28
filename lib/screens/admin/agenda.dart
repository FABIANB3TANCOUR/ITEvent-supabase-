import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AgendaUsuario extends StatefulWidget {
  @override
  _AgendaUsuarioState createState() => _AgendaUsuarioState();
}

class _AgendaUsuarioState extends State<AgendaUsuario> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _eventos = {
    DateTime.now(): ['Reunión con equipo', 'Clase de Flutter'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Agenda'),
      ),
      body: Column(
        children: [
          TableCalendar(
            calendarFormat: _calendarFormat,
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2050),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => _eventos[day] ?? [],
          ),
          Expanded(
            child: _selectedDay == null
                ? Center(child: Text('Selecciona un día'))
                : ListView.builder(
                    itemCount: _eventos[_selectedDay]?.length ?? 0,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(_eventos[_selectedDay]![index]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _eliminarEvento(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/agregar_evento');
        },
      ),
    );
  }

  void _eliminarEvento(int index) {
    setState(() {
      _eventos[_selectedDay]?.removeAt(index);
    });
  }
}