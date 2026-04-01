import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos.dart';
import 'tables.dart';

export 'tables.dart' show CategoryType;

part 'app_db.g.dart';

@DriftDatabase(
  tables: [Categories, Expenses, AppSettings],
  daos: [CategoriesDao, ExpensesDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seed();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(categories, categories.limitCents);
          }
          if (from < 3) {
            await m.alterTable(TableMigration(appSettings));
          }
          if (from < 4) {
            // Restore missing columns back to table by invoking table alteration
            await m.alterTable(TableMigration(appSettings));
          }
        },
      );

  Future<void> _seed() async {
    await into(appSettings).insert(
      const AppSettingsCompanion(),
      mode: InsertMode.insertOrIgnore,
    );

    // Core categories always present.
    await into(categories).insert(
      CategoriesCompanion.insert(
        name: 'Food',
        emoji: const Value('🍛'),
        type: CategoryType.core,
        limitCents: const Value(80000),
        sortOrder: const Value(10),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    await into(categories).insert(
      CategoriesCompanion.insert(
        name: 'Travel',
        emoji: const Value('🚌'),
        type: CategoryType.core,
        limitCents: const Value(50000),
        sortOrder: const Value(20),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    await into(categories).insert(
      CategoriesCompanion.insert(
        name: 'Misc',
        emoji: const Value('📦'),
        type: CategoryType.misc,
        includeInTotal: const Value(false),
        limitCents: const Value(10000),
        sortOrder: const Value(999),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'spend_gremlin.sqlite');
}

