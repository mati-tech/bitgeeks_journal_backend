import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';

class _Destination {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _Destination(this.path, this.label, this.icon, this.selectedIcon);
}

const _destinations = [
  _Destination('/dashboard', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
  _Destination('/trades', 'Trades', Icons.candlestick_chart_outlined, Icons.candlestick_chart_rounded),
  _Destination('/analytics', 'Analytics', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
  _Destination('/insights', 'Insights', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
];

int _indexFor(String location) {
  for (var i = 0; i < _destinations.length; i++) {
    if (location.startsWith(_destinations[i].path)) return i;
  }
  return 0;
}

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  void _go(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _indexFor(location);

    return responsive<Widget>(
      context,
      mobile: _MobileShell(
        location: location,
        selectedIndex: selected,
        onSelect: (i) => _go(context, i),
        child: child,
      ),
      tablet: _RailShell(
        location: location,
        selectedIndex: selected,
        extended: false,
        onSelect: (i) => _go(context, i),
        child: child,
      ),
      desktop: _RailShell(
        location: location,
        selectedIndex: selected,
        extended: true,
        onSelect: (i) => _go(context, i),
        child: child,
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  final String location;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _MobileShell({
    required this.child,
    required this.location,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelect,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
      floatingActionButton: location.startsWith('/trades')
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/trades/new'),
              icon: const Icon(Icons.add),
              label: const Text('New trade'),
            )
          : null,
    );
  }
}

class _RailShell extends StatelessWidget {
  final Widget child;
  final String location;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelect;

  const _RailShell({
    required this.child,
    required this.location,
    required this.selectedIndex,
    required this.extended,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.subtleBorder)),
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: extended ? 24 : 18),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 18),
                                ),
                                if (extended) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    'Trading\nJournal',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          height: 1.1,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          NavigationRail(
                            extended: extended,
                            selectedIndex: selectedIndex,
                            backgroundColor: Colors.transparent,
                            useIndicator: true,
                            minWidth: 64,
                            minExtendedWidth: 220,
                            onDestinationSelected: onSelect,
                            destinations: [
                              for (final d in _destinations)
                                NavigationRailDestination(
                                  icon: Icon(d.icon),
                                  selectedIcon: Icon(d.selectedIcon),
                                  label: Text(d.label),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: Size(extended ? double.infinity : 44, 44),
                                padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 8),
                              ),
                              onPressed: () => context.go('/trades/new'),
                              icon: const Icon(Icons.add, size: 18),
                              label: extended ? const Text('New trade') : const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (extended)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.subtleBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      auth.user?.fullName ?? auth.user?.email ?? 'You',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (auth.user?.email != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        auth.user!.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          await context.read<AuthProvider>().logout();
                                          if (context.mounted) context.go('/login');
                                        },
                                        icon: const Icon(Icons.logout, size: 16),
                                        label: const Text('Sign out'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.logout),
                              tooltip: 'Sign out',
                              onPressed: () async {
                                await context.read<AuthProvider>().logout();
                                if (context.mounted) context.go('/login');
                              },
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
