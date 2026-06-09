// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/health/thresholds.dart';
import '../../core/theme/app_theme.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('// THRESHOLDS //')),
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

  @override
  void initState() {
    super.initState();
    _cellDelta = TextEditingController(
        text: widget.thresholds.maxCellDelta.toString());
    _minCellV = TextEditingController(
        text: widget.thresholds.minCellVoltage.toString());
    _maxIr = TextEditingController(
        text: widget.thresholds.maxIrAbsolute.toString());
    _irDelta = TextEditingController(
        text: widget.thresholds.maxIrDelta.toString());
  }

  @override
  void dispose() {
    _cellDelta.dispose();
    _minCellV.dispose();
    _maxIr.dispose();
    _irDelta.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.thresholds.copyWith(
      maxCellDelta: double.tryParse(_cellDelta.text) ??
          widget.thresholds.maxCellDelta,
      minCellVoltage: double.tryParse(_minCellV.text) ??
          widget.thresholds.minCellVoltage,
      maxIrAbsolute: int.tryParse(_maxIr.text) ??
          widget.thresholds.maxIrAbsolute,
      maxIrDelta: int.tryParse(_irDelta.text) ??
          widget.thresholds.maxIrDelta,
    );
    await ref.read(settingsProvider.notifier).save(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('THRESHOLDS SAVED')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'RED FLAG THRESHOLDS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 3,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cellDelta,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'MAX CELL DELTA (V)',
            hintText: '0.05',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _minCellV,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'MIN CELL VOLTAGE (V)',
            hintText: '3.5',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maxIr,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'MAX IR ABSOLUTE (mΩ)',
            hintText: '8',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _irDelta,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'MAX IR DELTA (mΩ)',
            hintText: '3',
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _save,
          child: const Text('SAVE THRESHOLDS'),
        ),
      ],
    );
  }
}
