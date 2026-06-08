// lib/features/battery_list/battery_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart';
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
                itemBuilder: (ctx, i) {
                  final b = list[i];
                  return _BatteryTile(battery: b);
                },
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
            child: const Icon(Icons.qr_code_scanner, color: AppColors.accent),
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

class _BatteryTile extends StatelessWidget {
  final Battery battery;
  const _BatteryTile({required this.battery});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/battery/${battery.id}'),
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
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
