import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyTokenPuntoLectura = 'token_punto_lectura';
  static const _keyNombreKiosko = 'nombre_kiosko';

  // Guardar el token del kiosko
  static Future<void> guardarToken(String token) async {
    await _storage.write(key: _keyTokenPuntoLectura, value: token);
  }

  // Leer el token del kiosko
  static Future<String?> leerToken() async {
    return await _storage.read(key: _keyTokenPuntoLectura);
  }

  // Guardar el nombre del kiosko (para mostrarlo en pantalla)
  static Future<void> guardarNombreKiosko(String nombre) async {
    await _storage.write(key: _keyNombreKiosko, value: nombre);
  }

  // Leer el nombre del kiosko
  static Future<String?> leerNombreKiosko() async {
    return await _storage.read(key: _keyNombreKiosko);
  }

  // Borrar todo (útil para pruebas o revocación)
  static Future<void> borrarTodo() async {
    await _storage.deleteAll();
  }
}
