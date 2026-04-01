import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/money.dart';
import '../../data/db/app_db.dart';
import '../../data/providers.dart';
import '../common/app_providers.dart';
import '../expenses/add_expense_sheet.dart';

class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void set(DateTime d) => state = DateTime(d.year, d.month, d.day);
}

final selectedDayProvider = NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final expensesAsync = ref.watch(expensesForDayProvider(day));

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMM d').format(day)),
      ),
      body: SafeArea(
        child: categoriesAsync.when(
          data: (categories) => settingsAsync.when(
            data: (settings) => expensesAsync.when(
              data: (expenses) {
                final core = categories.where((c) => c.type == CategoryType.core).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                final byId = {for (final c in categories) c.id: c};
                final dayTotalIncluded = expenses.fold<int>(0, (p, e) {
                  final c = byId[e.categoryId];
                  if (c == null) return p;
                  if (c.includeInTotal && e.includeInTotal) return p + e.amountCents;
                  return p;
                });

                final pct = settings.dailyLimitCents <= 0 ? 0 : (dayTotalIncluded / settings.dailyLimitCents * 100).round();

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (MediaQuery.of(context).size.width * 0.05).clamp(16.0, 28.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${DateFormat('MMM d').format(day)} — ${Money.formatCents(dayTotalIncluded)}',
                              style: AppTypography.serifAmount(size: 15, color: AppColors.text, weight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$pct% of limit',
                            style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _DayTabs(
                        selected: day,
                        onPick: (d) => ref.read(selectedDayProvider.notifier).set(d),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView(
                          children: [
                            for (final c in core) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 6),
                                child: Text(
                                  '${c.name.toLowerCase()} — tap to add/edit',
                                  style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _CoreCategoryCard(
                                category: c,
                                day: day,
                                expenses: expenses.where((e) => e.categoryId == c.id).toList(),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border, width: 0.7, style: BorderStyle.solid),
                              ),
                              child: Text(
                                'custom + misc — via + button',
                                style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _DayTabs extends StatelessWidget {
  const _DayTabs({required this.selected, required this.onPick});

  final DateTime selected;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final start = selected.subtract(const Duration(days: 2));
    final days = List.generate(5, (i) {
      final d = start.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });

    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: OutlinedButton(
                onPressed: () => onPick(d),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: d == selected ? AppColors.green : AppColors.border, width: 0.7),
                  backgroundColor: d == selected ? AppColors.green : Colors.transparent,
                  foregroundColor: d == selected ? Colors.black : AppColors.muted,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    DateFormat('EEE d').format(d),
                    style: AppTypography.monoLabel(size: 10, color: d == selected ? Colors.black : AppColors.muted, weight: FontWeight.w500, letterSpacing: 0.2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CoreCategoryCard extends ConsumerWidget {
  const _CoreCategoryCard({required this.category, required this.day, required this.expenses});

  final Category category;
  final DateTime day;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spent = expenses.fold<int>(0, (p, e) => p + e.amountCents);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                Text(category.name.toUpperCase(), style: AppTypography.monoLabel(size: 11, color: AppColors.text, weight: FontWeight.w600, letterSpacing: 0.8)),
                const Spacer(),
                Text(Money.formatCents(spent), style: AppTypography.serifAmount(size: 15, color: AppColors.green, weight: FontWeight.w600)),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddExpenseSheet(initialCategory: category, occurredOn: day),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text('+', style: TextStyle(fontSize: 18, color: AppColors.green)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final e in expenses)
              InkWell(
                onLongPress: () async {
                  final db = ref.read(databaseProvider);
                  await db.expensesDao.deleteExpense(e.id);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.name ?? 'Expense',
                          style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(Money.formatCents(e.amountCents), style: AppTypography.monoLabel(size: 11, color: AppColors.text, weight: FontWeight.w500, letterSpacing: 0.2)),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AddExpenseSheet(initialExpense: e),
                          );
                        },
                        child: const Icon(Icons.edit, size: 16, color: AppColors.muted),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          final db = ref.read(databaseProvider);
                          await db.expensesDao.setExpenseIncludeInTotal(expenseId: e.id, include: !e.includeInTotal);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border, width: 0.7),
                          ),
                          child: Text(
                            e.includeInTotal ? 'incl' : 'excl',
                            style: AppTypography.monoLabel(size: 8, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

