import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: EventsScreen(),
    );
  }
}

class EventsScreen extends StatelessWidget {
  // Ejemplo lista de eventos con imagenes
  final List<Map<String, String>> events = [
    {
      'title': 'Evento Escala',
      'dateRange': 'Feb 14 - 09 Mayo, 2023',
      'imageUrl': 'https://via.placeholder.com/150/0000FF/FFFFFF?text=Escala'
    },
    {
      'title': 'Evento Entre Amigos',
      'dateRange': 'Feb 14 - 09 Mayo, 2023',
      'imageUrl': 'https://via.placeholder.com/150/FF0000/FFFFFF?text=Amigos'
    },
    {
      'title': 'Evento Cultura Fest',
      'dateRange': 'Feb 14 - 09 Mayo, 2023',
      'imageUrl': 'https://via.placeholder.com/150/00FF00/FFFFFF?text=Cultura'
    },
    {
      'title': 'Evento Vibras',
      'dateRange': 'Feb 14 - 09 Mayo, 2023',
      'imageUrl': 'https://via.placeholder.com/150/FFFF00/000000?text=Vibras'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eventos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Explorar Eventos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildEventItem(
                  title: event['title']!,
                  dateRange: event['dateRange']!,
                  imageUrl: event['imageUrl']!,
                );
              },
            ),
          ),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required String title,
    required String dateRange,
    required String imageUrl,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(dateRange),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () {
          // Aquí iría la navegación o acción al seleccionar un evento
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(icon: Icons.home, label: 'Home', isSelected: true),
            _buildNavItem(icon: Icons.person, label: 'Agente'),
            _buildNavItem(icon: Icons.help, label: 'Assessor'),
            _buildNavItem(icon: Icons.chat, label: 'Comedial'),
            _buildNavItem(icon: Icons.notifications, label: 'Notificador'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
      ],
    );
  }
}
