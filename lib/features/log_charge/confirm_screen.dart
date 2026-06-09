// lib/features/log_charge/confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'log_charge_provider.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  final String batteryId;
  const ConfirmScreen({super.key, required this.batteryId});

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  List<TextEditingController> _vCtrls = [];
  List<TextEditingController> _irCtrls = [];
  int _builtForCellCount = 0;

  @override
  void dispose() {
    for (final c in _vCtrls) c.dispose();
    for (final c in _irCtrls) c.dispose();
    super.dispose();
  }

  void _rebuildControllers(LogChargeState state) {
    final cc = state.cellCount > 0 ? state.cellCount : state.voltages.length;
    if (cc == _builtForCellCount) return;

    for (final c in _vCtrls) c.dispose();
    for (final c in _irCtrls) c.dispose();

    _vCtrls = List.generate(cc, (i) {
      final v = i < state.voltages.length ? state.voltages[i] : 0.0;
      return TextEditingController(text: v > 0 ? v.toStringAsFixed(3) : '');
    });
    _irCtrls = List.generate(cc, (i) {
      final ir = i < state.irValues.length ? state.irValues[i] : 0;
      return TextEditingController(text: ir > 0 ? ir.toString() : '');
    });
    _builtForCellCount = cc;
  }

  void _syncOcrResults(LogChargeState state) {
    // Called when OCR finishes — fill controllers that are still blank
    final cc = state.cellCount > 0 ? state.cellCount : state.voltages.length;
    if (cc != _builtForCellCount) return;
    for (var i = 0; i < _vCtrls.length && i < state.voltages.length; i++) {
      if (_vCtrls[i].text.isEmpty && state.voltages[i] > 0) {
        _vCtrls[i].text = state.voltages[i].toStringAsFixed(3);
      }
    }
    for (var i = 0; i < _irCtrls.length && i < state.irValues.length; i++) {
      if (_irCtrls[i].text.isEmpty && state.irValues[i] > 0) {
        _irCtrls[i].text = state.irValues[i].toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logChargeProvider(widget.batteryId));
    final notifier = ref.read(logChargeProvider(widget.batteryId).notifier);

    if (state.processing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('PROCESSING OCR...',
                  style: TextStyle(letterSpacing: 2)),
            ],
          ),
        ),
      );
    }

    final cc = state.cellCount > 0 ? state.cellCount : state.voltages.length;
    if (cc > 0 && cc != _builtForCellCount) {
      _rebuildControllers(state);
    }
    // Sync in case OCR results just arrived into already-built controllers
    if (cc == _builtForCellCount && cc > 0) {
      _syncOcrResults(state);
    }

    final canSave = cc > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('// CONFIRM VALUES //')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'CELL VOLTAGES',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 3,
                ),
          ),
          const SizedBox(height: 8),
          if (cc == 0)
            const Text(
              'NO BATTERY DATA — GO BACK',
              style: TextStyle(color: AppColors.warning),
            )
          else
            ...List.generate(cc, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: _vCtrls[i],
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration:
                        InputDecoration(labelText: 'C${i + 1} VOLTAGE (V)'),
                    onChanged: (v) {
                      final d = double.tryParse(v);
                      if (d != null) notifier.updateVoltage(i, d);
                    },
                  ),
                )),
          const SizedBox(height: 16),
          Text(
            'INTERNAL RESISTANCE',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 3,
                ),
          ),
          const SizedBox(height: 8),
          if (cc > 0)
            ...List.generate(cc, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    controller: _irCtrls[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'C${i + 1} IR (mΩ)'),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null) notifier.updateIr(i, n);
                    },
                  ),
                )),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: canSave
                ? () => context.push('/battery/${widget.batteryId}/log/save')
                : null,
            child: const Text('LOOKS GOOD →'),
          ),
        ],
      ),
    );
  }
}
