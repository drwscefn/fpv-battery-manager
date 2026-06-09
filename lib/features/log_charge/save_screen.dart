// lib/features/log_charge/save_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_provider.dart';
import '../../core/health/health_service.dart';
import '../../core/health/thresholds.dart';
import '../../core/models/health_flag.dart';
import '../../core/models/log_type.dart';
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
          logType: state.logType,
          notes:
              _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );

    final thresholds = await HealthThresholds.load();
    final battery =
        await ref.read(batteriesDaoProvider).getBatteryById(widget.batteryId);
    final cycleCount = await ref
        .read(chargeLogsDaoProvider)
        .countLogsOfType(widget.batteryId, 'post_charge');
    final flags = HealthService.computeFlags(
      recentVoltages: [state.voltages],
      recentIr: [state.irValues],
      recentLogTypes: [state.logType.dbValue],
      totalChargeCycles: cycleCount,
      isPuffed: battery?.isPuffed ?? false,
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
    final logType = ref.watch(logChargeProvider(widget.batteryId)).logType;
    return Scaffold(
      appBar: AppBar(title: const Text('// ADD NOTE + SAVE //')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'LOG TYPE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 3,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: LogType.values.map((t) {
                final selected = logType == t;
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => ref
                          .read(
                              logChargeProvider(widget.batteryId).notifier)
                          .setLogType(t),
                      child: Text(
                        t.label,
                        style: const TextStyle(
                            fontSize: 10, letterSpacing: 1),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
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
