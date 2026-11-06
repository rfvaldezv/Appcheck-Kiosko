import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'facial_screen.dart';
import 'confirmation_screen.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _numeroController = TextEditingController();
  final _pinController = TextEditingController();
  bool _cargando = false;
  String? _error;

  Future<void> _validarPin() async {
    final numero = _numeroController.text.trim();
    final pin = _pinController.text.trim();

    if (numero.isEmpty || pin.isEmpty) {
      setState(() => _error = 'Ingresa tu número de empleado y PIN.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // 1. Validar PIN con la API
      final response = await ApiService.validarPin(
        numeroEmpleado: numero,
        pin: pin,
      );

      final metodoLectura = response['metodoLectura'] as String;

      // 2. Si es PIN simple, registrar checada directo
      if (metodoLectura == 'PIN') {
        final token = await StorageService.leerToken();
        if (token == null) throw Exception('No hay token de kiosko.');

        final checada = await ApiService.registrarChecada(
          tokenPuntoLectura: token,
          numeroEmpleado: numero,
          metodoUsado: 'PIN',
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(
              mensaje: checada['mensaje'] as String,
              tipoChecada: checada['tipoChecada'] as String,
              nombreEmpleado: checada['empleado']['nombreCompleto'] as String,
              hash: checada['hash'] as String,
              timestamp: checada['timestampServidor'] as String,
            ),
          ),
        );
      } else if (metodoLectura == 'PIN+Rostro') {
        // 3. PIN + Rostro: ir a la pantalla facial con nombre canónico
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FacialScreen(
              numeroEmpleado: numero,
              metodoUsado: 'PIN+Rostro',
            ),
          ),
        );
      } else if (metodoLectura == 'Rostro') {
        // 4. Solo Rostro: ir a la pantalla facial
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FacialScreen(
              numeroEmpleado: numero,
              metodoUsado: 'Rostro',
            ),
          ),
        );
      } else if (metodoLectura == 'QR+Rostro') {
        // 5. QR + Rostro (por si el empleado lo tiene configurado así)
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FacialScreen(
              numeroEmpleado: numero,
              metodoUsado: 'QR+Rostro',
            ),
          ),
        );
      } else if (metodoLectura == 'QR') {
        // 6. QR solo (aunque venga por PIN, respetamos su método preferido)
        final token = await StorageService.leerToken();
        if (token == null) throw Exception('No hay token de kiosko.');

        final checada = await ApiService.registrarChecada(
          tokenPuntoLectura: token,
          numeroEmpleado: numero,
          metodoUsado: 'QR',
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(
              mensaje: checada['mensaje'] as String,
              tipoChecada: checada['tipoChecada'] as String,
              nombreEmpleado: checada['empleado']['nombreCompleto'] as String,
              hash: checada['hash'] as String,
              timestamp: checada['timestampServidor'] as String,
            ),
          ),
        );
      } else {
        setState(() => _error = 'Método de lectura no soportado: $metodoLectura');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: const Text('Checar con PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _numeroController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Número de Empleado',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'PIN (4 dígitos)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _validarPin,
                icon: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.check_circle),
                label: Text(_cargando ? 'Validando...' : 'Checar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
