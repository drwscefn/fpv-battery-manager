// lib/features/battery_detail/battery_detail_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/database/database_provider.dart';
import '../../core/health/health_service.dart';
import '../../core/health/thresholds.dart';
import '../../core/models/health_flag.dart';

final batteryDetailProvider =
    StreamProvider.family<Battery?, String>((ref, id) {
  return ref.watch(batteriesDaoProvider).watchAllBatteries().map(
        (list) => list.where((b) => b.id == id).firstOrNull,
      );
});

final batteryLogsProvider =
    StreamProvider.family<List<ChargeLog>, String>((ref, id) {
  return ref.watch(chargeLogsDaoProvider).watchLogsForBattery(id);
});

final batteryHealthProvider =
    FutureProvider.family<List<HealthFlag>, String>((ref, id) async {
  final logs =
      await ref.read(chargeLogsDaoProvider).getRecentLogs(id, limit: 5);
  final thresholds = await HealthThresholds.load();
  final voltages = logs
      .map((l) => (jsonDecode(l.cellVoltages) as List).cast<double>())
      .toList();
  final irValues = logs
      .map((l) => (jsonDecode(l.cellIr) as List).cast<int>())
      .toList();
  return HealthService.computeFlags(
    recentVoltages: voltages,
    recentIr: irValues,
    thresholds: thresholds,
  );
});
