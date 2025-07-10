import 'package:flutter/material.dart';

import 'agenda.dart';
import 'comunidad.dart';
import 'eventos.dart';
import 'mensajes.dart';
import 'notificaciones.dart';

void navigateToPage(BuildContext context, int index) async {
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
    case 3:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MensajesScreen()),
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
