import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class NavDestinationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const NavDestinationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class ResponsiveShell extends StatelessWidget {
  final String currentLocation;
  final List<NavDestinationItem> navItems;
  final List<NavDestinationItem>? secondaryItems;
  final Widget child;
  final String headerTitle;
  final List<Widget>? actions;
  final bool isAdminShell;

  const ResponsiveShell({
    super.key,
    required this.currentLocation,
    required this.navItems,
    this.secondaryItems,
    required this.child,
    required this.headerTitle,
    this.actions,
    this.isAdminShell = false,
  });

  int _selectedIndex() {
    for (int i = 0; i < navItems.length; i++) {
      if (currentLocation == navItems[i].route ||
          currentLocation.startsWith('${navItems[i].route}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 960;
    final selectedIdx = _selectedIndex();
    final bottomItems = navItems.take(5).toList();

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              navItems: navItems,
              secondaryItems: secondaryItems ?? const [],
              currentLocation: currentLocation,
              isAdminShell: isAdminShell,
            ),
            Expanded(
              child: Column(
                children: [
                  _TopHeaderBar(
                    title: headerTitle,
                    actions: actions,
                    isAdminShell: isAdminShell,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(headerTitle),
        actions: actions,
      ),
      drawer: Drawer(
        backgroundColor: AppColors.navyPrimary,
        child: SafeArea(
          child: _SidebarContent(
            navItems: navItems,
            secondaryItems: secondaryItems ?? const [],
            currentLocation: currentLocation,
            isAdminShell: isAdminShell,
            closeDrawerOnTap: true,
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIdx.clamp(0, bottomItems.length - 1),
        onDestinationSelected: (idx) {
          context.go(bottomItems[idx].route);
        },
        destinations: bottomItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon, color: AppColors.navyPrimary),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TopHeaderBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool isAdminShell;

  const _TopHeaderBar({
    required this.title,
    this.actions,
    required this.isAdminShell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.navyPrimary,
            ),
          ),
          const SizedBox(width: 12),
          if (isAdminShell)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emeraldSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ADMIN CONSOLE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldDark,
                ),
              ),
            ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final List<NavDestinationItem> navItems;
  final List<NavDestinationItem> secondaryItems;
  final String currentLocation;
  final bool isAdminShell;

  const _DesktopSidebar({
    required this.navItems,
    required this.secondaryItems,
    required this.currentLocation,
    required this.isAdminShell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      color: AppColors.navyPrimary,
      child: SafeArea(
        child: _SidebarContent(
          navItems: navItems,
          secondaryItems: secondaryItems,
          currentLocation: currentLocation,
          isAdminShell: isAdminShell,
          closeDrawerOnTap: false,
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final List<NavDestinationItem> navItems;
  final List<NavDestinationItem> secondaryItems;
  final String currentLocation;
  final bool isAdminShell;
  final bool closeDrawerOnTap;

  const _SidebarContent({
    required this.navItems,
    required this.secondaryItems,
    required this.currentLocation,
    required this.isAdminShell,
    required this.closeDrawerOnTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.emeraldAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      isAdminShell ? 'Operations & Audit' : 'Product Ownership',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF1E3A5F), height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            children: [
              ...navItems.map((item) => _SidebarTile(
                    item: item,
                    selected: currentLocation == item.route ||
                        currentLocation.startsWith('${item.route}/'),
                    closeDrawerOnTap: closeDrawerOnTap,
                  )),
              if (secondaryItems.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Text(
                    'MORE',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...secondaryItems.map((item) => _SidebarTile(
                      item: item,
                      selected: currentLocation == item.route,
                      closeDrawerOnTap: closeDrawerOnTap,
                    )),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final NavDestinationItem item;
  final bool selected;
  final bool closeDrawerOnTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.closeDrawerOnTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? AppColors.emeraldAccent.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (closeDrawerOnTap) Navigator.of(context).pop();
            context.go(item.route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  color: selected
                      ? AppColors.emeraldAccent
                      : const Color(0xFFCBD5E1),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    ),
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
