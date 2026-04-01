import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/money.dart';
import '../../data/db/app_db.dart';
import '../common/app_providers.dart';
import 'widgets/spend_ring.dart';

enum RingView { daily, weekly, monthly }

class RingViewNotifier extends Notifier<RingView> {
  @override
  RingView build() => RingView.daily;

  void set(RingView v) => state = v;
}

final ringViewProvider = NotifierProvider<RingViewNotifier, RingView>(RingViewNotifier.new);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final view = ref.watch(ringViewProvider);
    final tomorrow = today.add(const Duration(days: 1));

    final DateTime rangeStart;
    final DateTime rangeEnd;
    if (view == RingView.daily) {
      rangeStart = today;
      rangeEnd = tomorrow;
    } else if (view == RingView.weekly) {
      rangeStart = today.subtract(const Duration(days: 6));
      rangeEnd = tomorrow;
    } else {
      rangeStart = DateTime(today.year, today.month, 1);
      rangeEnd = tomorrow;
    }

    final categoriesAsync = ref.watch(categoriesProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final todayExpensesAsync = ref.watch(expensesForDayProvider(today));
    final rangeExpensesAsync = ref.watch(expensesForRangeProvider((rangeStart, rangeEnd)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (MediaQuery.of(context).size.width * 0.05).clamp(16.0, 28.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Text(
                  DateFormat('EEEE, d MMM yyyy').format(today),
                  style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                ),
              ),
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) => settingsAsync.when(
                    data: (settings) => todayExpensesAsync.when(
                      data: (todayExpenses) => rangeExpensesAsync.when(
                        data: (rangeExpenses) {
                        final categoryById = {for (final c in categories) c.id: c};

                        int includedTotalCents = 0;
                        final expensesByCategory = <int, List<Expense>>{};

                        for (final e in rangeExpenses) {
                          final c = categoryById[e.categoryId];
                          if (c == null) continue;
                          final include = e.includeInTotal && c.includeInTotal;
                          if (include) includedTotalCents += e.amountCents;
                        }

                        for (final e in todayExpenses) {
                          final c = categoryById[e.categoryId];
                          if (c == null) continue;
                          (expensesByCategory[e.categoryId] ??= []).add(e);
                        }

                        final dailyLimit = settings.dailyLimitCents;
                        final weeklyLimit = settings.weeklyLimitCents;
                        final monthlyLimit = settings.monthlyLimitCents;
                        int limitCents = dailyLimit;
                        String limitLabel = 'daily limit';
                        if (view == RingView.weekly) {
                          limitCents = weeklyLimit;
                          limitLabel = 'weekly limit';
                        } else if (view == RingView.monthly) {
                          limitCents = monthlyLimit;
                          limitLabel = 'monthly limit';
                        }

                        final percent = limitCents <= 0 ? 0.0 : includedTotalCents / limitCents;

                        final displayCategories = categories.where((c) => c.type != CategoryType.misc).toList()
                          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                        return ListView(
                          padding: const EdgeInsets.only(bottom: 10),
                          children: [
                            Center(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  RingView next = RingView.daily;
                                  if (view == RingView.daily) {
                                    next = RingView.weekly;
                                  } else if (view == RingView.weekly) {
                                    next = RingView.monthly;
                                  }
                                  ref.read(ringViewProvider.notifier).set(next);
                                },
                                child: SpendRing(
                                  spentCents: includedTotalCents,
                                  limitCents: limitCents,
                                  limitLabel: limitLabel,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ViewToggle(
                              value: view,
                              onChanged: (v) => ref.read(ringViewProvider.notifier).set(v),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "today's spend",
                              style: AppTypography.monoLabel(
                                size: 11,
                                color: AppColors.muted,
                                weight: FontWeight.w500,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...displayCategories.map((c) {
                              final exps = expensesByCategory[c.id] ?? const <Expense>[];
                              final spent = exps.fold<int>(0, (p, e) => p + e.amountCents);
                              final overBy = spent - c.limitCents;
                              final over = overBy > 0;
                              return _CategoryCard(
                                title: '${c.emoji} ${c.name}'.toUpperCase(),
                                badge: c.type == CategoryType.core ? 'core' : 'custom',
                                badgeColor: c.type == CategoryType.core ? AppColors.green : AppColors.amber,
                                amountCents: spent,
                                over: over,
                                lines: exps.take(3).map((e) => _ExpenseLine(name: e.name ?? 'Expense', amountCents: e.amountCents)).toList(),
                                warningText: over ? '⚠ over by ${Money.formatCents(overBy)} (limit ${Money.formatCents(c.limitCents)})' : null,
                                onTap: c.type == CategoryType.core ? () => context.go('/history') : null,
                              );
                            }),
                            ...categories.where((c) => c.type == CategoryType.misc).map((c) {
                              final exps = expensesByCategory[c.id] ?? const <Expense>[];
                              final spent = exps.fold<int>(0, (p, e) => p + e.amountCents);
                              final overBy = spent - c.limitCents;
                              final over = overBy > 0;
                              return _CategoryCard(
                                title: c.name.toUpperCase(),
                                badge: 'misc',
                                badgeColor: AppColors.red,
                                amountCents: spent,
                                over: over,
                                lines: exps.take(3).map((e) => _ExpenseLine(name: e.name ?? 'Misc item', amountCents: e.amountCents)).toList(),
                                warningText: over ? '⚠ over by ${Money.formatCents(overBy)} (limit ${Money.formatCents(c.limitCents)})' : null,
                                onTap: null,
                              );
                            }),
                            if (percent > 1.0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A0D0D),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.red, width: 1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '⚠ DAILY LIMIT EXCEEDED',
                                      style: AppTypography.monoLabel(size: 11, color: AppColors.red, weight: FontWeight.w600, letterSpacing: 0.3),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'over by ${Money.formatCents(includedTotalCents - limitCents)} — ${Money.formatCents(includedTotalCents)} spent of ${Money.formatCents(limitCents)}',
                                      style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.value, required this.onChanged});

  final RingView value;
  final ValueChanged<RingView> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, RingView v) {
      final active = value == v;
      return Expanded(
        child: TextButton(
          onPressed: () => onChanged(v),
          style: TextButton.styleFrom(
            backgroundColor: active ? AppColors.green : Colors.transparent,
            foregroundColor: active ? Colors.black : AppColors.muted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(vertical: 6),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppTypography.monoLabel(size: 11, color: active ? Colors.black : AppColors.muted, weight: FontWeight.w500, letterSpacing: 0.2)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          btn('daily', RingView.daily),
          btn('weekly', RingView.weekly),
          btn('monthly', RingView.monthly),
        ],
      ),
    );
  }
}

class _ExpenseLine {
  const _ExpenseLine({required this.name, required this.amountCents});
  final String name;
  final int amountCents;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.amountCents,
    required this.over,
    required this.lines,
    this.warningText,
    this.onTap,
  });

  final String title;
  final String badge;
  final Color badgeColor;
  final int amountCents;
  final bool over;
  final List<_ExpenseLine> lines;
  final String? warningText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = over ? AppColors.red : AppColors.border;
    final cardBg = over ? const Color(0xFF1A0D0D) : AppColors.card;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: over ? 1.5 : 0.7),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(title, style: AppTypography.monoLabel(size: 11, color: AppColors.text, weight: FontWeight.w600, letterSpacing: 0.8), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(badge, style: AppTypography.monoLabel(size: 10, color: badgeColor, weight: FontWeight.w500, letterSpacing: 0.2)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Money.formatCents(amountCents),
                      style: AppTypography.serifAmount(size: 15, color: over ? AppColors.red : AppColors.green, weight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l.name,
                            style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Money.formatCents(l.amountCents),
                          style: AppTypography.monoLabel(size: 11, color: AppColors.text, weight: FontWeight.w500, letterSpacing: 0.2),
                        ),
                      ],
                    ),
                  ),
                ),
                if (warningText != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A0D0D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      warningText!,
                      style: AppTypography.monoLabel(size: 10, color: AppColors.red, weight: FontWeight.w500, letterSpacing: 0.2),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

