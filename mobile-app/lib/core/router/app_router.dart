import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/convert/screens/convert_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class AppRouter {
  static const home = '/';
  static const convert = '/convert';
  static const history = '/history';
  static const settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildRoute(const HomeScreen());
      case convert:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(ConvertScreen(
          filePath: args?['filePath'],
          fileName: args?['fileName'],
        ));
      case history:
        return _buildRoute(const HistoryScreen());
      case AppRouter.settings:
        return _buildRoute(const SettingsScreen());
      default:
        return _buildRoute(const HomeScreen());
    }
  }

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
