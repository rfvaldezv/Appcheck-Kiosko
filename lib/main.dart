import 'package:flutter/material.dart';
import 'screens/activation_screen.dart';
import 'screens/scanner_screen.dart';
import 'services/storage_service.dart';

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
    _verificarToken();
  }

  Future<void> _verificarToken() async {
    await Future.delayed(const Duration(seconds: 1));

    final token = await StorageService.leerToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
	Navigator.pushReplacement(
	 context,
	 MaterialPageRoute(builder: (_) => const ScannerScreen()),
	);
    } else {
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
