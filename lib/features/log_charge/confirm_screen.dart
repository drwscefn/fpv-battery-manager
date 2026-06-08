// lib/features/log_charge/confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'log_charge_provider.dart';

class ConfirmScreen extends ConsumerWidget {
  final String batteryId;
  const ConfirmScreen({super.key, required this.batteryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logChargeProvider(batteryId));

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
          ...List.generate(
            state.voltages.isEmpty ? 1 : state.voltages.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextFormField(
                initialValue: state.voltages.isEmpty
                    ? ''
                    : state.voltages[i].toStringAsFixed(3),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration:
                    InputDecoration(labelText: 'CELL ${i + 1} (V)'),
                onChanged: (v) {
                  final d = double.tryParse(v);
                  if (d != null) {
                    ref
                        .read(logChargeProvider(batteryId).notifier)
                        .updateVoltage(i, d);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'INTERNAL RESISTANCE',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 3,
                ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            state.irValues.isEmpty ? 1 : state.irValues.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextFormField(
                initialValue: state.irValues.isEmpty
                    ? ''
                    : state.irValues[i].toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'CELL ${i + 1} IR (mΩ)'),
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null) {
                    ref
                        .read(logChargeProvider(batteryId).notifier)
                        .updateIr(i, n);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: state.voltages.isEmpty
                ? null
                : () => context.push(
                    '/battery/$batteryId/log/save'),
            child: const Text('LOOKS GOOD →'),
          ),
        ],
      ),
    );
  }
}
