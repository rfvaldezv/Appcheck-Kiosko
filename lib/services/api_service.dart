import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

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
      String? pin,
  }) async {
      Future<http.Response> postChecada(String token) => http.post(
          Uri.parse('$baseUrl/api/checada'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
              'numeroEmpleado': numeroEmpleado,
              'tokenPuntoLectura': token,
              'tipoChecada': 'Entrada',
              'metodoUsado': metodoUsado,
              'esOffline': false,
              'fotoBase64': fotoBase64,
              'pin': pin,
          }),
      );

      // 1. Intento con el token recibido
      var response = await postChecada(tokenPuntoLectura);

      if (response.statusCode == 200) {
          return jsonDecode(response.body);
      }

      // 2. Si 401, recuperar token y reintentar UNA vez
      if (response.statusCode == 401) {
          print('⚠️ Token inválido en checada (401). Recuperando token...');
          try {
              var deviceId = await StorageService.leerDeviceId();
              if (deviceId == null || deviceId.isEmpty) {
                  try {
                      deviceId = await StorageService.obtenerDeviceIdReal();
                      await StorageService.guardarDeviceId(deviceId);
                  } catch (e) {
                      print('❌ Error obteniendo deviceId: $e');
                  }
              }

              if (deviceId != null && deviceId.isNotEmpty) {
                  final rec = await recuperarToken(deviceId: deviceId);
                  final tokenNuevo = rec['tokenPuntoLectura'] as String?;
                  if (tokenNuevo != null && tokenNuevo.isNotEmpty) {
                      await StorageService.guardarToken(tokenNuevo);
                      print('✅ Token recuperado. Reintentando checada...');

                      // 🔧 FIX #1: esperar 500ms para que el backend actualice el hash en BD
                      await Future.delayed(const Duration(milliseconds: 500));

                      response = await postChecada(tokenNuevo);

                      if (response.statusCode == 200) {
                          return jsonDecode(response.body);
                      }

                      // 🔧 FIX #2: si el retry falla, mensaje claro
                      final err = jsonDecode(response.body);
                      throw Exception(
                          'Sesión expirada. Reinicia la app. Detalle: ${err['mensaje'] ?? 'Token inválido'}'
                      );
                  }
              }
          } catch (e) {
              print('❌ Error en retry: $e');
              // 🔧 FIX #3: limpiar token para forzar recuperación en próximo arranque
              await StorageService.borrarToken();
              rethrow;
          }
      }

      // 3. Otro error (400, 404, 500, etc.)
      try {
          final error = jsonDecode(response.body);
          throw Exception(error['mensaje'] ?? 'Error al registrar checada (${response.statusCode})');
      } catch (e) {
          throw Exception('Error al registrar checada (${response.statusCode}): ${response.body}');
      }
  }

  // 3. Obtener el método de lectura del empleado
  static Future<Map<String, dynamic>> obtenerMetodoLectura({
      required String numeroEmpleado,
      required String tokenKiosko,
  }) async {
      final url = Uri.parse('$baseUrl/api/employee/metodo-lectura/$numeroEmpleado?tokenKiosko=$tokenKiosko');
      var response = await http.get(url);

      if (response.statusCode == 200) {
          return jsonDecode(response.body);
      }

      // Si 401, recuperar token y reintentar
      if (response.statusCode == 401) {
          print('⚠️ Token inválido (401). Intentando recuperar token...');
          try {
              var deviceId = await StorageService.leerDeviceId();
              if (deviceId == null || deviceId.isEmpty) {
                  deviceId = await StorageService.obtenerDeviceIdReal();
                  await StorageService.guardarDeviceId(deviceId);
              }

              if (deviceId != null && deviceId.isNotEmpty) {
                  final rec = await recuperarToken(deviceId: deviceId);
                  final tokenNuevo = rec['tokenPuntoLectura'] as String?;
                  if (tokenNuevo != null && tokenNuevo.isNotEmpty) {
                      await StorageService.guardarToken(tokenNuevo);
                      print('✅ Token recuperado. Reintentando...');

                      // 🔧 FIX: esperar 500ms para que el backend actualice el hash
                      await Future.delayed(const Duration(milliseconds: 500));

                      final url2 = Uri.parse('$baseUrl/api/employee/metodo-lectura/$numeroEmpleado?tokenKiosko=$tokenNuevo');
                      response = await http.get(url2);

                      if (response.statusCode == 200) {
                          return jsonDecode(response.body);
                      }

                      final err = jsonDecode(response.body);
                      throw Exception('Sesión expirada. Reinicia la app. Detalle: ${err['mensaje'] ?? 'Token inválido'}');
                  }
              }
          } catch (e) {
              print('❌ Error recuperando token: $e');
              await StorageService.borrarToken();
              rethrow;
          }
      }

      try {
          final error = jsonDecode(response.body);
          throw Exception(error['mensaje'] ?? 'Error al obtener método (${response.statusCode})');
      } catch (e) {
          throw Exception('Error al obtener método (${response.statusCode}): ${response.body}');
      }
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
