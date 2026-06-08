// lib/core/database/charge_logs_dao.dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

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

  Future<List<ChargeLog>> getRecentLogs(String batteryId, {int limit = 5}) =>
      (_db.select(_db.chargeLogs)
            ..where((t) => t.batteryId.equals(batteryId))
            ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
            ..limit(limit))
          .get();

  Future<void> insertLog({
    required String id,
    required String batteryId,
    required List<double> cellVoltages,
    required List<int> cellIr,
    String? notes,
  }) =>
      _db.into(_db.chargeLogs).insert(ChargeLogsCompanion.insert(
            id: id,
            batteryId: batteryId,
            loggedAt: DateTime.now(),
            cellVoltages: jsonEncode(cellVoltages),
            cellIr: jsonEncode(cellIr),
            notes: Value(notes),
          ));

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
