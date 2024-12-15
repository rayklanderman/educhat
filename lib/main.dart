import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:educhat/config/supabase_config.dart';
import 'package:educhat/screens/auth/login_screen.dart';
import 'package:educhat/screens/auth/register_screen.dart';
import 'package:educhat/screens/home/home_screen.dart';
import 'package:educhat/screens/chat/chat_screen.dart';
import 'package:educhat/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  runApp(
    const ProviderScope(
      child: EduChatApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isAuth = SupabaseConfig.client.auth.currentSession != null;
    final isAuthRoute = state.matchedLocation == '/login' || 
                       state.matchedLocation == '/register';

    // If not authenticated and not on auth route, redirect to login
    if (!isAuth && !isAuthRoute) return '/login';
    
    // If authenticated and on auth route, redirect to home
    if (isAuth && isAuthRoute) return '/home';
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ChatScreen(
          chatId: state.pathParameters['id']!,
          otherUser: extra?['user'],
        );
      },
    ),
  ],
);

class EduChatApp extends StatelessWidget {
  const EduChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EduChat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
