// lib/features/add_battery/add_battery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';

class AddBatteryScreen extends ConsumerStatefulWidget {
  const AddBatteryScreen({super.key});

  @override
  ConsumerState<AddBatteryScreen> createState() => _AddBatteryScreenState();
}

class _AddBatteryScreenState extends ConsumerState<AddBatteryScreen> {
  final _label = TextEditingController();
  final _capacity = TextEditingController();
  int _cellCount = 6;
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _capacity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty || _capacity.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final id = const Uuid().v4();
    await ref.read(batteriesDaoProvider).insertBattery(
          id: id,
          label: _label.text.trim().toUpperCase(),
          cellCount: _cellCount,
          capacityMah: int.parse(_capacity.text.trim()),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (mounted) context.go('/battery/$id/print');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('// ADD BATTERY //')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'LABEL (e.g. 6S RACE #1)'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'CELL COUNT: ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _cellCount,
                dropdownColor: AppColors.surface,
                items: [1, 2, 3, 4, 5, 6, 7, 8]
                    .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text(
                            '${n}S',
                            style: const TextStyle(color: AppColors.accent),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _cellCount = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _capacity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'CAPACITY (mAh)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'NOTES (optional)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'SAVING...' : 'SAVE + PRINT QR LABEL'),
          ),
        ],
      ),
    );
  }
}
