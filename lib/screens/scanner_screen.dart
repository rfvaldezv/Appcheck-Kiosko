import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'confirmation_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _procesando = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final codigo = barcodes.first.rawValue;
    if (codigo == null || codigo.isEmpty) return;

    setState(() => _procesando = true);
    _controller.stop();

    // 👈 Capturamos el Navigator y el ScaffoldMessenger ANTES del await
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final token = await StorageService.leerToken();
      if (token == null || token.isEmpty) {
        throw Exception('No hay token de kiosko. Reactiva el dispositivo.');
      }

      final response = await ApiService.registrarChecada(
        tokenPuntoLectura: token,
        numeroEmpleado: codigo,
        metodoUsado: 'QR',
      );

      if (!mounted) return;

      // 👈 Usamos el navigator capturado, no el context
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(
            mensaje: response['mensaje'] as String,
            tipoChecada: response['tipoChecada'] as String,
            nombreEmpleado: response['empleado']['nombreCompleto'] as String,
            hash: response['hash'] as String,
            timestamp: response['timestampServidor'] as String,
          ),
        ),
      ).then((_) {
        if (!mounted) return;
        setState(() => _procesando = false);
        _controller.start();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      _controller.start();
      // 👈 Usamos el messenger capturado, no el context
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: const Text('AppCheck Kiosko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Desactivar kiosko',
            onPressed: () async {
              await StorageService.borrarTodo();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0F766E), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Acerque su código QR al centro de la cámara',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
          if (_procesando)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0F766E)),
                    SizedBox(height: 16),
                    Text('Registrando checada...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
