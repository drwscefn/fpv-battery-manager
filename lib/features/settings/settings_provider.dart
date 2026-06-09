// lib/features/settings/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/health/thresholds.dart';

class SettingsNotifier extends AsyncNotifier<HealthThresholds> {
  @override
  Future<HealthThresholds> build() => HealthThresholds.load();

  Future<void> save(HealthThresholds thresholds) async {
    await thresholds.save();
    state = AsyncData(thresholds);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, HealthThresholds>(
  SettingsNotifier.new,
);
