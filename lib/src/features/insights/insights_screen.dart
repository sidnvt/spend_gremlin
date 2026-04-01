import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/money.dart';
import '../../data/db/app_db.dart';
import '../../data/providers.dart';
import '../common/app_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    // Pick date range
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, 1, 1);
    final lastDate = DateTime(now.year, now.month, now.day);

    final range = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: lastDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.green,
              onPrimary: Colors.black,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.bg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (range == null) return;

    final db = ref.read(databaseProvider);
    final categories = await db.categoriesDao.watchAll().first;
    final categoryById = {for (final c in categories) c.id: c};

    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day).add(const Duration(days: 1));

    final expenses = await db.expensesDao.getForRange(start: start, end: end);

    // Build CSV
    final buf = StringBuffer();
    buf.writeln('Date,Category,Name,Amount (₹),Included');
    for (final e in expenses) {
      final cat = categoryById[e.categoryId];
      final catName = cat != null ? '${cat.emoji} ${cat.name}' : 'Unknown';
      final date = DateFormat('yyyy-MM-dd').format(e.occurredOn);
      final name = (e.name ?? '').replaceAll(',', ' ').replaceAll('"', "'");
      final amount = (e.amountCents / 100).toStringAsFixed(0);
      final included = e.includeInTotal ? 'Yes' : 'No';
      buf.writeln('$date,"$catName","$name",$amount,$included');
    }

    // Write to temp file
    final dir = await getTemporaryDirectory();
    final dateStr = '${DateFormat('yyyyMMdd').format(range.start)}_${DateFormat('yyyyMMdd').format(range.end)}';
    final file = File('${dir.path}/spend_gremlin_$dateStr.csv');
    await file.writeAsString(buf.toString());

    // Share
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Spend Gremlin Export ($dateStr)',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final last7Start = today.subtract(const Duration(days: 6));

    final categoriesAsync = ref.watch(categoriesProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final monthExpensesAsync = ref.watch(_expensesRangeProvider((monthStart, nextMonthStart)));
    final last7ExpensesAsync = ref.watch(_expensesRangeProvider((last7Start, tomorrow)));

    // Responsive horizontal padding for curved display
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = (screenWidth * 0.05).clamp(16.0, 28.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.green, size: 22),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: categoriesAsync.when(
            data: (categories) => settingsAsync.when(
              data: (settings) => monthExpensesAsync.when(
                data: (monthExpenses) => last7ExpensesAsync.when(
                  data: (last7Expenses) {
                    final byId = {for (final c in categories) c.id: c};
                    final misc = categories.where((c) => c.type == CategoryType.misc).toList();
                    final miscId = misc.isEmpty ? null : misc.first.id;

                    Map<DateTime, int> includedTotalByDay(List<Expense> exps) {
                      final map = <DateTime, int>{};
                      for (final e in exps) {
                        final d = DateTime(e.occurredOn.year, e.occurredOn.month, e.occurredOn.day);
                        final c = byId[e.categoryId];
                        if (c == null) continue;
                        if (c.includeInTotal && e.includeInTotal) {
                          map[d] = (map[d] ?? 0) + e.amountCents;
                        }
                      }
                      return map;
                    }

                    Map<DateTime, int> totalByDayAll(List<Expense> exps) {
                      final map = <DateTime, int>{};
                      for (final e in exps) {
                        final d = DateTime(e.occurredOn.year, e.occurredOn.month, e.occurredOn.day);
                        map[d] = (map[d] ?? 0) + e.amountCents;
                      }
                      return map;
                    }

                    final includedByDayMonth = includedTotalByDay(monthExpenses);
                    final includedByDay7 = includedTotalByDay(last7Expenses);

                    int streak() {
                      final today = DateTime(now.year, now.month, now.day);
                      var d = today;
                      var s = 0;
                      while (true) {
                        final t = includedByDayMonth[d] ?? 0;
                        if (t <= settings.dailyLimitCents) {
                          s++;
                          d = d.subtract(const Duration(days: 1));
                          if (d.isBefore(monthStart)) break;
                        } else {
                          break;
                        }
                      }
                      return s;
                    }

                    final streakDays = streak();

                    final dailyBars = List.generate(7, (i) {
                      final d = DateTime(last7Start.year, last7Start.month, last7Start.day).add(Duration(days: i));
                      return (d, includedByDay7[d] ?? 0);
                    });
                    final maxBar = dailyBars.map((e) => e.$2).fold<int>(0, (p, v) => v > p ? v : p);

                    final totalsByCategoryMonth = <int, int>{};
                    for (final e in monthExpenses) {
                      totalsByCategoryMonth[e.categoryId] = (totalsByCategoryMonth[e.categoryId] ?? 0) + e.amountCents;
                    }
                    final monthTotalAll = totalsByCategoryMonth.values.fold<int>(0, (p, v) => p + v);
                    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

                    final daysSoFar = now.day;
                    final avgPerDay = daysSoFar == 0 ? 0 : (includedByDayMonth.values.fold<int>(0, (p, v) => p + v) / daysSoFar).round();
                    final forecast = avgPerDay * daysInMonth;

                    final miscMonthTotal = miscId == null ? 0 : (totalsByCategoryMonth[miscId] ?? 0);
                    final miscByDay = totalByDayAll(monthExpenses.where((e) => e.categoryId == miscId).toList());
                    final miscOverDays = miscByDay.values.where((v) => v > settings.miscLimitCents).length;

                    final includedHeat = includedTotalByDay(monthExpenses);

                    return ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      children: [
                        Text(DateFormat('MMMM yyyy').format(now), style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2)),
                        const SizedBox(height: 10),
                        Text('streak', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        _InsightCard(
                          title: 'days under limit',
                          value: '$streakDays days',
                          valueColor: AppColors.green,
                          subtitle: 'this month: ${includedByDayMonth.values.where((v) => v <= settings.dailyLimitCents).length}/$daysInMonth',
                        ),
                        const SizedBox(height: 10),
                        Text('daily spend — last 7 days', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        _TrendBars(
                          items: dailyBars,
                          max: maxBar,
                          dailyLimitCents: settings.dailyLimitCents,
                        ),
                        const SizedBox(height: 10),
                        Text('category split this month', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        _CategorySplit(
                          categories: categories,
                          totalsByCategory: totalsByCategoryMonth,
                          monthTotalAll: monthTotalAll,
                        ),
                        const SizedBox(height: 10),
                        Text('monthly forecast', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        _ForecastCard(
                          projectedCents: forecast,
                          monthlyLimitCents: settings.monthlyLimitCents,
                          daysRemain: daysInMonth - now.day,
                        ),
                        const SizedBox(height: 10),
                        Text('daily limit breach log', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        _Heatmap(
                          monthStart: monthStart,
                          daysInMonth: daysInMonth,
                          totalsByDay: includedHeat,
                          dailyLimitCents: settings.dailyLimitCents,
                        ),
                        const SizedBox(height: 10),
                        Text('misc creep', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        _InsightCard(
                          title: 'misc this month',
                          value: Money.formatCents(miscMonthTotal),
                          valueColor: AppColors.red,
                          subtitle: miscId == null ? 'no misc category' : 'over limit on $miscOverDays of ${miscByDay.length} days',
                        ),
                      ],
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }
}

final _expensesRangeProvider = StreamProvider.family<List<Expense>, (DateTime, DateTime)>((ref, range) {
  final db = ref.watch(databaseProvider);
  return db.expensesDao.watchForRange(start: range.$1, end: range.$2);
});

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.title, required this.value, required this.valueColor, required this.subtitle});

  final String title;
  final String value;
  final Color valueColor;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w600, letterSpacing: 0.6)),
              Text(value, style: AppTypography.serifAmount(size: 15, color: valueColor, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.items, required this.max, required this.dailyLimitCents});

  final List<(DateTime, int)> items;
  final int max;
  final int dailyLimitCents;

  @override
  Widget build(BuildContext context) {
    Color colorFor(int cents) {
      if (dailyLimitCents <= 0) return AppColors.green;
      final pct = cents / dailyLimitCents;
      if (pct > 1.0) return AppColors.red;
      if (pct >= 0.9) return AppColors.amber;
      return AppColors.green;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final item in items)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: max == 0 ? 2 : (item.$2 / max * 48).clamp(2, 48).toDouble(),
                          decoration: BoxDecoration(
                            color: colorFor(item.$2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('E').format(item.$1).substring(0, 1), style: AppTypography.monoLabel(size: 10, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('■ under', style: AppTypography.monoLabel(size: 10, color: AppColors.green, weight: FontWeight.w500, letterSpacing: 0.2)),
              const SizedBox(width: 10),
              Text('■ near', style: AppTypography.monoLabel(size: 10, color: AppColors.amber, weight: FontWeight.w500, letterSpacing: 0.2)),
              const SizedBox(width: 10),
              Text('■ over', style: AppTypography.monoLabel(size: 10, color: AppColors.red, weight: FontWeight.w500, letterSpacing: 0.2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySplit extends StatelessWidget {
  const _CategorySplit({required this.categories, required this.totalsByCategory, required this.monthTotalAll});

  final List<Category> categories;
  final Map<int, int> totalsByCategory;
  final int monthTotalAll;

  Color colorFor(Category c) {
    return switch (c.type) {
      CategoryType.core => AppColors.green,
      CategoryType.custom => AppColors.amber,
      CategoryType.misc => AppColors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = categories
        .where((c) => totalsByCategory.containsKey(c.id))
        .toList()
      ..sort((a, b) => (totalsByCategory[b.id] ?? 0).compareTo(totalsByCategory[a.id] ?? 0));

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        children: [
          for (final c in items.take(6)) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${c.emoji} ${c.name}'.toLowerCase(), style: AppTypography.monoLabel(size: 12, color: c.type == CategoryType.misc ? AppColors.red : AppColors.text, weight: FontWeight.w500, letterSpacing: 0.2)),
                Text(
                  monthTotalAll == 0 ? '0%' : '${((totalsByCategory[c.id]! / monthTotalAll) * 100).round()}%',
                  style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 7,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              clipBehavior: Clip.antiAlias,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: monthTotalAll == 0 ? 0 : (totalsByCategory[c.id]! / monthTotalAll).clamp(0.0, 1.0).toDouble(),
                child: Container(color: colorFor(c)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.projectedCents, required this.monthlyLimitCents, required this.daysRemain});

  final int projectedCents;
  final int monthlyLimitCents;
  final int daysRemain;

  @override
  Widget build(BuildContext context) {
    final pct = monthlyLimitCents <= 0 ? 0.0 : projectedCents / monthlyLimitCents;
    final color = pct > 1.0 ? AppColors.red : AppColors.amber;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROJECTED SPEND', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w600, letterSpacing: 0.6)),
              Text(Money.formatCents(projectedCents), style: AppTypography.serifAmount(size: 15, color: color, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 7,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
            clipBehavior: Clip.antiAlias,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(color: color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).round()}% of monthly limit · $daysRemain days remain',
            style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.monthStart, required this.daysInMonth, required this.totalsByDay, required this.dailyLimitCents});

  final DateTime monthStart;
  final int daysInMonth;
  final Map<DateTime, int> totalsByDay;
  final int dailyLimitCents;

  Color colorFor(int cents) {
    if (dailyLimitCents <= 0) return AppColors.border;
    final pct = cents / dailyLimitCents;
    if (pct > 1.0) return AppColors.red;
    if (pct >= 0.9) return AppColors.amber;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var day = 1; day <= daysInMonth; day++)
            Builder(
              builder: (context) {
                final d = DateTime(monthStart.year, monthStart.month, day);
                final total = totalsByDay[d] ?? 0;
                final color = total == 0 ? AppColors.border : colorFor(total);
                return Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: total == 0 ? 0.35 : 1.0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
