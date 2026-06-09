// lib/features/battery_detail/battery_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/health_flag.dart';
import '../../core/models/log_type.dart';
import '../../core/theme/app_theme.dart';
import 'battery_detail_provider.dart';

class BatteryDetailScreen extends ConsumerStatefulWidget {
  final String batteryId;
  const BatteryDetailScreen({super.key, required this.batteryId});

  @override
  ConsumerState<BatteryDetailScreen> createState() =>
      _BatteryDetailScreenState();
}

class _BatteryDetailScreenState extends ConsumerState<BatteryDetailScreen> {
  Future<void> _showEditDialog(BuildContext context) async {
    final battery =
        await ref.read(batteriesDaoProvider).getBatteryById(widget.batteryId);
    if (battery == null || !context.mounted) return;

    final labelCtrl = TextEditingController(text: battery.label);
    final notesCtrl = TextEditingController(text: battery.notes ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(),
        title: const Text('// RENAME BATTERY //'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'LABEL'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(labelText: 'NOTES'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(batteriesDaoProvider).updateBattery(
                    id: widget.batteryId,
                    label: labelCtrl.text.trim(),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('SAVE',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    labelCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _showDuplicateDialog(BuildContext context) async {
    final battery =
        await ref.read(batteriesDaoProvider).getBatteryById(widget.batteryId);
    if (battery == null || !context.mounted) return;

    final labelCtrl =
        TextEditingController(text: '${battery.label} COPY');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(),
        title: const Text('// DUPLICATE BATTERY //'),
        content: TextField(
          controller: labelCtrl,
          decoration: const InputDecoration(labelText: 'NEW LABEL'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final newId = const Uuid().v4();
              final label = labelCtrl.text.trim().isEmpty
                  ? '${battery.label} COPY'
                  : labelCtrl.text.trim();
              await ref.read(batteriesDaoProvider).duplicateBattery(
                    sourceId: widget.batteryId,
                    newId: newId,
                    newLabel: label,
                  );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.push('/battery/$newId');
              }
            },
            child: const Text('DUPLICATE',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    labelCtrl.dispose();
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(),
        title: const Text('// DELETE BATTERY //'),
        content: const Text(
          'This will permanently delete the battery and ALL charge logs. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE',
                style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(batteriesDaoProvider).deleteBattery(widget.batteryId);
      if (context.mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final battery = ref.watch(batteryDetailProvider(widget.batteryId));
    final logs = ref.watch(batteryLogsProvider(widget.batteryId));
    final health = ref.watch(batteryHealthProvider(widget.batteryId));

    return Scaffold(
      appBar: AppBar(
        title: battery.maybeWhen(
          data: (b) => Text('// ${b?.label ?? '...'} //'),
          orElse: () => const Text('// BATTERY //'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Charts',
            onPressed: () =>
                context.push('/battery/${widget.batteryId}/charts'),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'QR Label',
            onPressed: () =>
                context.push('/battery/${widget.batteryId}/print'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(),
            onSelected: (v) {
              if (v == 'rename') _showEditDialog(context);
              if (v == 'duplicate') _showDuplicateDialog(context);
              if (v == 'delete') _showDeleteDialog(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'rename',
                child: Text('RENAME'),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: Text('DUPLICATE'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('DELETE',
                    style: TextStyle(color: AppColors.warning)),
              ),
            ],
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
            context.push('/battery/${widget.batteryId}/log/capture'),
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
          Row(
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  LogType.fromDb(log.logType).label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
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
