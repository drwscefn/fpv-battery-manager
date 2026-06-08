// lib/core/health/thresholds.dart
import 'package:shared_preferences/shared_preferences.dart';

class HealthThresholds {
  final double maxCellDelta;
  final double minCellVoltage;
  final int maxIrAbsolute;
  final int maxIrDelta;

  const HealthThresholds({
    this.maxCellDelta = 0.05,
    this.minCellVoltage = 3.5,
    this.maxIrAbsolute = 8,
    this.maxIrDelta = 3,
  });

  static const _keyDelta = 'threshold_cell_delta';
  static const _keyMinV = 'threshold_min_v';
  static const _keyMaxIr = 'threshold_max_ir';
  static const _keyIrDelta = 'threshold_ir_delta';

  static Future<HealthThresholds> load() async {
    final p = await SharedPreferences.getInstance();
    return HealthThresholds(
      maxCellDelta: p.getDouble(_keyDelta) ?? 0.05,
      minCellVoltage: p.getDouble(_keyMinV) ?? 3.5,
      maxIrAbsolute: p.getInt(_keyMaxIr) ?? 8,
      maxIrDelta: p.getInt(_keyIrDelta) ?? 3,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_keyDelta, maxCellDelta);
    await p.setDouble(_keyMinV, minCellVoltage);
    await p.setInt(_keyMaxIr, maxIrAbsolute);
    await p.setInt(_keyIrDelta, maxIrDelta);
  }

  HealthThresholds copyWith({
    double? maxCellDelta,
    double? minCellVoltage,
    int? maxIrAbsolute,
    int? maxIrDelta,
  }) =>
      HealthThresholds(
        maxCellDelta: maxCellDelta ?? this.maxCellDelta,
        minCellVoltage: minCellVoltage ?? this.minCellVoltage,
        maxIrAbsolute: maxIrAbsolute ?? this.maxIrAbsolute,
        maxIrDelta: maxIrDelta ?? this.maxIrDelta,
      );
}
