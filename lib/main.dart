import 'package:flutter/material.dart';
import 'screens/activation_screen.dart';
import 'screens/scanner_screen.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';

void main() {
  runApp(const AppCheckKioskoApp());
}

class AppCheckKioskoApp extends StatelessWidget {
  const AppCheckKioskoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppCheck Kiosko',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0F766E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    try {
      // 🔧 FIX: SIEMPRE recuperar token por deviceId (no solo si no hay)
      // Esto resuelve el problema del "token viejo" que causaba 401.
      
      var deviceIdGuardado = await StorageService.leerDeviceId();

      // 🔧 FIX: si no hay deviceId en storage, obtenerlo del hardware y guardarlo
      if (deviceIdGuardado == null || deviceIdGuardado.isEmpty) {
          print('⚠️ No hay deviceId guardado. Obteniendo del hardware...');
          try {
               deviceIdGuardado = await StorageService.obtenerDeviceIdReal();
               await StorageService.guardarDeviceId(deviceIdGuardado);
               print('✅ DeviceId guardado: $deviceIdGuardado');
          } catch (e) {
              print('❌ Error obteniendo deviceId del hardware: $e');
          }
      }

      if (deviceIdGuardado != null && deviceIdGuardado.isNotEmpty) {
        // Hay deviceId registrado → intentar recuperar token fresco
        try {
          print('🔄 Recuperando token por deviceId: $deviceIdGuardado');
          final response = await ApiService.recuperarToken(deviceId: deviceIdGuardado);
          
          final tokenNuevo = response['tokenPuntoLectura'] as String?;
          if (tokenNuevo != null && tokenNuevo.isNotEmpty) {
            await StorageService.guardarToken(tokenNuevo);
            print('✅ Token recuperado y guardado: ${tokenNuevo.substring(0, 8)}...');
            
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            );
            return;
          }
        } catch (e) {
          print('⚠️ Error recuperando token: $e');
          // Si falla recuperación, intentar con token guardado (fallback)
          final tokenGuardado = await StorageService.leerToken();
          if (tokenGuardado != null && tokenGuardado.isNotEmpty) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            );
            return;
          }
        }
      }
      
      // Si no hay deviceId ni token, pedir activación
      print('⚠️ Sin deviceId ni token, ir a activación');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ActivationScreen()),
      );
    } catch (e) {
      print('❌ Error en inicialización: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ActivationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F766E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'AppCheck',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kiosko',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Recuperando token...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScannerScreen extends StatelessWidget {
  const PlaceholderScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escáner (en construcción)')),
      body: const Center(child: Text('Aquí irá el escáner QR')),
    );
  }
}
