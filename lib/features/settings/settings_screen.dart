// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backup/backup_service.dart';
import '../../core/database/database_provider.dart';
import '../../core/health/thresholds.dart';
import '../../core/theme/app_theme.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('// SETTINGS //')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ERROR: $e')),
        data: (thresholds) => _SettingsForm(thresholds: thresholds),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  final HealthThresholds thresholds;
  const _SettingsForm({required this.thresholds});

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late final TextEditingController _cellDelta;
  late final TextEditingController _minCellV;
  late final TextEditingController _maxIr;
  late final TextEditingController _irDelta;
  late final TextEditingController _maxChargeV;
  late final TextEditingController _minFlightV;
  late final TextEditingController _maxCycles;

  @override
  void initState() {
    super.initState();
    _cellDelta =
        TextEditingController(text: widget.thresholds.maxCellDelta.toString());
    _minCellV =
        TextEditingController(text: widget.thresholds.minCellVoltage.toString());
    _maxIr =
        TextEditingController(text: widget.thresholds.maxIrAbsolute.toString());
    _irDelta =
        TextEditingController(text: widget.thresholds.maxIrDelta.toString());
    _maxChargeV = TextEditingController(
        text: widget.thresholds.maxChargeVoltage.toString());
    _minFlightV = TextEditingController(
        text: widget.thresholds.minFlightCellVoltage.toString());
    _maxCycles =
        TextEditingController(text: widget.thresholds.maxCycleCount.toString());
  }

  @override
  void dispose() {
    _cellDelta.dispose();
    _minCellV.dispose();
    _maxIr.dispose();
    _irDelta.dispose();
    _maxChargeV.dispose();
    _minFlightV.dispose();
    _maxCycles.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.thresholds.copyWith(
      maxCellDelta:
          double.tryParse(_cellDelta.text) ?? widget.thresholds.maxCellDelta,
      minCellVoltage:
          double.tryParse(_minCellV.text) ?? widget.thresholds.minCellVoltage,
      maxIrAbsolute:
          int.tryParse(_maxIr.text) ?? widget.thresholds.maxIrAbsolute,
      maxIrDelta: int.tryParse(_irDelta.text) ?? widget.thresholds.maxIrDelta,
      maxChargeVoltage: double.tryParse(_maxChargeV.text) ??
          widget.thresholds.maxChargeVoltage,
      minFlightCellVoltage: double.tryParse(_minFlightV.text) ??
          widget.thresholds.minFlightCellVoltage,
      maxCycleCount:
          int.tryParse(_maxCycles.text) ?? widget.thresholds.maxCycleCount,
    );
    await ref.read(settingsProvider.notifier).save(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('THRESHOLDS SAVED')),
      );
    }
  }

  Future<void> _export() async {
    final batteriesDao = ref.read(batteriesDaoProvider);
    final logsDao = ref.read(chargeLogsDaoProvider);
    try {
      await BackupService.exportBackup(batteriesDao, logsDao);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('EXPORT FAILED: $e')),
        );
      }
    }
  }

  Future<void> _import() async {
    final batteriesDao = ref.read(batteriesDaoProvider);
    final logsDao = ref.read(chargeLogsDaoProvider);
    final result = await BackupService.importBackup(batteriesDao, logsDao);
    if (!mounted) return;
    if (result.cancelled) return;
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('IMPORT FAILED: ${result.error}')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'IMPORTED: ${result.batteriesAdded} BATTERIES, ${result.logsAdded} LOGS',
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            letterSpacing: 3,
            fontSize: 11,
          ),
        ),
      );

  Widget _field(TextEditingController ctrl, String label, String hint,
          {bool decimal = true}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('VOLTAGE THRESHOLDS'),
        _field(_maxChargeV, 'MAX CHARGE VOLTAGE/CELL (V)', '4.22'),
        _field(_minFlightV, 'MIN POST-FLIGHT VOLTAGE/CELL (V)', '3.3'),
        _field(_minCellV, 'MIN CELL VOLTAGE GENERAL (V)', '3.5'),
        _field(_cellDelta, 'MAX CELL DELTA (V)', '0.05'),
        _section('IR THRESHOLDS'),
        _field(_maxIr, 'MAX IR ABSOLUTE (mΩ)', '8', decimal: false),
        _field(_irDelta, 'MAX IR CELL DELTA (mΩ)', '3', decimal: false),
        _section('CYCLE COUNT'),
        _field(_maxCycles, 'MAX CYCLES BEFORE WARNING', '150', decimal: false),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _save,
          child: const Text('SAVE THRESHOLDS'),
        ),

        // ── Backup ──────────────────────────────────────────────────────────
        _section('BACKUP & RESTORE'),
        const Text(
          'Export saves all batteries and charge logs as a JSON file.\nImport adds new entries from a backup without overwriting existing data.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload),
          label: const Text('EXPORT BACKUP'),
          onPressed: _export,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('IMPORT BACKUP'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.border),
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: _import,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
