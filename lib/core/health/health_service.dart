// lib/core/health/health_service.dart
import '../models/health_flag.dart';
import 'thresholds.dart';

class HealthService {
  static List<HealthFlag> computeFlags({
    required List<List<double>> recentVoltages,
    required List<List<int>> recentIr,
    required List<String> recentLogTypes,
    required int totalChargeCycles,
    required bool isPuffed,
    required HealthThresholds thresholds,
  }) {
    final flags = <HealthFlag>[];

    // ── Puff — immediate retire ──────────────────────────────────────────────
    if (isPuffed) {
      flags.add(const HealthFlag(
        type: HealthFlagType.puffed,
        level: HealthFlagLevel.red,
        message: 'PUFFED — RETIRE IMMEDIATELY',
      ));
    }

    // ── Cycle count ──────────────────────────────────────────────────────────
    if (totalChargeCycles > thresholds.maxCycleCount) {
      flags.add(HealthFlag(
        type: HealthFlagType.highCycleCount,
        level: HealthFlagLevel.yellow,
        message:
            'CYCLE COUNT $totalChargeCycles > ${thresholds.maxCycleCount} — CONSIDER RETIRING',
      ));
    }

    if (recentVoltages.isEmpty) return flags;

    // ── Overvoltage — check most recent post-charge log ──────────────────────
    for (var i = 0; i < recentLogTypes.length; i++) {
      if (recentLogTypes[i] == 'post_charge' && i < recentVoltages.length) {
        final voltages = recentVoltages[i];
        for (var c = 0; c < voltages.length; c++) {
          if (voltages[c] > thresholds.maxChargeVoltage) {
            flags.add(HealthFlag(
              type: HealthFlagType.overvoltage,
              level: HealthFlagLevel.red,
              message:
                  'C${c + 1} OVERVOLTAGE: ${voltages[c].toStringAsFixed(3)}V > ${thresholds.maxChargeVoltage}V',
            ));
          }
        }
        break;
      }
    }

    // ── Deep discharge — check most recent post-flight log ───────────────────
    for (var i = 0; i < recentLogTypes.length; i++) {
      if (recentLogTypes[i] == 'post_flight' && i < recentVoltages.length) {
        final voltages = recentVoltages[i];
        for (var c = 0; c < voltages.length; c++) {
          if (voltages[c] < thresholds.minFlightCellVoltage) {
            flags.add(HealthFlag(
              type: HealthFlagType.deepDischarge,
              level: HealthFlagLevel.red,
              message:
                  'C${c + 1} DEEP DISCHARGE: ${voltages[c].toStringAsFixed(3)}V < ${thresholds.minFlightCellVoltage}V',
            ));
          }
        }
        break;
      }
    }

    // ── Red flags from latest log ────────────────────────────────────────────
    final latestV = recentVoltages.last;
    final latestIr = recentIr.isNotEmpty ? recentIr.last : <int>[];

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

      for (var i = 0; i < latestV.length; i++) {
        if (latestV[i] < thresholds.minCellVoltage) {
          flags.add(HealthFlag(
            type: HealthFlagType.lowCellVoltage,
            level: HealthFlagLevel.red,
            message: 'C${i + 1} LOW: ${latestV[i].toStringAsFixed(3)}V',
          ));
          break;
        }
      }
    }

    if (latestIr.isNotEmpty) {
      for (var i = 0; i < latestIr.length; i++) {
        if (latestIr[i] > thresholds.maxIrAbsolute) {
          flags.add(HealthFlag(
            type: HealthFlagType.highIrAbsolute,
            level: HealthFlagLevel.red,
            message:
                'C${i + 1} HIGH IR: ${latestIr[i]}mΩ > ${thresholds.maxIrAbsolute}mΩ',
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
                  'C${i + 1} IR DELTA: ${latestIr[i]}mΩ (avg: ${avg.toStringAsFixed(1)}mΩ)',
            ));
            break;
          }
        }
      }
    }

    // ── Yellow trend flags (need >= 3 logs) ──────────────────────────────────
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
          message: 'CELL IMBALANCE WORSENING OVER RECENT LOGS',
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
          message: 'AVG IR RISING OVER RECENT LOGS',
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
