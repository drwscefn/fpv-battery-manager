// lib/core/database/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'batteries_dao.dart';
import 'charge_logs_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final batteriesDaoProvider = Provider<BatteriesDao>(
  (ref) => BatteriesDao(ref.watch(databaseProvider)),
);

final chargeLogsDaoProvider = Provider<ChargeLogsDao>(
  (ref) => ChargeLogsDao(ref.watch(databaseProvider)),
);
