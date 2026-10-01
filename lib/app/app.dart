import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/pos/pos_page.dart';
import '../features/student/student_page.dart';
import '../features/kitchen/kitchen_page.dart';
import '../features/pickup/pickup_page.dart';
import '../features/admin/admin_page.dart';
import 'theme.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
    GoRoute(
      path: '/login',
      builder: (_, state) =>
          LoginPage(staffOnly: state.uri.queryParameters['mode'] == 'staff'),
    ),
    GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
    GoRoute(
      path: '/student',
      builder: (_, state) => StudentPage(
        initialCategory: state.uri.queryParameters['category'] ?? 'Meals',
      ),
    ),
    GoRoute(path: '/pos', builder: (_, _) => const PosPage()),
    GoRoute(path: '/kitchen', builder: (_, _) => const KitchenPage()),
    GoRoute(path: '/pickup', builder: (_, _) => const PickupPage()),
    GoRoute(path: '/admin', builder: (_, _) => const AdminPage()),
  ],
);

class SmartCanteenApp extends StatelessWidget {
  const SmartCanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'University of Mindanao Canteen',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}
