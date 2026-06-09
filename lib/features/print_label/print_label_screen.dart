// lib/features/print_label/print_label_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/database/database_provider.dart';
import '../../core/printing/niimbot_service.dart';
import '../../core/theme/app_theme.dart';

class PrintLabelScreen extends ConsumerWidget {
  final String batteryId;
  const PrintLabelScreen({super.key, required this.batteryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteriesDao = ref.watch(batteriesDaoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('// PRINT QR LABEL //')),
      body: FutureBuilder(
        future: batteriesDao.getBatteryById(batteryId),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                const SizedBox(height: 32),
                _PrintButton(batteryId: batteryId, batteryLabel: battery.label),
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
  const _PrintButton(
      {required this.batteryId, required this.batteryLabel});

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
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            'BLE ERROR: $_error',
            style: const TextStyle(
                color: AppColors.warning, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(
                    content: Text(
                        'Use the Niimbot app to print the QR shown above'))),
            child: const Text('SHARE INSTEAD'),
          ),
        ],
      ],
    );
  }
}
