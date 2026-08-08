import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/courses/presentation/courses_screen.dart';
import '../../features/courses/presentation/course_detail_screen.dart';
import '../../features/news/presentation/news_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/payment/presentation/payment_upload_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/course-detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'comp';
        return CourseDetailScreen(courseId: id);
      },
    ),
    GoRoute(
      path: '/payment-upload',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PaymentUploadScreen(
          enrollmentId: extra?['enrollmentId'] as String?,
          amount: extra?['amount'] as num?,
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithBottomNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/courses',
          builder: (context, state) => const CoursesScreen(),
        ),
        GoRoute(
          path: '/news',
          builder: (context, state) => const NewsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNavBar({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/courses')) return 1;
    if (location.startsWith('/news')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/courses');
        break;
      case 2:
        context.go('/news');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.navy900 : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);
    final selectedColor = isDark ? AppColors.primaryLime : const Color(0xFF041426);
    final unselectedColor = isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (idx) => _onItemTapped(idx, context),
          backgroundColor: bgColor,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: selectedColor),
              label: 'Bosh sahifa',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book, color: selectedColor),
              label: 'Kurslar',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper, color: selectedColor),
              label: 'Yangiliklar',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: selectedColor),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
