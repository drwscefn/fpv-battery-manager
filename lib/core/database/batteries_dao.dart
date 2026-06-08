import 'package:drift/drift.dart';
import 'database.dart';

class BatteriesDao {
  final AppDatabase _db;
  BatteriesDao(this._db);

  Future<List<Battery>> getAllBatteries() =>
      _db.select(_db.batteries).get();

  Stream<List<Battery>> watchAllBatteries() =>
      _db.select(_db.batteries).watch();

  Future<Battery?> getBatteryById(String id) =>
      (_db.select(_db.batteries)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> insertBattery({
    required String id,
    required String label,
    required int cellCount,
    required int capacityMah,
    String? notes,
  }) =>
      _db.into(_db.batteries).insert(BatteriesCompanion.insert(
            id: id,
            label: label,
            cellCount: cellCount,
            capacityMah: capacityMah,
            notes: Value(notes),
            createdAt: DateTime.now(),
          ));

  Future<void> updateBattery({
    required String id,
    required String label,
    String? notes,
  }) =>
      (_db.update(_db.batteries)..where((t) => t.id.equals(id))).write(
        BatteriesCompanion(
          label: Value(label),
          notes: Value(notes),
        ),
      );

  Future<void> deleteBattery(String id) =>
      (_db.delete(_db.batteries)..where((t) => t.id.equals(id))).go();
}
