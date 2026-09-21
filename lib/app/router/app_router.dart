import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../domain/entities/transaction.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/transactions/presentation/screens/transaction_details_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/settings/presentation/screens/manage_categories_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/set_password_screen.dart';
import '../../shared/widgets/app_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(
      name: RouteNames.splash,
      path: RoutePaths.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      name: RouteNames.login,
      path: RoutePaths.login,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      name: RouteNames.signup,
      path: RoutePaths.signup,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      name: RouteNames.setPassword,
      path: RoutePaths.setPassword,
      builder: (context, state) => const SetPasswordScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.home,
              path: RoutePaths.home,
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.transactions,
              path: RoutePaths.transactions,
              builder: (context, state) => const TransactionsScreen(),
              routes: [
                GoRoute(
                  name: RouteNames.addTransaction,
                  path: RoutePaths.addTransaction,
                  builder: (context, state) => AddTransactionScreen(
                    transactionToEdit: state.extra as Transaction?,
                  ),
                ),
                GoRoute(
                  name: RouteNames.transactionDetails,
                  path: RoutePaths.transactionDetails,
                  builder: (context, state) => TransactionDetailsScreen(transactionId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.analytics,
              path: RoutePaths.analytics,
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: RouteNames.settings,
              path: RoutePaths.settings,
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  name: RouteNames.categories,
                  path: RoutePaths.categories,
                  builder: (context, state) => const ManageCategoriesScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
