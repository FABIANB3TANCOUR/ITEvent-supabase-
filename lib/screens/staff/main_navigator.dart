import 'package:flutter/material.dart';
import 'package:itevent/screens/admin/main.dart';
import 'package:itevent/screens/staff/perfil_propio.dart';

import 'agendar_sesion.dart';
import 'comunidad.dart';
import 'perfil_asistente.dart';
import 'perfil_invitado.dart';
import 'type_logins.dart';

import 'event_detail.dart';


class MainNavigatorStaff extends StatefulWidget {
  const MainNavigatorStaff({super.key});

  @override
  State<MainNavigatorStaff> createState() => _MainNavigatorStaffState();
}

class _MainNavigatorStaffState extends State<MainNavigatorStaff> {
  int _selectedIndex = 0;

  // ⚠️ Cambia estos valores por los valores reales cuando tengas el userId y eventoId
  final String userId = 'usuario_id';       // ← Aquí va el ID del usuario real
  final String eventoId = 'evento_id';      // ← Aquí va el ID del evento real

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AgendaScreen(userId: 'id',eventoId: 'id',),
      const ComunidadScreen(),
      PerfilUsuarioPage(userId: userId),
      PerfilInvitadoPage(uuid: userId),
      LoginStaffPage(),
      EventScreen(), // <-- Aquí está corregido y definido como const si aplica
      InternationalEventScreen(eventoId: eventoId, userId: userId),
      PerfilPropioStaff(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Agendas'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Comunidad'),
          BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: 'Asistente'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Invitado'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Eventos'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Detalle'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Perfil'),
        ],
      ),
    );
  }
}
