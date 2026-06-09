// lib/features/battery_list/qr_scan_screen.dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
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
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.high,
        enableAudio: false);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
    _controller!.startImageStream(_processFrame);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_processing) return;
    _processing = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;
      final barcodes = await _scanner.processImage(inputImage);
      if (barcodes.isEmpty) return;
      final value = barcodes.first.rawValue;
      if (value == null || value.isEmpty) return;

      await _controller?.stopImageStream();

      final battery =
          await ref.read(batteriesDaoProvider).getBatteryById(value);
      if (!mounted) return;

      if (battery != null) {
        context.pushReplacement('/battery/${battery.id}/log/capture');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BATTERY NOT FOUND')),
        );
        await _controller?.startImageStream(_processFrame);
        _processing = false;
      }
    } catch (_) {
      _processing = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _controller?.description;
    if (camera == null) return null;

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    // Concatenate all plane bytes (required for correct YUV data)
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21, // Android camera native format
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _scanner.close();
    super.dispose();
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
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: Text(
                'ALIGN QR CODE TO FRAME',
                style: TextStyle(
                  color: AppColors.accent,
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
