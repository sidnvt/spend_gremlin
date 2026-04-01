import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_typography.dart';
import '../expenses/add_expense_sheet.dart';

class NavShellScreen extends ConsumerWidget {
  const NavShellScreen({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _NavTab(path: '/dashboard', label: 'home', icon: '⊞'),
    _NavTab(path: '/history', label: 'history', icon: '≡'),
    _NavTab(path: '/insights', label: 'insights', icon: '◈'),
    _NavTab(path: '/settings', label: 'settings', icon: '⚙'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.path));

    // Account for system navigation bar and curved display edges
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final curvedEdgePad = (screenWidth * 0.02).clamp(6.0, 14.0);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
        ),
        padding: EdgeInsets.fromLTRB(curvedEdgePad, 6, curvedEdgePad, 8 + bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomItem(
              tab: _tabs[0],
              selected: currentIndex == 0,
              onTap: () => context.go(_tabs[0].path),
            ),
            _BottomItem(
              tab: _tabs[1],
              selected: currentIndex == 1,
              onTap: () => context.go(_tabs[1].path),
            ),
            _PlusButton(
              onTap: () async {
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddExpenseSheet(),
                );
              },
            ),
            _BottomItem(
              tab: _tabs[2],
              selected: currentIndex == 2,
              onTap: () => context.go(_tabs[2].path),
            ),
            _BottomItem(
              tab: _tabs[3],
              selected: currentIndex == 3,
              onTap: () => context.go(_tabs[3].path),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.path, required this.label, required this.icon});
  final String path;
  final String label;
  final String icon;
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.tab, required this.selected, required this.onTap});

  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tab.icon, style: const TextStyle(fontSize: 18, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: AppTypography.monoLabel(
                size: 10,
                color: selected ? AppColors.green : AppColors.muted,
                weight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: SizedBox(
        width: 52,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.black,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            elevation: 0,
          ),
          onPressed: onTap,
          child: const Text('+', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

