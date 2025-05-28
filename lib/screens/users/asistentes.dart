import 'package:flutter/material.dart';

class AssistantsPage extends StatelessWidget {
  const AssistantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Asistentes"),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Botones de filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Todo"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Recomendado"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Categoría"),
                ),
              ],
            ),
          ),
          // Lista de asistentes
          Expanded(
            child: ListView(
              children: const [
                _AssistantCard(
                  name: "David Arams",
                  role: "Coordinador",
                  location: "Ensenada, B.C.",
                ),
                _AssistantCard(
                  name: "Jason Alexander",
                  role: "Director",
                  location: "Ensenada, B.C.",
                ),
                _AssistantCard(
                  name: "Kathy Perez",
                  role: "Organizadora",
                  location: "Ensenada, B.C.",
                ),
                _AssistantCard(
                  name: "Roberto Gomez",
                  role: "Productor",
                  location: "Sin especificar",
                ),
              ],
            ),
          ),
          // Barra de navegación inferior
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.indigo,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Agenda"),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: "Asistentes"),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: "Comunidad"),
              BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notificación"),
            ],
          ),
        ],
      ),
    );
  }
}

// Componente de Tarjeta de Asistente
class _AssistantCard extends StatelessWidget {
  final String name;
  final String role;
  final String location;

  const _AssistantCard({
    required this.name,
    required this.role,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.indigo,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("$role - $location"),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        // Acción al tocar el asistente
      },
    );
  }
}