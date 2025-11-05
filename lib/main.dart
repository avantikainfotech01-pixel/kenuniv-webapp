import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenuniv/providers/auth_provider.dart';
import 'package:kenuniv/screens/admin/sidebar/sidebar_scaffold.dart';
import 'package:kenuniv/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance(); // ensure registration

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    // ✅ Load saved session (token, permissions, role)
    authNotifier.loadAuthData();

    Widget homeScreen;
    if (authState.token != null && authState.token!.isNotEmpty) {
      homeScreen = SidebarScaffold(userName: authState.userRole ?? "Admin");
    } else {
      homeScreen = const LoginScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(primarySwatch: Colors.red),
      home: homeScreen,
    );
  }
}
