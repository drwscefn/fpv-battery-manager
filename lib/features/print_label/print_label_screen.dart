// lib/features/print_label/print_label_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/database_provider.dart';
import '../../core/printing/niimbot_service.dart';
import '../../core/theme/app_theme.dart';

class PrintLabelScreen extends ConsumerStatefulWidget {
  final String batteryId;
  const PrintLabelScreen({super.key, required this.batteryId});

  @override
  ConsumerState<PrintLabelScreen> createState() => _PrintLabelScreenState();
}

class _PrintLabelScreenState extends ConsumerState<PrintLabelScreen> {
  final _qrKey = GlobalKey();

  Future<Uint8List?> _captureQrBytes() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveToGallery(String batteryId) async {
    final bytes = await _captureQrBytes();
    if (bytes == null) return;
    await Gal.putImageBytes(bytes, album: 'FPV Battery');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SAVED TO GALLERY')),
      );
    }
  }

  Future<void> _shareQr(String batteryId) async {
    final bytes = await _captureQrBytes();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qr_$batteryId.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'FPV Battery QR Label');
  }

  @override
  Widget build(BuildContext context) {
    final batteriesDao = ref.watch(batteriesDaoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('// PRINT QR LABEL //')),
      body: FutureBuilder(
        future: batteriesDao.getBatteryById(widget.batteryId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final battery = snapshot.data;
          if (battery == null) {
            return const Center(child: Text('BATTERY NOT FOUND'));
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(
                            data: battery.id,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: AppColors.background,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.textPrimary,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            battery.label.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.accent,
                                  letterSpacing: 3,
                                ),
                          ),
                          Text(
                            '${battery.cellCount}S · ${battery.capacityMah}MAH',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _PrintButton(
                  batteryId: widget.batteryId,
                  batteryLabel: battery.label,
                  onSave: () => _saveToGallery(widget.batteryId),
                  onShare: () => _shareQr(widget.batteryId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrintButton extends ConsumerStatefulWidget {
  final String batteryId;
  final String batteryLabel;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  const _PrintButton({
    required this.batteryId,
    required this.batteryLabel,
    this.onSave,
    this.onShare,
  });

  @override
  ConsumerState<_PrintButton> createState() => _PrintButtonState();
}

class _PrintButtonState extends ConsumerState<_PrintButton> {
  final _niimbot = NiimbotService();
  bool _printing = false;
  String? _error;

  Future<void> _print() async {
    setState(() {
      _printing = true;
      _error = null;
    });
    try {
      await _niimbot.connect();
      await _niimbot.printLabel(widget.batteryLabel.toUpperCase());
      await _niimbot.disconnect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LABEL SENT TO PRINTER')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.print),
          label: Text(_printing ? 'CONNECTING...' : 'PRINT VIA NIIMBOT'),
          onPressed: _printing ? null : _print,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.save_alt),
          label: const Text('SAVE TO GALLERY'),
          onPressed: () => widget.onSave?.call(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            'BLE ERROR: $_error',
            style: const TextStyle(color: AppColors.warning, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => widget.onSave?.call(),
                child: const Text('SAVE TO GALLERY'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onShare?.call(),
                child: const Text('SHARE'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
