import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenuniv/providers/auth_provider.dart';
import 'package:kenuniv/screens/admin/sidebar/sidebar_scaffold.dart';
import 'package:kenuniv/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(child: MyApp(prefs: prefs)));
}

class MyApp extends ConsumerWidget {
  final SharedPreferences prefs;
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authProvider.notifier);
    authNotifier.loadAuthData(); // Load once

    final authState = ref.watch(authProvider);
    final homeScreen = (authState.token?.isNotEmpty ?? false)
        ? SidebarScaffold(userName: authState.userRole ?? "Admin")
        : const LoginScreen();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(primarySwatch: Colors.red),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) =>
            SidebarScaffold(userName: authState.userRole ?? "Admin"),
      },
      home: homeScreen,
    );
  }
}
