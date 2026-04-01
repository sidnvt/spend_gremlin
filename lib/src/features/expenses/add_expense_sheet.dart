import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../../core/money.dart';
import '../../data/db/app_db.dart';
import '../../data/providers.dart';
import '../common/app_providers.dart';

enum _AddMode { main, form, newCategory }

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key, this.initialCategory, this.occurredOn, this.initialExpense});

  final Category? initialCategory;
  final DateTime? occurredOn;
  final Expense? initialExpense;

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  _AddMode _mode = _AddMode.main;
  Category? _selectedCategory;
  String _newCatEmoji = '🦝';

  final _amount = TextEditingController();
  final _name = TextEditingController();
  final _newCatName = TextEditingController();
  bool _includeInTotal = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialExpense != null) {
      final e = widget.initialExpense!;
      _mode = _AddMode.form;
      _amount.text = (e.amountCents / 100).toStringAsFixed(2);
      _name.text = e.name ?? '';
      _includeInTotal = e.includeInTotal;
    } else if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _mode = _AddMode.form;
      _includeInTotal = widget.initialCategory!.includeInTotal;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _name.dispose();
    _newCatName.dispose();
    super.dispose();
  }

  void _resetForm() {
    _amount.clear();
    _name.clear();
    _includeInTotal = true;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                (MediaQuery.of(context).size.width * 0.05).clamp(16.0, 28.0),
                14,
                (MediaQuery.of(context).size.width * 0.05).clamp(16.0, 28.0),
                14 + bottomPadding,
              ),
              child: categoriesAsync.when(
                data: (categories) {
                  if (_selectedCategory == null && widget.initialExpense != null) {
                    _selectedCategory = categories.firstWhere((c) => c.id == widget.initialExpense!.categoryId);
                  }
                  return settingsAsync.when(
                    data: (_) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: switch (_mode) {
                        _AddMode.main => _MainPicker(
                            categories: categories,
                            onPick: (c) {
                              setState(() {
                                _selectedCategory = c;
                                _mode = _AddMode.form;
                                _resetForm();
                                _includeInTotal = c.includeInTotal;
                              });
                            },
                            onNewCategory: () {
                              setState(() {
                                _mode = _AddMode.newCategory;
                                _newCatEmoji = '🦝';
                                _newCatName.clear();
                              });
                            },
                            onCancel: () => Navigator.of(context).maybePop(),
                          ),
                        _AddMode.form => _ExpenseForm(
                            key: ValueKey('form-${_selectedCategory?.id}'),
                            title: _selectedCategory == null ? 'expense' : '${_selectedCategory!.emoji} ${_selectedCategory!.name}'.toLowerCase(),
                            isEditing: widget.initialExpense != null,
                            amount: _amount,
                            name: _name,
                            includeInTotal: _includeInTotal,
                            onIncludeChanged: (v) => setState(() => _includeInTotal = v),
                            onBack: () => setState(() => _mode = _AddMode.main),
                            onSave: _selectedCategory == null
                                ? null
                                : () async {
                                    final amountCents = Money.parseRupeesToCents(_amount.text);
                                    if (amountCents <= 0) return;
                                    final parsedName = _name.text.trim().isEmpty ? null : _name.text.trim();
                                    final db = ref.read(databaseProvider);
                                    if (widget.initialExpense != null) {
                                      await db.expensesDao.updateExpense(
                                        id: widget.initialExpense!.id,
                                        categoryId: _selectedCategory!.id,
                                        amountCents: amountCents,
                                        name: parsedName,
                                        occurredOn: widget.initialExpense!.occurredOn,
                                        includeInTotal: _includeInTotal,
                                      );
                                    } else {
                                      await db.expensesDao.addExpense(
                                        categoryId: _selectedCategory!.id,
                                        amountCents: amountCents,
                                        name: parsedName,
                                        occurredOn: widget.occurredOn ?? DateTime.now(),
                                        includeInTotal: _includeInTotal,
                                      );
                                    }
                                    if (context.mounted) {
                                      Navigator.of(context).maybePop();
                                    }
                                  },
                          ),
                        _AddMode.newCategory => _NewCategory(
                            emoji: _newCatEmoji,
                            name: _newCatName,
                            onPickEmoji: (e) => setState(() => _newCatEmoji = e),
                            onBack: () => setState(() => _mode = _AddMode.main),
                            onCreate: () async {
                              final name = _newCatName.text.trim();
                              if (name.isEmpty) return;
                              final db = ref.read(databaseProvider);
                              final id = await db.categoriesDao.createCustomCategory(name: name, emoji: _newCatEmoji);
                              final created = categories.firstWhere(
                                (c) => c.id == id,
                                orElse: () => Category(
                                  id: id,
                                  name: name,
                                  emoji: _newCatEmoji,
                                  type: CategoryType.custom,
                                  includeInTotal: true,
                                  limitCents: 25000,
                                  sortOrder: 50,
                                ),
                              );
                              setState(() {
                                _selectedCategory = created;
                                _mode = _AddMode.form;
                                _resetForm();
                                _includeInTotal = true;
                              });
                            },
                          ),
                      },
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: $e'),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $e'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainPicker extends StatelessWidget {
  const _MainPicker({
    required this.categories,
    required this.onPick,
    required this.onNewCategory,
    required this.onCancel,
  });

  final List<Category> categories;
  final ValueChanged<Category> onPick;
  final VoidCallback onNewCategory;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final core = categories.where((c) => c.type == CategoryType.core).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final custom = categories.where((c) => c.type == CategoryType.custom).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final misc = categories.where((c) => c.type == CategoryType.misc).toList();

    final picks = <Category>[
      ...core,
      ...custom,
    ];

    return SingleChildScrollView(
      key: const ValueKey('main'),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('add expense', style: AppTypography.serifAmount(size: 16, color: AppColors.text)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          childAspectRatio: 2.3,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final c in picks)
              _CatOpt(
                icon: c.emoji,
                name: c.name.toLowerCase(),
                badge: c.type == CategoryType.core ? 'core' : 'custom',
                badgeColor: c.type == CategoryType.core ? AppColors.green : AppColors.amber,
                onTap: () => onPick(c),
              ),
            _CatOpt(
              icon: '+',
              iconColor: AppColors.amber,
              name: 'new category',
              badge: null,
              badgeColor: null,
              onTap: onNewCategory,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (misc.isNotEmpty)
          _MiscRow(
            misc: misc.first,
            miscLimitCents: misc.first.limitCents,
            onTap: () => onPick(misc.first),
          ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.muted,
            side: const BorderSide(color: AppColors.border, width: 0.7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('cancel', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, letterSpacing: 0.2)),
        ),
      ],
      ),
    );
  }
}

class _CatOpt extends StatelessWidget {
  const _CatOpt({
    required this.icon,
    this.iconColor,
    required this.name,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  final String icon;
  final Color? iconColor;
  final String name;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 18, color: iconColor)),
            const SizedBox(height: 4),
            Text(name, style: AppTypography.monoLabel(size: 10, color: AppColors.text, letterSpacing: 0.2)),
            if (badge != null) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor!.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge!, style: AppTypography.monoLabel(size: 9, color: badgeColor!, weight: FontWeight.w500, letterSpacing: 0.2)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiscRow extends ConsumerWidget {
  const _MiscRow({required this.misc, required this.miscLimitCents, required this.onTap});

  final Category misc;
  final int miscLimitCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expensesAsync = ref.watch(expensesForDayProvider(today));

    return expensesAsync.when(
      data: (expenses) {
        final miscSpent = expenses.where((e) => e.categoryId == misc.id).fold<int>(0, (p, e) => p + e.amountCents);
        final over = miscSpent > miscLimitCents;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'MISC · ${Money.formatCents(miscSpent)} / ${Money.formatCents(miscLimitCents)} limit',
                  style: AppTypography.monoLabel(size: 9, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                ),
                const SizedBox(height: 4),
                Text(
                  over ? '⚠ over limit — tap to log misc item' : 'tap to log misc item',
                  style: AppTypography.monoLabel(size: 10, color: over ? AppColors.red : AppColors.text, weight: FontWeight.w500, letterSpacing: 0.2),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _ExpenseForm extends StatelessWidget {
  const _ExpenseForm({
    super.key,
    required this.title,
    required this.isEditing,
    required this.amount,
    required this.name,
    required this.includeInTotal,
    required this.onIncludeChanged,
    required this.onBack,
    required this.onSave,
  });

  final String title;
  final bool isEditing;
  final TextEditingController amount;
  final TextEditingController name;
  final bool includeInTotal;
  final ValueChanged<bool> onIncludeChanged;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: AppColors.muted, size: 18),
            ),
            Text(title, style: AppTypography.serifAmount(size: 16, color: AppColors.text)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '₹ amount*',
                  labelStyle: AppTypography.monoLabel(size: 11, color: AppColors.text, weight: FontWeight.w500, letterSpacing: 0.2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: 'name (optional)',
                  labelStyle: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text('include in daily total', style: AppTypography.monoLabel(size: 11, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2)),
            const Spacer(),
            Switch(
              value: includeInTotal,
              onChanged: onIncludeChanged,
              activeThumbColor: AppColors.green,
              inactiveThumbColor: AppColors.muted,
              inactiveTrackColor: AppColors.border,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
          ),
          child: Text(isEditing ? 'update' : 'save', style: AppTypography.monoLabel(size: 12, color: Colors.black, weight: FontWeight.w600, letterSpacing: 0.3)),
        ),
      ],
    );
  }
}

class _NewCategory extends StatelessWidget {
  const _NewCategory({
    required this.emoji,
    required this.name,
    required this.onPickEmoji,
    required this.onBack,
    required this.onCreate,
  });

  final String emoji;
  final TextEditingController name;
  final ValueChanged<String> onPickEmoji;
  final VoidCallback onBack;
  final VoidCallback onCreate;

  static const _emojiChoices = ['🦝', '💊', '🎮', '🛒', '👗', '🎵', '🍺', '💪', '📚'];

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('newcat'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: AppColors.muted, size: 18),
            ),
            Text('new category', style: AppTypography.serifAmount(size: 16, color: AppColors.text)),
          ],
        ),
        const SizedBox(height: 8),
        Text('pick emoji (optional, defaults to 🦝)', style: AppTypography.monoLabel(size: 10, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in _emojiChoices)
              TextButton(
                onPressed: () => onPickEmoji(e),
                style: TextButton.styleFrom(
                  backgroundColor: e == emoji ? AppColors.border : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(e, style: const TextStyle(fontSize: 18)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: name,
          decoration: InputDecoration(
            labelText: 'category name*',
            labelStyle: AppTypography.monoLabel(size: 11, color: AppColors.text, weight: FontWeight.w500, letterSpacing: 0.2),
          ),
        ),
        const SizedBox(height: 8),
        Text('first expense will be prompted after', style: AppTypography.monoLabel(size: 10, color: AppColors.muted, weight: FontWeight.w400, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
          ),
          child: Text('create category', style: AppTypography.monoLabel(size: 12, color: Colors.black, weight: FontWeight.w600, letterSpacing: 0.3)),
        ),
      ],
    );
  }
}

