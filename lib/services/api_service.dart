import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //static const String baseUrl = 'http://127.0.0.1:5123';
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.appcheck.com.mx',
  );

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
    String? fotoBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/checada'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'numeroEmpleado': numeroEmpleado,
          'tokenPuntoLectura': tokenPuntoLectura,
          'tipoChecada': 'Entrada',
          'metodoUsado': metodoUsado,
          'esOffline': false,
          'fotoBase64': fotoBase64, // 👈 Enviar la foto
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['mensaje'] ?? 'Error al registrar checada');
      }
    } catch (e) {
      throw Exception('Error al registrar checada: $e');
    }
  }

  // 3. Obtener el método de lectura del empleado
  static Future<Map<String, dynamic>> obtenerMetodoLectura({
    required String numeroEmpleado,
    required String tokenKiosko,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/employee/metodo-lectura/$numeroEmpleado?tokenKiosko=$tokenKiosko'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al obtener método');
  }

  // 4. Recuperar token (si el kiosko ya está activo)
  static Future<Map<String, dynamic>> recuperarToken({
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/kiosko/recuperar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'Error al recuperar token');
  }

  // 5. Validar PIN (para el modo PIN o PIN+Rostro)
  static Future<Map<String, dynamic>> validarPin({
    required String numeroEmpleado,
    required String pin,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/employee/validar-pin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'numeroEmpleado': numeroEmpleado,
        'pin': pin,
      }),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['mensaje'] ?? 'PIN incorrecto');
  }
}
