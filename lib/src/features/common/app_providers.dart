import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

final categoriesProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return db.categoriesDao.watchAll();
});

final settingsProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return db.settingsDao.watch();
});

final expensesForDayProvider = StreamProvider.family((ref, DateTime dayStart) {
  final db = ref.watch(databaseProvider);
  return db.expensesDao.watchForDay(dayStart);
});

final expensesForRangeProvider = StreamProvider.family((ref, (DateTime, DateTime) range) {
  final db = ref.watch(databaseProvider);
  return db.expensesDao.watchForRange(start: range.$1, end: range.$2);
});

