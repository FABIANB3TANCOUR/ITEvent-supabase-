import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'agenda.dart';
import 'comunidad.dart';
import 'eventos.dart';
import 'mensajes.dart';
import 'notificaciones.dart';

void navigateToPage(BuildContext context, int index) async {
  // Solo necesitamos cargar el adminId si vamos a la pantalla de mensajes
  if (index == 3) {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getInt('adminId');
    
    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al administrador')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MensajesScreen()),
    );
    return;
  }

  // Para las demás pantallas
  switch (index) {
    case 0:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EventosScreen()),
      );
      break;
    case 1:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AgendaUsuario()),
      );
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ComunidadScreen()),
      );
      break;
    case 4:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
      break;
  }
}