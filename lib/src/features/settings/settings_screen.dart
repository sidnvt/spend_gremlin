import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/money.dart';
import '../../data/db/app_db.dart';
import '../../data/providers.dart';
import '../common/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (MediaQuery.of(context).size.width * 0.05).clamp(16.0, 28.0),
          ),
          child: settingsAsync.when(
            data: (settings) => categoriesAsync.when(
              data: (categories) {
                final core = categories.where((c) => c.type == CategoryType.core).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                final misc = categories.where((c) => c.type == CategoryType.misc).toList();
                final custom = categories.where((c) => c.type == CategoryType.custom).toList()..sort((a, b) => a.name.compareTo(b.name));

                final customIncluded = custom.isEmpty ? true : custom.every((c) => c.includeInTotal);

                Future<void> editLimit(String title, int initialCents, ValueChanged<int> onSave) async {
                  final c = TextEditingController(text: Money.formatCents(initialCents));
                  final res = await showDialog<int>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text(title, style: AppTypography.serifAmount(size: 16, color: AppColors.text)),
                      content: TextField(
                        controller: c,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '₹ amount'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('cancel', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, letterSpacing: 0.2)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(Money.parseRupeesToCents(c.text)),
                          child: Text('save', style: AppTypography.monoLabel(size: 11, color: AppColors.green, weight: FontWeight.w600, letterSpacing: 0.2)),
                        ),
                      ],
                    ),
                  );
                  if (res == null) return;
                  onSave(res);
                }

                return ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  children: [
                    Text('spend limits', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    _SettingsRow(
                      label: 'daily limit',
                      value: Money.formatCents(settings.dailyLimitCents),
                      onTap: () => editLimit('Daily limit', settings.dailyLimitCents, (v) async {
                        final db = ref.read(databaseProvider);
                        await db.settingsDao.setLimits(dailyLimitCents: v);
                      }),
                    ),
                    _SettingsRow(
                      label: 'weekly limit',
                      value: Money.formatCents(settings.weeklyLimitCents),
                      onTap: () => editLimit('Weekly limit', settings.weeklyLimitCents, (v) async {
                        final db = ref.read(databaseProvider);
                        await db.settingsDao.setLimits(weeklyLimitCents: v);
                      }),
                    ),
                    _SettingsRow(
                      label: 'monthly limit',
                      value: Money.formatCents(settings.monthlyLimitCents),
                      onTap: () => editLimit('Monthly limit', settings.monthlyLimitCents, (v) async {
                        final db = ref.read(databaseProvider);
                        await db.settingsDao.setLimits(monthlyLimitCents: v);
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 10),
                      child: Text(
                        'category warnings use per-category limits below',
                        style: AppTypography.monoLabel(size: 10, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                      ),
                    ),
                    Text('category warning limits', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    for (final c in categories)
                      _SettingsRow(
                        label: '${c.emoji} ${c.name}'.toLowerCase(),
                        value: Money.formatCents(c.limitCents),
                        danger: c.type == CategoryType.misc,
                        onTap: () => editLimit('${c.name} limit', c.limitCents, (v) async {
                          final db = ref.read(databaseProvider);
                          await db.categoriesDao.setLimit(categoryId: c.id, limitCents: v);
                          if (c.type == CategoryType.misc) {
                            await db.settingsDao.setLimits(miscLimitCents: v);
                          }
                        }),
                      ),
                    const SizedBox(height: 8),
                    Text('include in daily total', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    for (final c in core)
                      _ToggleRow(
                        label: c.name.toLowerCase(),
                        value: c.includeInTotal,
                        onChanged: (v) async {
                          final db = ref.read(databaseProvider);
                          await db.categoriesDao.setIncludeInTotal(categoryId: c.id, include: v);
                        },
                      ),
                    if (misc.isNotEmpty)
                      _ToggleRow(
                        label: 'misc',
                        value: misc.first.includeInTotal,
                        onChanged: (v) async {
                          final db = ref.read(databaseProvider);
                          await db.categoriesDao.setIncludeInTotal(categoryId: misc.first.id, include: v);
                        },
                      ),
                    _ToggleRow(
                      label: 'custom categories',
                      value: customIncluded,
                      onChanged: (v) async {
                        final db = ref.read(databaseProvider);
                        for (final c in custom) {
                          await db.categoriesDao.setIncludeInTotal(categoryId: c.id, include: v);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Text('custom categories', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w500, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    for (final c in custom)
                      _CustomCategoryRow(
                        label: '${c.emoji} ${c.name}'.toLowerCase(),
                        onRemove: () async {
                          final db = ref.read(databaseProvider);
                          await db.categoriesDao.deleteCategory(c.id);
                        },
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 0.7, style: BorderStyle.solid),
                      ),
                      child: Text(
                        '+ add category (use + button)',
                        textAlign: TextAlign.center,
                        style: AppTypography.monoLabel(size: 11, color: AppColors.green, weight: FontWeight.w500, letterSpacing: 0.2),
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
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.value, required this.onTap, this.danger = false});

  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.7))),
        child: Row(
          children: [
            Text(label, style: AppTypography.monoLabel(size: 12, color: danger ? AppColors.redLight : AppColors.text, weight: FontWeight.w500, letterSpacing: 0.2)),
            const Spacer(),
            Text(value, style: AppTypography.serifAmount(size: 13, color: danger ? AppColors.red : AppColors.green, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.7))),
      child: Row(
        children: [
          Text(label, style: AppTypography.monoLabel(size: 12, color: AppColors.text, weight: FontWeight.w500, letterSpacing: 0.2)),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.green,
            inactiveThumbColor: AppColors.muted,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}

class _CustomCategoryRow extends StatelessWidget {
  const _CustomCategoryRow({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.7))),
      child: Row(
        children: [
          Text(label, style: AppTypography.monoLabel(size: 12, color: AppColors.text, weight: FontWeight.w500, letterSpacing: 0.2)),
          const Spacer(),
          GestureDetector(
            onTap: onRemove,
            child: Text('remove', style: AppTypography.monoLabel(size: 11, color: AppColors.red, weight: FontWeight.w600, letterSpacing: 0.2)),
          ),
        ],
      ),
    );
  }
}

