// lib/features/log_charge/save_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_provider.dart';
import '../../core/health/health_service.dart';
import '../../core/health/thresholds.dart';
import '../../core/models/health_flag.dart';
import '../../core/theme/app_theme.dart';
import 'log_charge_provider.dart';

class SaveScreen extends ConsumerStatefulWidget {
  final String batteryId;
  const SaveScreen({super.key, required this.batteryId});

  @override
  ConsumerState<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends ConsumerState<SaveScreen> {
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = ref.read(logChargeProvider(widget.batteryId));
    final logId = const Uuid().v4();
    await ref.read(chargeLogsDaoProvider).insertLog(
          id: logId,
          batteryId: widget.batteryId,
          cellVoltages: state.voltages,
          cellIr: state.irValues,
          notes:
              _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );

    final thresholds = await HealthThresholds.load();
    final flags = HealthService.computeFlags(
      recentVoltages: [state.voltages],
      recentIr: [state.irValues],
      thresholds: thresholds,
    );
    final redFlags =
        flags.where((f) => f.level == HealthFlagLevel.red).toList();

    if (mounted && redFlags.isNotEmpty) {
      await _showRedFlagWarning(redFlags);
    } else if (mounted) {
      context.go('/battery/${widget.batteryId}');
    }
  }

  Future<void> _showRedFlagWarning(List<HealthFlag> flags) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(),
        title: const Row(children: [
          Icon(Icons.warning, color: AppColors.warning),
          SizedBox(width: 8),
          Text(
            '⚠ BATTERY WARNING',
            style: TextStyle(color: AppColors.warning, letterSpacing: 2),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: flags
              .map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '— ${f.message}',
                      style: const TextStyle(letterSpacing: 1),
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/battery/${widget.batteryId}');
            },
            child: const Text(
              'ACKNOWLEDGED',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('// ADD NOTE + SAVE //')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'SESSION NOTES (optional)',
                hintText: 'e.g. AFTER RACE · HOT PACK',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'SAVING...' : 'SAVE LOG'),
            ),
          ],
        ),
      ),
    );
  }
}
