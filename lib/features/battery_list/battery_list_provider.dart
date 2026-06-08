// lib/features/battery_list/battery_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/database/database_provider.dart';

final batteriesStreamProvider = StreamProvider<List<Battery>>((ref) {
  return ref.watch(batteriesDaoProvider).watchAllBatteries();
});
