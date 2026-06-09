// lib/core/health/thresholds.dart
import 'package:shared_preferences/shared_preferences.dart';

class HealthThresholds {
  final double maxCellDelta;
  final double minCellVoltage;
  final int maxIrAbsolute;
  final int maxIrDelta;
  final double maxChargeVoltage;
  final double minFlightCellVoltage;
  final int maxCycleCount;

  const HealthThresholds({
    this.maxCellDelta = 0.05,
    this.minCellVoltage = 3.5,
    this.maxIrAbsolute = 8,
    this.maxIrDelta = 3,
    this.maxChargeVoltage = 4.22,
    this.minFlightCellVoltage = 3.3,
    this.maxCycleCount = 150,
  });

  static const _keyDelta = 'threshold_cell_delta';
  static const _keyMinV = 'threshold_min_v';
  static const _keyMaxIr = 'threshold_max_ir';
  static const _keyIrDelta = 'threshold_ir_delta';
  static const _keyMaxChargeV = 'threshold_max_charge_v';
  static const _keyMinFlightV = 'threshold_min_flight_v';
  static const _keyCycles = 'threshold_max_cycles';

  static Future<HealthThresholds> load() async {
    final p = await SharedPreferences.getInstance();
    return HealthThresholds(
      maxCellDelta: p.getDouble(_keyDelta) ?? 0.05,
      minCellVoltage: p.getDouble(_keyMinV) ?? 3.5,
      maxIrAbsolute: p.getInt(_keyMaxIr) ?? 8,
      maxIrDelta: p.getInt(_keyIrDelta) ?? 3,
      maxChargeVoltage: p.getDouble(_keyMaxChargeV) ?? 4.22,
      minFlightCellVoltage: p.getDouble(_keyMinFlightV) ?? 3.3,
      maxCycleCount: p.getInt(_keyCycles) ?? 150,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_keyDelta, maxCellDelta);
    await p.setDouble(_keyMinV, minCellVoltage);
    await p.setInt(_keyMaxIr, maxIrAbsolute);
    await p.setInt(_keyIrDelta, maxIrDelta);
    await p.setDouble(_keyMaxChargeV, maxChargeVoltage);
    await p.setDouble(_keyMinFlightV, minFlightCellVoltage);
    await p.setInt(_keyCycles, maxCycleCount);
  }

  HealthThresholds copyWith({
    double? maxCellDelta,
    double? minCellVoltage,
    int? maxIrAbsolute,
    int? maxIrDelta,
    double? maxChargeVoltage,
    double? minFlightCellVoltage,
    int? maxCycleCount,
  }) =>
      HealthThresholds(
        maxCellDelta: maxCellDelta ?? this.maxCellDelta,
        minCellVoltage: minCellVoltage ?? this.minCellVoltage,
        maxIrAbsolute: maxIrAbsolute ?? this.maxIrAbsolute,
        maxIrDelta: maxIrDelta ?? this.maxIrDelta,
        maxChargeVoltage: maxChargeVoltage ?? this.maxChargeVoltage,
        minFlightCellVoltage: minFlightCellVoltage ?? this.minFlightCellVoltage,
        maxCycleCount: maxCycleCount ?? this.maxCycleCount,
      );
}
