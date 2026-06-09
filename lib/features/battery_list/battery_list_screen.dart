// lib/features/battery_list/battery_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import 'battery_list_provider.dart';

class BatteryListScreen extends ConsumerWidget {
  const BatteryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteries = ref.watch(batteriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('// LIPO MGR //'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: batteries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ERROR: $e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Text(
                  'NO BATTERIES\nADD ONE BELOW',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 2,
                      ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _BatteryTile(battery: list[i]),
              ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'qr',
            mini: true,
            onPressed: () => context.push('/scan'),
            backgroundColor: AppColors.surface,
            child:
                const Icon(Icons.qr_code_scanner, color: AppColors.accent),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => context.push('/add'),
            backgroundColor: AppColors.accent,
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

// ── Battery tile with long-press action sheet ─────────────────────────────────

class _BatteryTile extends ConsumerWidget {
  final Battery battery;
  const _BatteryTile({required this.battery});

  void _longPress(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    battery.label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accent,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${battery.cellCount}S · ${battery.capacityMah}mAh',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            _actionTile(
              context: context,
              sheetCtx: sheetCtx,
              icon: Icons.open_in_new,
              color: AppColors.accent,
              label: 'OPEN',
              onTap: () => context.push('/battery/${battery.id}'),
            ),
            _actionTile(
              context: context,
              sheetCtx: sheetCtx,
              icon: Icons.bar_chart,
              color: AppColors.textSecondary,
              label: 'CHARTS',
              onTap: () =>
                  context.push('/battery/${battery.id}/charts'),
            ),
            _actionTile(
              context: context,
              sheetCtx: sheetCtx,
              icon: Icons.edit,
              color: AppColors.textSecondary,
              label: 'RENAME',
              onTap: () => _showRenameDialog(context, ref),
            ),
            _actionTile(
              context: context,
              sheetCtx: sheetCtx,
              icon: Icons.content_copy,
              color: AppColors.textSecondary,
              label: 'DUPLICATE',
              onTap: () => _showDuplicateDialog(context, ref),
            ),
            _actionTile(
              context: context,
              sheetCtx: sheetCtx,
              icon: Icons.delete_outline,
              color: AppColors.warning,
              label: 'DELETE',
              onTap: () => _showDeleteDialog(context, ref),
              labelColor: AppColors.warning,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required BuildContext sheetCtx,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          letterSpacing: 2,
          color: labelColor ?? AppColors.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.pop(sheetCtx);
        onTap();
      },
    );
  }

  Future<void> _showRenameDialog(BuildContext context, WidgetRef ref) async {
    final full =
        await ref.read(batteriesDaoProvider).getBatteryById(battery.id);
    if (!context.mounted) return;
    final labelCtrl = TextEditingController(text: battery.label);
    final notesCtrl =
        TextEditingController(text: full?.notes ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(),
        title: const Text('// RENAME //'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration:
                  const InputDecoration(labelText: 'LABEL'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration:
                  const InputDecoration(labelText: 'NOTES'),
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
                    id: battery.id,
                    label: labelCtrl.text.trim().isEmpty
                        ? battery.label
                        : labelCtrl.text.trim(),
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

  Future<void> _showDuplicateDialog(
      BuildContext context, WidgetRef ref) async {
    final labelCtrl =
        TextEditingController(text: '${battery.label} COPY');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(),
        title: const Text('// DUPLICATE //'),
        content: TextField(
          controller: labelCtrl,
          decoration:
              const InputDecoration(labelText: 'NEW LABEL'),
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
              await ref.read(batteriesDaoProvider).duplicateBattery(
                    sourceId: battery.id,
                    newId: newId,
                    newLabel: labelCtrl.text.trim().isEmpty
                        ? '${battery.label} COPY'
                        : labelCtrl.text.trim(),
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

  Future<void> _showDeleteDialog(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(),
        title: const Text('// DELETE //'),
        content: Text(
          'Permanently delete "${battery.label}" and all its charge logs?',
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
      await ref.read(batteriesDaoProvider).deleteBattery(battery.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/battery/${battery.id}'),
      onLongPress: () => _longPress(context, ref),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    battery.label.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  ),
                  Text(
                    '${battery.cellCount}S · ${battery.capacityMah}MAH',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
