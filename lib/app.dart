import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'core/api_client.dart';
import 'core/live_socket.dart';
import 'router.dart';
import 'services/analytics_service.dart';
import 'services/dashboard_service.dart';
import 'services/holding_service.dart';
import 'services/market_service.dart';
import 'services/portfolio_service.dart';
import 'services/users_service.dart';
import 'state/session.dart';

class StockRiskApp extends StatefulWidget {
  const StockRiskApp({super.key, required this.api, required this.live, required this.session});

  final ApiClient api;
  final LiveSocket live;
  final Session session;

  @override
  State<StockRiskApp> createState() => _StockRiskAppState();
}

class _StockRiskAppState extends State<StockRiskApp> {
  late final GoRouter _router = buildRouter(widget.session);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: widget.api),
        ChangeNotifierProvider<LiveSocket>.value(value: widget.live),
        ChangeNotifierProvider<Session>.value(value: widget.session),
        Provider<PortfolioService>(create: (_) => PortfolioService(widget.api)),
        Provider<HoldingService>(create: (_) => HoldingService(widget.api)),
        Provider<MarketService>(create: (_) => MarketService(widget.api)),
        Provider<AnalyticsService>(create: (_) => AnalyticsService(widget.api)),
        Provider<DashboardService>(create: (_) => DashboardService(widget.api)),
        Provider<UsersService>(create: (_) => UsersService(widget.api)),
      ],
      child: MaterialApp.router(
        title: 'Stock Risk Engine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
