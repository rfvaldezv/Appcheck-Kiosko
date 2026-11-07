import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'confirmation_screen.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;

class FacialScreen extends StatefulWidget {
  final String numeroEmpleado;
  final String metodoUsado;
  const FacialScreen({super.key, required this.numeroEmpleado, this.metodoUsado = 'Rostro'});
  
  @override
  State<FacialScreen> createState() => _FacialScreenState();
}

class _FacialScreenState extends State<FacialScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  bool _rostroDetectado = false;
  bool _procesando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicializarCamara();
    _recuperarTokenInicial();
  }

  Future<void> _recuperarTokenInicial() async {
    try {
      final deviceId = await StorageService.leerDeviceId();
      if (deviceId != null && deviceId.isNotEmpty) {
        final rec = await ApiService.recuperarToken(deviceId: deviceId);
        final tokenNuevo = rec['tokenPuntoLectura'] as String?;
        if (tokenNuevo != null && tokenNuevo.isNotEmpty) {
          await StorageService.guardarToken(tokenNuevo);
          print('✅ Token recuperado al abrir FacialScreen');
        }
      }
    } catch (e) {
      print('⚠️ No se pudo recuperar token inicial: $e');
    }
  }

  Future<void> _inicializarCamara() async {
    try {
      final camaras = await availableCameras();
      final camaraFrontal = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => camaras.first,
      );

      _cameraController = CameraController(
        camaraFrontal,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      _cameraController!.startImageStream((image) async {
          if (_procesando) return;
          // TODO Sprint B: Implementar detección real con ML Kit
          // (CameraImage → InputImage requiere conversión YUV → RGB)
          // Por ahora: el rostro se valida 100% en el BACKEND con FaceONNX.
          // El ML Kit aquí solo serviría para UX (avisar "coloca tu rostro").
          if (mounted && !_rostroDetectado) {
              setState(() => _rostroDetectado = true);
          }
      });

      setState(() {});
    } catch (e) {
      setState(() => _error = 'Error al iniciar cámara: $e');
    }
  }

  Future<void> _registrarChecadaFacial() async {
    if (_procesando) return;

    setState(() => _procesando = true);

    try {
      final token = await StorageService.leerToken();
      if (token == null) throw Exception('No hay token de kiosko.');

      // Capturar la foto de la cámara
      final image = await _cameraController!.takePicture();
      // Comprimir la imagen a 300x300 (suficiente para la IA)
      final bytes = await image.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      final resizedImage = img.copyResize(originalImage!, width: 300, height: 300);
      final compressedBytes = img.encodeJpg(resizedImage, quality: 80);
      final fotoBase64 = base64Encode(compressedBytes);

      // Enviar la foto a la API para la validación
      final response = await ApiService.registrarChecada(
        tokenPuntoLectura: token,
        numeroEmpleado: widget.numeroEmpleado,
        metodoUsado: widget.metodoUsado,
        fotoBase64: fotoBase64,
        // pin: null,  // No aplica para métodos con rostro
      );

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
    } catch (e) {
      setState(() {
        _error = e.toString();
        _procesando = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: Text('Validación Facial: ${widget.numeroEmpleado}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _cameraController == null || !_cameraController!.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    CameraPreview(_cameraController!),
                    Center(
                      child: Container(
                        width: 250,
                        height: 350,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _rostroDetectado ? Colors.green : Colors.white54,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(125),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 120,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          _rostroDetectado ? 'Rostro detectado. Presiona para checar.' : 'Coloca tu rostro en el óvalo',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: _rostroDetectado && !_procesando ? _registrarChecadaFacial : null,
                          icon: _procesando ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.camera),
                          label: Text(_procesando ? 'Registrando...' : 'Checar con Rostro'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _rostroDetectado ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
