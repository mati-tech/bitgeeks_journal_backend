import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/insights_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/loading_view.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsightsProvider>().load();
    });
  }

  Future<void> _generate() async {
    final p = context.read<InsightsProvider>();
    final n = await p.generate();
    if (!mounted) return;
    if (n != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(n == 0 ? 'No new insights this round.' : 'Generated $n insight${n == 1 ? '' : 's'}.')),
      );
    } else if (p.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(p.error!),
          backgroundColor: AppColors.lossSoft,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<InsightsProvider>();
    final pad = responsive(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 24, pad, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Insights',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Patterns, blind spots, and psychological flags Claude found in your trading.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (!context.isMobile)
                    FilledButton.icon(
                      onPressed: p.generating ? null : _generate,
                      icon: p.generating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(p.generating ? 'Analyzing…' : 'Generate insights'),
                    ),
                ],
              ),
            ),
            Expanded(child: _body(p, pad)),
          ],
        ),
        if (context.isMobile)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: p.generating ? null : _generate,
              icon: p.generating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(p.generating ? 'Analyzing' : 'Generate'),
            ),
          ),
      ],
    );
  }

  Widget _body(InsightsProvider p, double pad) {
    if (p.loading && p.items.isEmpty) return const LoadingView();
    if (p.items.isEmpty) {
      return EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'No insights yet',
        subtitle: 'Once you have at least 5 trades, generate AI insights to surface patterns and blind spots.',
        action: FilledButton.icon(
          onPressed: p.generating ? null : _generate,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate insights'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => p.load(),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(pad, 12, pad, 100),
        itemCount: p.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final insight = p.items[i];
          return InsightCard(
            insight: insight,
            onDismiss: () async {
              final ok = await p.dismiss(insight.id);
              if (!mounted) return;
              if (!ok && p.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.error!)));
              }
            },
          );
        },
      ),
    );
  }
}
