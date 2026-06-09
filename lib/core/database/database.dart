// lib/core/database/database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';
part 'database.g.dart';

@DriftDatabase(tables: [Batteries, ChargeLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(chargeLogs, chargeLogs.logType);
          }
          if (from < 3) {
            await m.addColumn(batteries, batteries.isPuffed);
          }
        },
      );

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'fpv_batteries');
}
