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

// ────────────────────────── MOBILE ──────────────────────────

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
    // Only show FAB on the exact trades list route
    final showFAB = location == '/trades';

    return Scaffold(
      body: SafeArea(
          bottom: false,
          child: child),
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
      floatingActionButton: showFAB
          ? FloatingActionButton.extended(
        onPressed: () => context.go('/trades/new'),
        icon: const Icon(Icons.add),
        label: const Text('New trade'),
      )
          : null,
    );
  }
}

// ────────────────────────── TABLET / DESKTOP ──────────────────────────

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
    final user = auth.user;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // ── Left rail ──
            // Explicit width is required: a child below uses
            // minimumSize: Size(double.infinity, 44) when extended, which
            // demands a bounded parent width or layout silently breaks on web.
            Container(
              width: extended ? 240 : 80,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.subtleBorder)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: extended ? 24 : 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.show_chart_rounded,
                                color: Colors.white, size: 18),
                          ),
                          if (extended) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Trading\nJournal',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Nav destinations
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

                    const SizedBox(height: 24),

                    // New trade button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: Size(extended ? double.infinity : 44, 44),
                          padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 8),
                        ),
                        onPressed: () => context.go('/trades/new'),
                        icon: const Icon(Icons.add, size: 18),
                        label: extended
                            ? const Text('New trade')
                            : const SizedBox.shrink(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // User card (extended) or logout icon (compact)
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
                                user?.fullName ?? user?.email ?? 'You',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (user?.email != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user!.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
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
                      Center(
                        child: IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Sign out',
                          onPressed: () async {
                            await context.read<AuthProvider>().logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Main content ──
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}