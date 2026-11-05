import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'facial_screen.dart';
import 'confirmation_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _procesando = false;
  String? _nombreKiosko;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarNombreKiosko();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarNombreKiosko() async {
    final nombre = await StorageService.leerNombreKiosko();
    if (mounted) setState(() => _nombreKiosko = nombre);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.value.isRunning) {
        _controller.start();
      }
    } else if (state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    final codigo = rawValue.trim().replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (codigo.isEmpty) return;

    print('🔵 QR RAW: "$rawValue"');
    print('🔵 QR LIMPIO: "$codigo"');

    setState(() => _procesando = true);
    _controller.stop();

    try {
      final token = await StorageService.leerToken();
      if (token == null) throw Exception('No hay token de kiosko.');
      print('🔵 TOKEN DEL KIOSKO EN EL CELULAR: $token');

      print('🟡 Llamando a obtenerMetodoLectura con codigo: $codigo');
      final metodoInfo = await ApiService.obtenerMetodoLectura(
        numeroEmpleado: codigo,
        tokenKiosko: token,
      );
      print('🟡 Respuesta de obtenerMetodoLectura: $metodoInfo');

      final metodoLectura = metodoInfo['metodoLectura'] as String;
      print('🟡 Método de lectura: $metodoLectura');

      if (metodoLectura == 'QR') {
        print('🟢 Modo Solo QR. Registrando checada...');
        final response = await ApiService.registrarChecada(
          tokenPuntoLectura: token,
          numeroEmpleado: codigo,
          metodoUsado: 'QR',
        );
        print('🟢 Respuesta de registrarChecada: $response');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(
              mensaje: response['mensaje'] as String,
              tipoChecada: response['tipoChecada'] as String,
              nombreEmpleado: response['empleado']['nombreCompleto'] as String,
              hash: response['hash'] as String,
              timestamp: response['timestampServidor'] as String,
            ),
          ),
        );
      } else {
        print('🟢 Modo $metodoLectura. Navegando a FacialScreen...');
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacialScreen(numeroEmpleado: codigo, metodoUsado: metodoLectura),
          ),
        );
        
        if (!mounted) return;
        setState(() => _procesando = false);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) await _controller.start();
      }
    } catch (e) {
      print('🔴 Error en _onDetect: $e');
      if (!mounted) return;
      setState(() => _procesando = false);

      // 👈 MOSTRAR EL TOKEN EN UN DIÁLOGO (SOLO PARA DEBUG)
      final token = await StorageService.leerToken();
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error de Kiosko'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $e'),
              const SizedBox(height: 16),
              const Text('Token del celular:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(token ?? 'NO HAY TOKEN', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AppCheck Kiosko', style: TextStyle(fontSize: 18)),
            if (_nombreKiosko != null)
              Text(
                _nombreKiosko!,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
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
