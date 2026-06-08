// lib/core/health/health_service.dart
import '../models/health_flag.dart';
import 'thresholds.dart';

class HealthService {
  static List<HealthFlag> computeFlags({
    required List<List<double>> recentVoltages,
    required List<List<int>> recentIr,
    required HealthThresholds thresholds,
  }) {
    final flags = <HealthFlag>[];

    if (recentVoltages.isEmpty) return flags;

    final latestV = recentVoltages.last;
    final latestIr = recentIr.isNotEmpty ? recentIr.last : <int>[];

    // --- Red flags from latest log ---

    if (latestV.isNotEmpty) {
      final delta = latestV.reduce((a, b) => a > b ? a : b) -
          latestV.reduce((a, b) => a < b ? a : b);
      if (delta > thresholds.maxCellDelta) {
        flags.add(HealthFlag(
          type: HealthFlagType.cellDelta,
          level: HealthFlagLevel.red,
          message:
              'CELL DELTA ${delta.toStringAsFixed(3)}V > ${thresholds.maxCellDelta}V',
        ));
      }

      for (final v in latestV) {
        if (v < thresholds.minCellVoltage) {
          flags.add(HealthFlag(
            type: HealthFlagType.lowCellVoltage,
            level: HealthFlagLevel.red,
            message:
                'CELL ${latestV.indexOf(v) + 1} LOW: ${v.toStringAsFixed(3)}V',
          ));
          break;
        }
      }
    }

    if (latestIr.isNotEmpty) {
      for (final ir in latestIr) {
        if (ir > thresholds.maxIrAbsolute) {
          flags.add(HealthFlag(
            type: HealthFlagType.highIrAbsolute,
            level: HealthFlagLevel.red,
            message:
                'CELL ${latestIr.indexOf(ir) + 1} HIGH IR: ${ir}mΩ > ${thresholds.maxIrAbsolute}mΩ',
          ));
          break;
        }
      }

      if (latestIr.length > 1) {
        for (var i = 0; i < latestIr.length; i++) {
          final others = [...latestIr]..removeAt(i);
          final avg = others.reduce((a, b) => a + b) / others.length;
          if (latestIr[i] - avg > thresholds.maxIrDelta) {
            flags.add(HealthFlag(
              type: HealthFlagType.irDelta,
              level: HealthFlagLevel.red,
              message:
                  'CELL ${i + 1} IR DELTA: ${latestIr[i]}mΩ (avg: ${avg.toStringAsFixed(1)}mΩ)',
            ));
            break;
          }
        }
      }
    }

    // --- Yellow trend flags (need >= 3 logs) ---

    if (recentVoltages.length >= 3) {
      final deltas = recentVoltages.map((v) {
        if (v.isEmpty) return 0.0;
        return v.reduce((a, b) => a > b ? a : b) -
            v.reduce((a, b) => a < b ? a : b);
      }).toList();
      if (_hasPositiveSlope(deltas)) {
        flags.add(const HealthFlag(
          type: HealthFlagType.cellDeltaTrend,
          level: HealthFlagLevel.yellow,
          message: 'CELL DELTA RISING OVER LAST LOGS',
        ));
      }
    }

    if (recentIr.length >= 3) {
      final avgIrs = recentIr.map((log) {
        if (log.isEmpty) return 0.0;
        return log.reduce((a, b) => a + b) / log.length;
      }).toList();
      if (_hasPositiveSlope(avgIrs)) {
        flags.add(const HealthFlag(
          type: HealthFlagType.irTrend,
          level: HealthFlagLevel.yellow,
          message: 'AVG IR RISING OVER LAST LOGS',
        ));
      }
    }

    return flags;
  }

  static bool _hasPositiveSlope(List<double> values) {
    final n = values.length;
    final xMean = (n - 1) / 2.0;
    final yMean = values.reduce((a, b) => a + b) / n;
    var num = 0.0;
    var den = 0.0;
    for (var i = 0; i < n; i++) {
      num += (i - xMean) * (values[i] - yMean);
      den += (i - xMean) * (i - xMean);
    }
    return den > 0 && (num / den) > 0;
  }
}
