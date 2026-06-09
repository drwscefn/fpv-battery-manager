// lib/core/database/charge_logs_dao.dart
import 'dart:convert';
import 'package:drift/drift.dart';
import '../models/log_type.dart';
import 'database.dart';

class ChargeLogsDao {
  final AppDatabase _db;
  ChargeLogsDao(this._db);

  Future<List<ChargeLog>> getLogsForBattery(String batteryId) =>
      (_db.select(_db.chargeLogs)
            ..where((t) => t.batteryId.equals(batteryId))
            ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
          .get();

  Stream<List<ChargeLog>> watchLogsForBattery(String batteryId) =>
      (_db.select(_db.chargeLogs)
            ..where((t) => t.batteryId.equals(batteryId))
            ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
          .watch();

  Future<List<ChargeLog>> getRecentLogs(String batteryId, {int limit = 10}) =>
      (_db.select(_db.chargeLogs)
            ..where((t) => t.batteryId.equals(batteryId))
            ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
            ..limit(limit))
          .get();

  Future<List<ChargeLog>> getAllLogs() =>
      (_db.select(_db.chargeLogs)
            ..orderBy([(t) => OrderingTerm.asc(t.loggedAt)]))
          .get();

  Future<int> countLogsOfType(String batteryId, String logType) =>
      (_db.select(_db.chargeLogs)
            ..where((t) =>
                t.batteryId.equals(batteryId) & t.logType.equals(logType)))
          .get()
          .then((rows) => rows.length);

  Future<void> insertLog({
    required String id,
    required String batteryId,
    required List<double> cellVoltages,
    required List<int> cellIr,
    LogType logType = LogType.postCharge,
    String? notes,
    DateTime? loggedAt,
  }) =>
      _db.into(_db.chargeLogs).insert(ChargeLogsCompanion.insert(
            id: id,
            batteryId: batteryId,
            loggedAt: loggedAt ?? DateTime.now(),
            cellVoltages: jsonEncode(cellVoltages),
            cellIr: jsonEncode(cellIr),
            logType: Value(logType.dbValue),
            notes: Value(notes),
          ));

  // Used by backup import — inserts only if the ID does not already exist.
  Future<void> insertLogIfNew({
    required String id,
    required String batteryId,
    required List<double> cellVoltages,
    required List<int> cellIr,
    required String logType,
    required DateTime loggedAt,
    String? notes,
  }) =>
      _db.into(_db.chargeLogs).insert(
            ChargeLogsCompanion.insert(
              id: id,
              batteryId: batteryId,
              loggedAt: loggedAt,
              cellVoltages: jsonEncode(cellVoltages),
              cellIr: jsonEncode(cellIr),
              logType: Value(logType),
              notes: Value(notes),
            ),
            mode: InsertMode.insertOrIgnore,
          );

  Future<void> updateLog({
    required String id,
    required List<double> cellVoltages,
    required List<int> cellIr,
    String? notes,
  }) =>
      (_db.update(_db.chargeLogs)..where((t) => t.id.equals(id))).write(
        ChargeLogsCompanion(
          cellVoltages: Value(jsonEncode(cellVoltages)),
          cellIr: Value(jsonEncode(cellIr)),
          notes: Value(notes),
        ),
      );

  Future<void> deleteLog(String id) =>
      (_db.delete(_db.chargeLogs)..where((t) => t.id.equals(id))).go();
}
