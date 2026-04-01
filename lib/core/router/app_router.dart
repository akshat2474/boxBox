import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/standings/presentation/standings_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/news/presentation/news_screen.dart';
import '../../features/race_hub/presentation/session_hub_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/main_layout.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/hub/:sessionKey',
        builder: (context, state) {
          final sessionKey = int.tryParse(state.pathParameters['sessionKey']!) ?? 0;
          final extra = state.extra as Map<String, String?>? ?? {};
          final title = extra['title'] ?? 'Race Hub';
          final dateStart = extra['dateStart'];
          return SessionHubScreen(sessionKey: sessionKey, title: title, sessionDateStart: dateStart);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'standings',
                    builder: (context, state) => const StandingsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/news',
                builder: (context, state) => const NewsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
