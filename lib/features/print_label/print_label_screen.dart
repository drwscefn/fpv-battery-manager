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
import '../../core/theme/app_theme.dart';

enum _LabelSize {
  small('SMALL', 120.0, '~25×25mm'),
  medium('MEDIUM', 200.0, '~50×50mm'),
  large('LARGE', 280.0, '~75×75mm');

  const _LabelSize(this.label, this.px, this.hint);
  final String label;
  final double px;
  final String hint;
}

class PrintLabelScreen extends ConsumerStatefulWidget {
  final String batteryId;
  const PrintLabelScreen({super.key, required this.batteryId});

  @override
  ConsumerState<PrintLabelScreen> createState() => _PrintLabelScreenState();
}

class _PrintLabelScreenState extends ConsumerState<PrintLabelScreen> {
  final _qrKey = GlobalKey();
  _LabelSize _size = _LabelSize.medium;

  Future<Uint8List?> _captureQrBytes() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    final bytes = await _captureQrBytes();
    if (bytes == null) return;
    await Gal.putImageBytes(bytes, album: 'FPV Battery');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SAVED TO GALLERY')),
      );
    }
  }

  Future<void> _share() async {
    final bytes = await _captureQrBytes();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qr_${widget.batteryId}.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'LIPO MGR QR Label');
  }

  @override
  Widget build(BuildContext context) {
    final batteriesDao = ref.watch(batteriesDaoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('// QR LABEL //')),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Size selector
                Text(
                  'PRINT SIZE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 3,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _LabelSize.values.map((s) {
                    final selected = s == _size;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selected
                                ? AppColors.accent
                                : Colors.transparent,
                            foregroundColor: selected
                                ? Colors.black
                                : AppColors.textSecondary,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.border,
                            ),
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => setState(() => _size = s),
                          child: Text(s.label,
                              style: const TextStyle(
                                  fontSize: 11, letterSpacing: 1)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  'TELL YOUR PRINTER: ${_size.hint}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // QR preview
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: battery.id,
                              version: QrVersions.auto,
                              size: _size.px,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              battery.label.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${battery.cellCount}S · ${battery.capacityMah}MAH',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: const Text('SAVE TO GALLERY'),
                  onPressed: _saveToGallery,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('SHARE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.border),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: _share,
                ),
                const SizedBox(height: 16),
                Text(
                  'SAVE TO GALLERY OR SHARE, THEN OPEN IN YOUR PRINTER APP.\nSET PRINT SIZE TO ${_size.hint} FOR BEST SCANNING.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
