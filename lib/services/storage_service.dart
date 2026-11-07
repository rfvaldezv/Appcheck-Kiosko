import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyTokenPuntoLectura = 'token_punto_lectura';
  static const _keyNombreKiosko = 'nombre_kiosko';
  static const _keyDeviceId = 'device_id_real';

  static Future<void> guardarToken(String token) async {
    await _storage.write(key: _keyTokenPuntoLectura, value: token);
  }

  static Future<String?> leerToken() async {
    return await _storage.read(key: _keyTokenPuntoLectura);
  }

  static Future<void> borrarToken() async {
    await _storage.delete(key: _keyTokenPuntoLectura);
  }

  static Future<void> guardarNombreKiosko(String nombre) async {
    await _storage.write(key: _keyNombreKiosko, value: nombre);
  }

  static Future<String?> leerNombreKiosko() async {
    return await _storage.read(key: _keyNombreKiosko);
  }

  // 👈 NUEVO: Obtener el ID real del hardware (androidId)
  static Future<String> obtenerDeviceIdReal() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  }

  // 👈 NUEVO: Guardar el DeviceId
  static Future<void> guardarDeviceId(String deviceId) async {
    await _storage.write(key: _keyDeviceId, value: deviceId);
  }

  // 👈 NUEVO: Leer el DeviceId guardado
  static Future<String?> leerDeviceId() async {
    return await _storage.read(key: _keyDeviceId);
  }

  static Future<void> borrarTodo() async {
    await _storage.deleteAll();
  }
}
