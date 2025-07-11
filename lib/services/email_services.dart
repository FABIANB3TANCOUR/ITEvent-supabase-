import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  final String edgeFunctionUrl;

  EmailService(this.edgeFunctionUrl);

  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    final response = await http.post(
      Uri.parse(edgeFunctionUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'to': to,
        'subject': subject,
        'html': htmlContent,
      }),
    );

    if (response.statusCode != 200) {
      print('Error al enviar correo: ${response.statusCode}');
      print('Cuerpo: ${response.body}');
      return false;
    }

    return true;
  }
}
