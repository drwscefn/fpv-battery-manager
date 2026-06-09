// lib/core/models/health_flag.dart
enum HealthFlagLevel { red, yellow }

enum HealthFlagType {
  cellDelta,
  lowCellVoltage,
  highIrAbsolute,
  irDelta,
  cellDeltaTrend,
  irTrend,
  overvoltage,
  deepDischarge,
  highCycleCount,
  puffed,
}

class HealthFlag {
  final HealthFlagType type;
  final HealthFlagLevel level;
  final String message;

  const HealthFlag({
    required this.type,
    required this.level,
    required this.message,
  });
}
