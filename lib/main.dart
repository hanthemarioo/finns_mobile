import 'package:finns_mobile/features/home_page_wrapper.dart';
import 'package:finns_mobile/features/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';

// 1. Make the main function async
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  final initialToken = await authService.getInitialToken();

  runApp(MyApp(initialToken: initialToken, authService: authService));
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  final AuthService authService;

  const MyApp({
    super.key,
    required this.initialToken,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..setAuthToken(initialToken),
        ),
      ],
      child: MaterialApp(
        title: 'Farm App',
        theme: ThemeData(primarySwatch: Colors.green),
        home: initialToken != null
            ? const HomePageWrapper()
            : const LoginPage(),
        routes: {
          '/login': (_) => const LoginPage(),
          '/home': (_) => const HomePageWrapper(),
        },
      ),
    );
  }
}
