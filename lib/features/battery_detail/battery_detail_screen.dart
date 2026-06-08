// lib/features/battery_detail/battery_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/models/health_flag.dart';
import '../../core/theme/app_theme.dart';
import 'battery_detail_provider.dart';

class BatteryDetailScreen extends ConsumerWidget {
  final String batteryId;
  const BatteryDetailScreen({super.key, required this.batteryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battery = ref.watch(batteryDetailProvider(batteryId));
    final logs = ref.watch(batteryLogsProvider(batteryId));
    final health = ref.watch(batteryHealthProvider(batteryId));

    return Scaffold(
      appBar: AppBar(
        title: battery.maybeWhen(
          data: (b) => Text('// ${b?.label ?? '...'} //'),
          orElse: () => const Text('// BATTERY //'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => context.push('/battery/$batteryId/print'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          health.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (flags) => _HealthCard(flags: flags),
          ),
          const SizedBox(height: 16),
          Text(
            'CHARGE HISTORY',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 3,
                ),
          ),
          const SizedBox(height: 8),
          logs.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('ERROR: $e'),
            data: (list) => list.isEmpty
                ? const Text(
                    'NO LOGS YET',
                    style:
                        TextStyle(color: AppColors.textSecondary),
                  )
                : Column(
                    children: list.map((l) => _LogTile(log: l)).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/battery/$batteryId/log/capture'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.camera_alt),
        label: const Text(
          'LOG CHARGE',
          style: TextStyle(letterSpacing: 2),
        ),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final List<HealthFlag> flags;
  const _HealthCard({required this.flags});

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.healthy),
          color: AppColors.surface,
        ),
        child: const Row(children: [
          Icon(Icons.check, color: AppColors.healthy, size: 16),
          SizedBox(width: 8),
          Text(
            'ALL HEALTHY',
            style: TextStyle(color: AppColors.healthy, letterSpacing: 2),
          ),
        ]),
      );
    }
    return Column(
      children: flags.map((f) {
        final color = f.level == HealthFlagLevel.red
            ? AppColors.warning
            : AppColors.accent;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            color: AppColors.surface,
          ),
          child: Row(children: [
            Icon(
              f.level == HealthFlagLevel.red
                  ? Icons.warning
                  : Icons.trending_up,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                f.message,
                style: TextStyle(color: color, letterSpacing: 1),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

class _LogTile extends StatelessWidget {
  final ChargeLog log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final voltages =
        (jsonDecode(log.cellVoltages) as List).cast<double>();
    final ir = (jsonDecode(log.cellIr) as List).cast<int>();
    final dateStr =
        DateFormat('MMM d · HH:mm').format(log.loggedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            voltages.map((v) => v.toStringAsFixed(3)).join(' · '),
            style: const TextStyle(letterSpacing: 1, fontSize: 12),
          ),
          if (ir.isNotEmpty)
            Text(
              'IR: ${ir.map((v) => '${v}mΩ').join(' · ')}',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1),
            ),
        ],
      ),
    );
  }
}
