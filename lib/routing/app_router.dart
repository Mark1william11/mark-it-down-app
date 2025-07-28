// lib/routing/app_router.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/todo.dart';
import '../logic/auth_service.dart';
import '../presentation/screens/auth_screen.dart'; // Import the new screen
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/stats_screen.dart';
import '../presentation/screens/add_edit_todo_screen.dart';
import '../presentation/screens/focus_mode_screen.dart';

part 'app_router.g.dart';

// Define route paths for better organization
class AppRoutes {
  static const home = '/';
  static const auth = '/auth';
  // Sub-routes now have their full path defined here
  static const stats = '/stats'; // Was 'stats'
  static const add = '/add';     // Was 'add'
  static const edit = '/edit';   // Was 'edit'
  static const focus = '/focus';   // Was 'focus'
}

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
final authStream = ref.watch(authServiceProvider).authStateChanges;

  return GoRouter(
    refreshListenable: GoRouterRefreshStream(authStream),
    
    // Initial route depends on auth state, but redirect will handle it
    initialLocation: AppRoutes.home,
    
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(child: Text('Error: ${state.error}')),
    ),

    // --- REDIRECT LOGIC ---
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = ref.read(authServiceProvider).currentUser != null;
      final isGoingToAuth = state.matchedLocation == AppRoutes.auth;

      // If user is not logged in and not on the auth screen, redirect to auth
      if (!isLoggedIn && !isGoingToAuth) {
        return AppRoutes.auth;
      }
      // If user is logged in and trying to go to the auth screen, redirect to home
      if (isLoggedIn && isGoingToAuth) {
        return AppRoutes.home;
      }

      // No redirect needed
      return null;
    },

    routes: [
      // Auth screen is a top-level route
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.stats,
      builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.add,
        builder: (context, state) => const AddEditTodoScreen(),
      ),
      GoRoute(
        path: AppRoutes.edit,
        builder: (context, state) {
          if (state.extra is! Todo) {
            return const Scaffold(body: Center(child: Text('Error: Missing Todo data')));
          }
          final todo = state.extra as Todo;
          return AddEditTodoScreen(todo: todo);
        },
      ),
      GoRoute(
        path: AppRoutes.focus,
        builder: (context, state) {
          if (state.extra is! Todo) {
            return const Scaffold(body: Center(child: Text('Error: Missing Todo data')));
          }
          final todo = state.extra as Todo;
          return FocusModeScreen(todo: todo);
        },
      ),
    ],
  );
}

// Helper class to make GoRouter refresh when a stream emits
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}