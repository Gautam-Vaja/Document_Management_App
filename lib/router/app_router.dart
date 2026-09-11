import 'package:document_management_app/screens/DocumentScanner/document_scanner_screen.dart';
import 'package:document_management_app/screens/document/document_screen.dart';
import 'package:document_management_app/screens/home/home_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/document',
        builder: (context, state) => const DocumentScreen(),
      ),
      GoRoute(
        path: '/documentScanner',
        builder: (context, state) => const DocumentScannerScreen(),
      ),
    ],
  );
}
