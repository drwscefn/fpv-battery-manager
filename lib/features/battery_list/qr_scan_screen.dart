// lib/features/battery_list/qr_scan_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  CameraController? _controller;
  final _scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanner.close();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning || _controller == null) return;
    setState(() => _scanning = true);
    try {
      final file = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final barcodes = await _scanner.processImage(inputImage);

      if (!mounted) return;

      if (barcodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NO QR CODE DETECTED — TRY AGAIN')),
        );
        return;
      }

      final value = barcodes.first.rawValue ?? '';
      if (value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('EMPTY QR CODE')),
        );
        return;
      }

      final battery = await ref.read(batteriesDaoProvider).getBatteryById(value);
      if (!mounted) return;

      if (battery != null) {
        context.pushReplacement('/battery/${battery.id}/log/capture');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BATTERY NOT FOUND IN DATABASE')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SCAN ERROR: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('// SCAN BATTERY QR //'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          // QR alignment box
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2),
              ),
            ),
          ),
          // Capture button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ALIGN QR CODE TO FRAME',
                    style: TextStyle(
                      color: AppColors.accent,
                      letterSpacing: 3,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _scan,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: _scanning
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.qr_code_scanner,
                              color: AppColors.accent, size: 32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
