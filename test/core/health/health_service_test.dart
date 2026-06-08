// test/core/health/health_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpv_battery_manager/core/health/health_service.dart';
import 'package:fpv_battery_manager/core/health/thresholds.dart';
import 'package:fpv_battery_manager/core/models/health_flag.dart';

void main() {
  const t = HealthThresholds(
    maxCellDelta: 0.05,
    minCellVoltage: 3.5,
    maxIrAbsolute: 8,
    maxIrDelta: 3,
  );

  group('single-log flags', () {
    test('no flags when all healthy', () {
      final flags = HealthService.computeFlags(
        recentVoltages: [[3.87, 3.87, 3.87, 3.87, 3.87, 3.87]],
        recentIr: [[3, 3, 3, 3, 3, 3]],
        thresholds: t,
      );
      expect(flags, isEmpty);
    });

    test('cell_delta red when delta > 0.05', () {
      final flags = HealthService.computeFlags(
        recentVoltages: [[3.87, 3.87, 3.87, 3.87, 3.87, 3.81]],
        recentIr: [[3, 3, 3, 3, 3, 3]],
        thresholds: t,
      );
      expect(flags.any((f) => f.type == HealthFlagType.cellDelta && f.level == HealthFlagLevel.red), isTrue);
    });

    test('low_cell_voltage red when cell < 3.5', () {
      final flags = HealthService.computeFlags(
        recentVoltages: [[3.87, 3.87, 3.87, 3.87, 3.87, 3.49]],
        recentIr: [[3, 3, 3, 3, 3, 3]],
        thresholds: t,
      );
      expect(flags.any((f) => f.type == HealthFlagType.lowCellVoltage), isTrue);
    });

    test('high_ir_abs red when ir > 8', () {
      final flags = HealthService.computeFlags(
        recentVoltages: [[3.87, 3.87, 3.87, 3.87, 3.87, 3.87]],
        recentIr: [[3, 3, 3, 3, 3, 9]],
        thresholds: t,
      );
      expect(flags.any((f) => f.type == HealthFlagType.highIrAbsolute), isTrue);
    });

    test('ir_delta red when one cell ir > avg others + 3', () {
      final flags = HealthService.computeFlags(
        recentVoltages: [[3.87, 3.87, 3.87, 3.87, 3.87, 3.87]],
        recentIr: [[3, 3, 3, 3, 3, 7]],
        thresholds: t,
      );
      expect(flags.any((f) => f.type == HealthFlagType.irDelta), isTrue);
    });
  });

  group('trend flags', () {
    test('cell_delta_trend yellow when delta is growing', () {
      final flags = HealthService.computeFlags(
        recentVoltages: [
          [3.87, 3.87],
          [3.87, 3.85],
          [3.87, 3.84],
          [3.87, 3.83],
          [3.87, 3.82],
        ],
        recentIr: List.generate(5, (_) => [3, 3]),
        thresholds: t,
      );
      expect(flags.any((f) => f.type == HealthFlagType.cellDeltaTrend), isTrue);
    });

    test('ir_trend yellow when avg ir is growing', () {
      final flags = HealthService.computeFlags(
        recentVoltages: List.generate(5, (_) => [3.87, 3.87]),
        recentIr: [
          [2, 2],
          [3, 3],
          [4, 4],
          [5, 5],
          [6, 6],
        ],
        thresholds: t,
      );
      expect(flags.any((f) => f.type == HealthFlagType.irTrend), isTrue);
    });

    test('no trend flag with fewer than 3 logs', () {
      final flags = HealthService.computeFlags(
        recentVoltages: [[3.87, 3.87]],
        recentIr: [[3, 3]],
        thresholds: t,
      );
      expect(flags.where((f) => f.level == HealthFlagLevel.yellow), isEmpty);
    });
  });
}
