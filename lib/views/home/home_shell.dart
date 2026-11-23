import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../received/received_list_screen.dart';
import '../quotation_list/quotation_list_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

/// Root shell with lazy tabs; opened tabs retain their state and scroll position.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final List<Widget?> _tabs = List<Widget?>.filled(4, null);

  @override
  void initState() {
    super.initState();
    _tabs[0] = _buildTab(0);
  }

  Widget _buildTab(int index) => switch (index) {
    0 => HomeScreen(
      onQuotationsTab: () => _selectTab(1),
      onSettingsTab: () => _selectTab(3),
    ),
    1 => const QuotationListScreen(),
    2 => const ReceivedListScreen(),
    3 => const SettingsScreen(),
    _ => throw RangeError.index(index, _tabs),
  };

  void _selectTab(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _tabs[index] ??= _buildTab(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [for (final tab in _tabs) tab ?? const SizedBox.shrink()],
      ),
      bottomNavigationBar: FloatingTabBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}

class FloatingTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const FloatingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _destinations = <_TabDestination>[
    _TabDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _TabDestination(
      label: 'Quotations',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
    ),
    _TabDestination(
      label: 'Received',
      icon: Icons.move_to_inbox_outlined,
      selectedIcon: Icons.move_to_inbox_rounded,
    ),
    _TabDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth = constraints.maxWidth / _destinations.length;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeInOutCubicEmphasized,
                    start: selectedIndex * segmentWidth + 4,
                    width: segmentWidth - 8,
                    top: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0; index < _destinations.length; index++)
                        Expanded(
                          child: _TabBarItem(
                            destination: _destinations[index],
                            selected: selectedIndex == index,
                            onTap: () => onDestinationSelected(index),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _TabDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class _TabBarItem extends StatelessWidget {
  final _TabDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _TabBarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.onPrimary
        : AppColors.textPrimary.withValues(alpha: 0.62);

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
