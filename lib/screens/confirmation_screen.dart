import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  final String mensaje;
  final String tipoChecada;
  final String nombreEmpleado;
  final String hash;
  final String timestamp;

  const ConfirmationScreen({
    super.key,
    required this.mensaje,
    required this.tipoChecada,
    required this.nombreEmpleado,
    required this.hash,
    required this.timestamp,
  });

  bool get _esEntrada => tipoChecada == 'Entrada';

  @override
  Widget build(BuildContext context) {
    final color = _esEntrada ? const Color(0xFF0F766E) : const Color(0xFFF59E0B);
    final icono = _esEntrada ? Icons.login : Icons.logout;
    final horaFormateada = _formatearHora(timestamp);

    return Scaffold(
      backgroundColor: color,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 100, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tipoChecada,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Empleado', nombreEmpleado),
                      const SizedBox(height: 8),
                      _infoRow('Hora', horaFormateada),
                      const SizedBox(height: 8),
                      _infoRow('Hash', '${hash.substring(0, 16)}...'),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(
                      'Siguiente empleado',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: color,
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

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatearHora(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      final hora = dt.hour.toString().padLeft(2, '0');
      final minuto = dt.minute.toString().padLeft(2, '0');
      return '$hora:$minuto';
    } catch (_) {
      return isoTimestamp;
    }
  }
}
