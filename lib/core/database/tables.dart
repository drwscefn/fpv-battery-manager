// lib/core/database/tables.dart
import 'package:drift/drift.dart';

class Batteries extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  IntColumn get cellCount => integer()();
  IntColumn get capacityMah => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChargeLogs extends Table {
  TextColumn get id => text()();
  TextColumn get batteryId => text().references(Batteries, #id)();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get cellVoltages => text()();
  TextColumn get cellIr => text()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
