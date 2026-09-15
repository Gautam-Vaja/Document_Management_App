import 'package:document_management_app/screens/DocumentScanner/document_scanner_screen.dart';
import 'package:document_management_app/screens/document/document_screen.dart';
import 'package:document_management_app/screens/fovorite/favorite_screen.dart';
import 'package:document_management_app/screens/home/home_screen.dart';
import 'package:document_management_app/screens/settings/settings_screen.dart';
import 'package:document_management_app/screens/splash/splash_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/splashScreen',
    routes: [
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/document',
        builder: (context, state) => const DocumentScreen(),
      ),
      GoRoute(
        path: '/favorite',
        builder: (context, state) => const FavoriteScreen(),
      ),
      GoRoute(
        path: '/documentScanner',
        builder: (context, state) => const DocumentScannerScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/splashScreen',
        builder: (context, state) => const SplashScreen(),
      ),
    ],
  );
}
