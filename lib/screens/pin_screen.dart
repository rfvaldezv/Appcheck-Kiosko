import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'facial_screen.dart';
import 'confirmation_screen.dart';

/// Pantalla para checar con ID (y opcionalmente PIN, según el método del empleado).
/// 
/// Flujo:
/// 1. Usuario ingresa número de empleado
/// 2. Backend consulta el método de lectura preferido
/// 3. Si método es "ID+PIN" → pide PIN y registra
/// 4. Si método es "ID+Rostro" → abre cámara
/// 5. Si método es "QR+Rostro" → abre cámara
/// 6. Si método es "Rostro" → abre cámara
/// 7. Si método es "QR" → registra directo (aunque no aplica, por seguridad)
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _numeroController = TextEditingController();
  bool _cargando = false;
  String? _error;

  Future<void> _consultarMetodo() async {
    final numero = _numeroController.text.trim();

    if (numero.isEmpty) {
      setState(() => _error = 'Ingresa tu número de empleado.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final token = await StorageService.leerToken();
      if (token == null) throw Exception('No hay token de kiosko.');

      // 1. Consultar el método de lectura del empleado
      final response = await ApiService.obtenerMetodoLectura(
        numeroEmpleado: numero,
        tokenKiosko: token,
      );

      final metodoLectura = response['metodoLectura'] as String;
      final nombreEmpleado = response['nombre'] as String;

      // 2. Según el método, decidir qué pedir
      if (metodoLectura == 'ID+PIN') {
        // Pedir PIN y registrar
        if (!mounted) return;
        setState(() => _cargando = false);
        await _pedirPinYRegistrar(numero, token, nombreEmpleado);
      } else if (metodoLectura == 'ID+Rostro' || metodoLectura == 'QR+Rostro' || metodoLectura == 'Rostro') {
        // Abrir cámara directamente
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FacialScreen(
              numeroEmpleado: numero,
              metodoUsado: metodoLectura,
            ),
          ),
        );
      } else if (metodoLectura == 'QR') {
        // Registrar directo (sin PIN, sin cámara)
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

  Future<void> _pedirPinYRegistrar(String numeroEmpleado, String token, String nombreEmpleado) async {
    final pinController = TextEditingController();
    String? errorPin;

    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Hola, $nombreEmpleado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingresa tu PIN para checar:'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'PIN',
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorPin != null) ...[
                const SizedBox(height: 8),
                Text(errorPin!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = pinController.text.trim();
                if (pin.isEmpty) {
                  setDialogState(() => errorPin = 'Ingresa tu PIN.');
                  return;
                }
                try {
                  final checada = await ApiService.registrarChecada(
                    tokenPuntoLectura: token,
                    numeroEmpleado: numeroEmpleado,
                    metodoUsado: 'ID+PIN',
                    pin: pin,
                  );
                  if (!mounted) return;
                  Navigator.pop(context, 'ok');
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
                } catch (e) {
                  setDialogState(() => errorPin = e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Checar'),
            ),
          ],
        ),
      ),
    );

    if (pin == null) {
      // El usuario canceló
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: const Text('Checar con ID'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge, size: 64, color: Color(0xFF0F766E)),
            const SizedBox(height: 24),
            const Text(
              'Ingresa tu número de empleado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numeroController,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4),
              decoration: const InputDecoration(
                labelText: 'Número de Empleado',
                hintText: 'Ej. TEST001',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _consultarMetodo(),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _consultarMetodo,
                icon: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.arrow_forward),
                label: Text(_cargando ? 'Consultando...' : 'Continuar'),
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
