import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/router.dart';
import 'config/theme.dart';
import 'providers/analytics_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/insights_provider.dart';
import 'providers/trades_provider.dart';
import 'services/analytics_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/insight_service.dart';
import 'services/trade_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TradingJournalApp());
}

class TradingJournalApp extends StatefulWidget {
  const TradingJournalApp({super.key});

  @override
  State<TradingJournalApp> createState() => _TradingJournalAppState();
}

class _TradingJournalAppState extends State<TradingJournalApp> {
  late final ApiClient _client;
  late final AuthService _authService;
  late final TradeService _tradeService;
  late final AnalyticsService _analyticsService;
  late final InsightService _insightService;

  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _authService = AuthService(_client);
    _tradeService = TradeService(_client);
    _analyticsService = AnalyticsService(_client);
    _insightService = InsightService(_client);

    _auth = AuthProvider(service: _authService, client: _client);
    _auth.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<TradesProvider>(
          create: (_) => TradesProvider(_tradeService),
        ),
        ChangeNotifierProvider<AnalyticsProvider>(
          create: (_) => AnalyticsProvider(_analyticsService),
        ),
        ChangeNotifierProvider<InsightsProvider>(
          create: (_) => InsightsProvider(_insightService),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(_auth);
          return MaterialApp.router(
            title: 'Trading Journal',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
