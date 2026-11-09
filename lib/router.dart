import 'package:go_router/go_router.dart';

import 'screens/common/change_password_screen.dart';
import 'screens/common/home_shell.dart';
import 'screens/common/login_screen.dart';
import 'screens/common/register_screen.dart';
import 'screens/common/splash_screen.dart';
import 'screens/investor/holding_form_screen.dart';
import 'screens/investor/portfolio_form_screen.dart';
import 'screens/investor/stock_detail_screen.dart';
import 'screens/shared/holding_detail_screen.dart';
import 'screens/shared/portfolio_detail_screen.dart';
import 'state/session.dart';

const List<String> publicPaths = ['/login', '/register'];

GoRouter buildRouter(Session session) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (context, state) {
      final String path = state.matchedLocation;

      if (session.status == SessionStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }

      if (session.status == SessionStatus.signedOut) {
        return publicPaths.contains(path) ? null : '/login';
      }

      if (path == '/splash' || publicPaths.contains(path)) {
        return '/home';
      }

      final bool isEditPage = path.endsWith('/edit') || path.endsWith('/new');

      if (isEditPage && session.user?.isAnalyst == true) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(path: '/change-password', builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(path: '/portfolios/new', builder: (context, state) => const PortfolioFormScreen()),
      GoRoute(
        path: '/portfolios/:id',
        builder: (context, state) => PortfolioDetailScreen(portfolioId: _id(state)),
      ),
      GoRoute(
        path: '/portfolios/:id/edit',
        builder: (context, state) => PortfolioFormScreen(portfolioId: _id(state)),
      ),
      GoRoute(
        path: '/portfolios/:id/holdings/new',
        builder: (context, state) => HoldingFormScreen(portfolioId: _id(state)),
      ),
      GoRoute(
        path: '/holdings/:id',
        builder: (context, state) => HoldingDetailScreen(holdingId: _id(state)),
      ),
      GoRoute(
        path: '/holdings/:id/edit',
        builder: (context, state) => HoldingFormScreen(holdingId: _id(state)),
      ),
      GoRoute(
        path: '/stocks/:ticker',
        builder: (context, state) => StockDetailScreen(ticker: state.pathParameters['ticker']!.toUpperCase()),
      ),
    ],
  );
}

int _id(GoRouterState state) {
  return int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
}
