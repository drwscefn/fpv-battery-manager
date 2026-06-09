// lib/features/log_charge/capture_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import 'log_charge_provider.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  final String batteryId;
  const CaptureScreen({super.key, required this.batteryId});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _controller;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initBattery();
  }

  Future<void> _initBattery() async {
    final battery = await ref
        .read(batteriesDaoProvider)
        .getBatteryById(widget.batteryId);
    if (battery != null) {
      ref
          .read(logChargeProvider(widget.batteryId).notifier)
          .initForBattery(battery.cellCount);
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing || _controller == null) return;
    setState(() => _capturing = true);
    final file = await _controller!.takePicture();
    ref
        .read(logChargeProvider(widget.batteryId).notifier)
        .setImagePath(file.path);
    if (mounted) context.push('/battery/${widget.batteryId}/log/confirm');
  }

  void _enterManually() {
    context.push('/battery/${widget.batteryId}/log/confirm');
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
        title: const Text('// AIM AT CHARGER SCREEN //'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _enterManually,
            child: const Text(
              'MANUAL',
              style: TextStyle(color: AppColors.accent, letterSpacing: 2),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          CustomPaint(
            painter: _CropOverlayPainter(),
            size: Size.infinite,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: AppColors.accent, width: 3),
                    shape: BoxShape.circle,
                  ),
                  child: _capturing
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.camera_alt,
                          color: AppColors.accent, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cropRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: size.width * 0.85,
      height: size.height * 0.35,
    );

    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, cropRect.top), dimPaint);
    canvas.drawRect(
        Rect.fromLTWH(0, cropRect.bottom, size.width,
            size.height - cropRect.bottom),
        dimPaint);
    canvas.drawRect(
        Rect.fromLTWH(
            0, cropRect.top, cropRect.left, cropRect.height),
        dimPaint);
    canvas.drawRect(
        Rect.fromLTWH(cropRect.right, cropRect.top,
            size.width - cropRect.right, cropRect.height),
        dimPaint);

    final borderPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, borderPaint);

    const tickLen = 16.0;
    final tickPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3;
    final corners = <(Offset, Offset, Offset)>[
      (cropRect.topLeft, Offset(cropRect.left + tickLen, cropRect.top), Offset(cropRect.left, cropRect.top + tickLen)),
      (cropRect.topRight, Offset(cropRect.right - tickLen, cropRect.top), Offset(cropRect.right, cropRect.top + tickLen)),
      (cropRect.bottomLeft, Offset(cropRect.left + tickLen, cropRect.bottom), Offset(cropRect.left, cropRect.bottom - tickLen)),
      (cropRect.bottomRight, Offset(cropRect.right - tickLen, cropRect.bottom), Offset(cropRect.right, cropRect.bottom - tickLen)),
    ];
    for (final (origin, h, v) in corners) {
      canvas.drawLine(origin, h, tickPaint);
      canvas.drawLine(origin, v, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
