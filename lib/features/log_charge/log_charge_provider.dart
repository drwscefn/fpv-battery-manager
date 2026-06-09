// lib/features/log_charge/log_charge_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/log_type.dart';
import '../../core/ocr/ocr_service.dart';

class LogChargeState {
  final String? imagePath;
  final List<double> voltages;
  final List<int> irValues;
  final String notes;
  final bool processing;
  final LogType logType;

  const LogChargeState({
    this.imagePath,
    this.voltages = const [],
    this.irValues = const [],
    this.notes = '',
    this.processing = false,
    this.logType = LogType.postCharge,
  });

  LogChargeState copyWith({
    String? imagePath,
    List<double>? voltages,
    List<int>? irValues,
    String? notes,
    bool? processing,
    LogType? logType,
  }) =>
      LogChargeState(
        imagePath: imagePath ?? this.imagePath,
        voltages: voltages ?? this.voltages,
        irValues: irValues ?? this.irValues,
        notes: notes ?? this.notes,
        processing: processing ?? this.processing,
        logType: logType ?? this.logType,
      );
}

class LogChargeNotifier extends FamilyNotifier<LogChargeState, String> {
  final _ocr = OcrService();

  @override
  LogChargeState build(String arg) => const LogChargeState();

  Future<void> setImagePath(String path) async {
    state = state.copyWith(imagePath: path, processing: true);
    final parsed = await _ocr.recognizeFromPath(path);
    state = state.copyWith(
      voltages: parsed.voltages,
      irValues: parsed.irValues,
      processing: false,
    );
  }

  void updateVoltage(int index, double value) {
    final updated = [...state.voltages];
    if (index < updated.length) updated[index] = value;
    state = state.copyWith(voltages: updated);
  }

  void updateIr(int index, int value) {
    final updated = [...state.irValues];
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
