import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'scanner_screen.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codigoController = TextEditingController();
  final _nombreKioskoController = TextEditingController(text: 'Kiosko Principal');
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreKioskoController.dispose();
    super.dispose();
  }

  Future<void> _activarKiosko() async {
    final codigo = _codigoController.text.trim().toUpperCase();
    final nombre = _nombreKioskoController.text.trim();

    if (codigo.isEmpty || nombre.isEmpty) {
      setState(() => _error = 'Por favor, ingresa el código y el nombre del kiosko.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final deviceId = 'tablet-${DateTime.now().millisecondsSinceEpoch}';

      final response = await ApiService.activarKiosko(
        codigo: codigo,
        deviceId: deviceId,
        nombreKiosko: nombre,
      );

      final token = response['tokenPuntoLectura'] as String;
      final nombreKiosko = response['nombre'] as String;

      await StorageService.guardarToken(token);
      await StorageService.guardarNombreKiosko(nombreKiosko);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _pegarDesdePortapapeles() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      final texto = clipboardData!.text!.trim().toUpperCase();
      final limpio = texto.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (limpio.length >= 4) {
        _codigoController.text = '${limpio.substring(0, 4)}-${limpio.substring(4)}';
      } else {
        _codigoController.text = limpio;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF0F766E)),
                const SizedBox(height: 20),
                Text(
                  'Activar Kiosko',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F766E),
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa el código de activación que te proporcionó tu administrador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nombreKioskoController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del kiosko',
                    hintText: 'Ej: Entrada Oficina Central',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codigoController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Código de activación',
                    hintText: 'XXXX-XXXX',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.vpn_key),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      tooltip: 'Pegar desde portapapeles',
                      onPressed: _pegarDesdePortapapeles,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                    LengthLimitingTextInputFormatter(9),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final texto = newValue.text.replaceAll('-', '').toUpperCase();
                      if (texto.length > 4) {
                        return TextEditingValue(
                          text: '${texto.substring(0, 4)}-${texto.substring(4)}',
                          selection: TextSelection.collapsed(offset: texto.length + 1),
                        );
                      } else {
                        return TextEditingValue(
                          text: texto,
                          selection: TextSelection.collapsed(offset: texto.length),
                        );
                      }
                    }),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _activarKiosko,
                    icon: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      _cargando ? 'Activando...' : 'Activar Kiosko',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
