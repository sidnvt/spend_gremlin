import 'package:drift/drift.dart';

import 'app_db.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<Category>> watchAll() {
    return (select(categories)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).watch();
  }

  Future<int> createCustomCategory({required String name, String emoji = '🦝'}) {
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: name,
        emoji: Value(emoji),
        type: CategoryType.custom,
        limitCents: const Value(25000),
        sortOrder: const Value(50),
      ),
    );
  }

  Future<void> setIncludeInTotal({required int categoryId, required bool include}) {
    return (update(categories)..where((t) => t.id.equals(categoryId))).write(
      CategoriesCompanion(includeInTotal: Value(include)),
    );
  }

  Future<void> deleteCategory(int id) async {
    await (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setLimit({required int categoryId, required int limitCents}) {
    return (update(categories)..where((t) => t.id.equals(categoryId))).write(
      CategoriesCompanion(limitCents: Value(limitCents)),
    );
  }
}

@DriftAccessor(tables: [Expenses, Categories])
class ExpensesDao extends DatabaseAccessor<AppDatabase> with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Stream<List<Expense>> watchForDay(DateTime dayStart) {
    final dayEnd = dayStart.add(const Duration(days: 1));
    return (select(expenses)
          ..where((t) => t.occurredOn.isBetweenValues(dayStart, dayEnd))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Stream<List<Expense>> watchForRange({required DateTime start, required DateTime end}) {
    return (select(expenses)
          ..where((t) => t.occurredOn.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.occurredOn), (t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  Future<List<Expense>> getForRange({required DateTime start, required DateTime end}) {
    return (select(expenses)
          ..where((t) => t.occurredOn.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm(expression: t.occurredOn), (t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<int> addExpense({
    required int categoryId,
    required int amountCents,
    String? name,
    required DateTime occurredOn,
    required bool includeInTotal,
  }) {
    return into(expenses).insert(
      ExpensesCompanion.insert(
        categoryId: categoryId,
        amountCents: amountCents,
        name: Value(name),
        occurredOn: occurredOn,
        includeInTotal: Value(includeInTotal),
      ),
    );
  }

  Future<void> setExpenseIncludeInTotal({required int expenseId, required bool include}) {
    return (update(expenses)..where((t) => t.id.equals(expenseId))).write(
      ExpensesCompanion(includeInTotal: Value(include)),
    );
  }

  Future<void> updateExpense({
    required int id,
    required int categoryId,
    required int amountCents,
    String? name,
    required DateTime occurredOn,
    required bool includeInTotal,
  }) {
    return (update(expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(
        categoryId: Value(categoryId),
        amountCents: Value(amountCents),
        name: Value(name),
        occurredOn: Value(occurredOn),
        includeInTotal: Value(includeInTotal),
      ),
    );
  }

  Future<void> deleteExpense(int id) async {
    await (delete(expenses)..where((t) => t.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<AppSetting> watch() {
    return (select(appSettings)..where((t) => t.id.equals(1))).watchSingle();
  }

  Future<AppSetting> getSettings() async {
    final row = await select(appSettings).getSingleOrNull();
    if (row != null) return row;

    await into(appSettings).insert(const AppSettingsCompanion());
    return await select(appSettings).getSingle();
  }

  Future<void> setLimits({
    int? dailyLimitCents,
    int? weeklyLimitCents,
    int? monthlyLimitCents,
    int? miscLimitCents,
  }) async {
    await update(appSettings).write(
      AppSettingsCompanion(
        dailyLimitCents: dailyLimitCents == null ? const Value.absent() : Value(dailyLimitCents),
        weeklyLimitCents: weeklyLimitCents == null ? const Value.absent() : Value(weeklyLimitCents),
        monthlyLimitCents: monthlyLimitCents == null ? const Value.absent() : Value(monthlyLimitCents),
        miscLimitCents: miscLimitCents == null ? const Value.absent() : Value(miscLimitCents),
      ),
    );
  }
}
