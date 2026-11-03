import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5123';

  // =====================================================
  // 1. Activar kiosko con código de 8 caracteres
  // =====================================================
  static Future<Map<String, dynamic>> activarKiosko({
    required String codigo,
    required String deviceId,
    required String nombreKiosko,
  }) async {
    try {
      print('🔵 Enviando petición a: $baseUrl/api/kiosko/activar');
      print('🔵 Body: ${jsonEncode({
        'codigo': codigo,
        'deviceId': deviceId,
        'nombreKiosko': nombreKiosko,
        'tipo': 'KioskoFijo',
      })}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/kiosko/activar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo': codigo,
          'deviceId': deviceId,
          'nombreKiosko': nombreKiosko,
          'tipo': 'KioskoFijo',
        }),
      );

      print('🟢 Status code: ${response.statusCode}');
      print('🟢 Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        String mensajeError = 'Error al activar el kiosko (${response.statusCode})';
        try {
          final error = jsonDecode(response.body);
          if (error is Map && error.containsKey('mensaje')) {
            mensajeError = error['mensaje'];
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            mensajeError = 'Error: ${response.body}';
          }
        }
        throw Exception(mensajeError);
      }
    } catch (e) {
      print('🔴 Error: $e');
      throw Exception('No se pudo conectar con el servidor. Detalle: $e');
    }
  }

  // =====================================================
  // 2. Registrar checada
  // =====================================================
  static Future<Map<String, dynamic>> registrarChecada({
    required String tokenPuntoLectura,
    required String numeroEmpleado,
    required String metodoUsado,
  }) async {
    try {
      print('🔵 Enviando checada a: $baseUrl/api/checada');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/checada'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'numeroEmpleado': numeroEmpleado,
          'tokenPuntoLectura': tokenPuntoLectura,
          'tipoChecada': 'Entrada',
          'metodoUsado': metodoUsado,
          'esOffline': false,
        }),
      );

      print('🟢 Status code: ${response.statusCode}');
      print('🟢 Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['mensaje'] ?? 'Error al registrar checada');
      }
    } catch (e) {
      print('🔴 Error: $e');
      throw Exception('Error al registrar checada: $e');
    }
  }
}
