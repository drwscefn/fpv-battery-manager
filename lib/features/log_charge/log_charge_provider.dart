// lib/features/log_charge/log_charge_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/log_type.dart';
import '../../core/ocr/ocr_service.dart';

class LogChargeState {
  final String? imagePath;
  final List<double> voltages;
  final List<int> irValues;
  final int cellCount;
  final String notes;
  final bool processing;
  final LogType logType;

  const LogChargeState({
    this.imagePath,
    this.voltages = const [],
    this.irValues = const [],
    this.cellCount = 0,
    this.notes = '',
    this.processing = false,
    this.logType = LogType.postCharge,
  });

  LogChargeState copyWith({
    String? imagePath,
    List<double>? voltages,
    List<int>? irValues,
    int? cellCount,
    String? notes,
    bool? processing,
    LogType? logType,
  }) =>
      LogChargeState(
        imagePath: imagePath ?? this.imagePath,
        voltages: voltages ?? this.voltages,
        irValues: irValues ?? this.irValues,
        cellCount: cellCount ?? this.cellCount,
        notes: notes ?? this.notes,
        processing: processing ?? this.processing,
        logType: logType ?? this.logType,
      );
}

class LogChargeNotifier extends FamilyNotifier<LogChargeState, String> {
  final _ocr = OcrService();

  @override
  LogChargeState build(String arg) => const LogChargeState();

  void initForBattery(int cellCount) {
    state = state.copyWith(
      cellCount: cellCount,
      voltages: List.filled(cellCount, 0.0),
      irValues: List.filled(cellCount, 0),
    );
  }

  Future<void> setImagePath(String path) async {
    state = state.copyWith(imagePath: path, processing: true);
    final parsed = await _ocr.recognizeFromPath(path);
    final cc = state.cellCount;
    final v = cc > 0
        ? List.generate(cc, (i) => i < parsed.voltages.length ? parsed.voltages[i] : 0.0)
        : parsed.voltages;
    final ir = cc > 0
        ? List.generate(cc, (i) => i < parsed.irValues.length ? parsed.irValues[i] : 0)
        : parsed.irValues;
    state = state.copyWith(voltages: v, irValues: ir, processing: false);
  }

  void updateVoltage(int index, double value) {
    final updated = List<double>.from(state.voltages);
    if (index < updated.length) updated[index] = value;
    state = state.copyWith(voltages: updated);
  }

  void updateIr(int index, int value) {
    final updated = List<int>.from(state.irValues);
    if (index < updated.length) updated[index] = value;
    state = state.copyWith(irValues: updated);
  }

  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void setLogType(LogType t) => state = state.copyWith(logType: t);
}

final logChargeProvider =
    NotifierProvider.family<LogChargeNotifier, LogChargeState, String>(
  LogChargeNotifier.new,
);
