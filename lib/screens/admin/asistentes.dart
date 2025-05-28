import 'package:flutter/material.dart';

import 'main_navigator.dart';
import 'perfil.dart';

class AsistentesScreen extends StatelessWidget {
  const AsistentesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5998),
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
          'Asistentes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(label: const Text('Todo'), onSelected: (_) {}),
                FilterChip(
                  label: const Text('Recomendado'),
                  onSelected: (_) {},
                ),
                FilterChip(label: const Text('Categoría'), onSelected: (_) {}),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Lista
          Expanded(
            child: ListView(
              children: const [
                PersonaCard(
                  name: 'David Arams',
                  role: 'Administrador',
                  location: 'Ensenada, B.C.',
                  image: 'https://randomuser.me/api/portraits/men/32.jpg',
                ),
                PersonaCard(
                  name: 'Jason Alexander',
                  role: 'Conferencista',
                  location: 'Ensenada, B.C.',
                  image: 'https://randomuser.me/api/portraits/men/12.jpg',
                ),
                PersonaCard(
                  name: 'Kathy Perez',
                  role: 'Staff',
                  location: 'Ensenada, B.C.',
                  image: 'https://randomuser.me/api/portraits/women/44.jpg',
                ),
                PersonaCard(
                  name: 'Roberto Gomez',
                  role: 'Administrador',
                  location: 'Ensenada, B.C.',
                  image: 'https://randomuser.me/api/portraits/men/54.jpg',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // asistentes
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => navigateToPage(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Aasistentes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificación',
          ),
        ],
      ),
    );
  }
}

class PersonaCard extends StatelessWidget {
  final String name;
  final String role;
  final String location;
  final String image;

  const PersonaCard({
    super.key,
    required this.name,
    required this.role,
    required this.location,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage(image), radius: 25),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$role\n$location'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Acción al dar tap
        },
      ),
    );
  }
}
