import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Centered card with a subtle gradient backdrop. Shared by login/register.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.7),
            radius: 1.4,
            colors: [
              Color(0xFF1A2640),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Trading Journal',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: child,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 18),
                      Center(child: footer!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
