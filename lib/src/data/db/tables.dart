import 'package:drift/drift.dart';

enum CategoryType { core, custom, misc }

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get emoji => text().withDefault(const Constant('🦝'))();
  IntColumn get type => intEnum<CategoryType>()();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
  IntColumn get limitCents => integer().withDefault(const Constant(10000))(); // ₹100 default per-category warning limit
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get amountCents => integer()();
  TextColumn get name => text().nullable()();
  DateTimeColumn get occurredOn => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get dailyLimitCents => integer().withDefault(const Constant(200000))(); // ₹2,000
  IntColumn get weeklyLimitCents => integer().withDefault(const Constant(1200000))(); // ₹12,000
  IntColumn get monthlyLimitCents => integer().withDefault(const Constant(4500000))(); // ₹45,000
  IntColumn get miscLimitCents => integer().withDefault(const Constant(10000))(); // ₹100

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
