import 'package:flutter/material.dart';

import 'main_navigator.dart';
import 'perfil.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue, // Azul
        leading: Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PerfilScreen()),
                );
              },
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        children: const [
          NotiCard(
            icon: Icons.calendar_today,
            title: 'Proximos Eventos',
            subtitle: 'Verifica tus nuevos eventos proximos',
          ),
          Divider(),
          NotiCard(
            icon: null,
            title: 'Bienvenido',
            subtitle: 'Busca tus eventos en ',
            logoText: 'ITE',
            logoBoldText: 'vent',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4, // Notificación
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
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
            label: 'Notificación',
          ),
        ],
      ),
    );
  }
}

class NotiCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String subtitle;
  final String? logoText;
  final String? logoBoldText;

  const NotiCard({
    super.key,
    this.icon,
    required this.title,
    required this.subtitle,
    this.logoText,
    this.logoBoldText,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          icon != null
              ? Icon(icon, size: 40)
              : RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: logoText ?? '',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextSpan(
                      text: logoBoldText ?? '',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle + (logoText != null ? 'ITE' + (logoBoldText ?? '') : ''),
      ),
    );
  }
}
