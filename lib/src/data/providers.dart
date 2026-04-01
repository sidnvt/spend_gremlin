import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_db.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

