import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:premium_email_app/providers/auth_provider.dart';
import 'package:premium_email_app/providers/email_provider.dart';
import 'package:premium_email_app/screens/splash/splash_screen.dart';
import 'package:premium_email_app/screens/auth/login_screen.dart';
import 'package:premium_email_app/screens/auth/signup_screen.dart';
import 'package:premium_email_app/screens/dashboard/dashboard_screen.dart';
import 'package:premium_email_app/screens/email/email_setup_screen.dart';
import 'package:premium_email_app/screens/email/compose_email_screen.dart';
import 'package:premium_email_app/screens/email/email_history_screen.dart';
import 'package:premium_email_app/screens/profile/profile_screen.dart';
import 'package:premium_email_app/screens/profile/settings_screen.dart';
import 'package:premium_email_app/core/constants/app_colors.dart';
import 'package:premium_email_app/core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  //  CHECK TOKEN EXPIRY ON APP START
  await _checkTokenOnStart();
  
  runApp(const MyApp());
}

// FUNCTION TO CHECK TOKEN ON APP START
Future<void> _checkTokenOnStart() async {
  print('🔍 Checking token on app startup...');
  try {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    
    if (!isLoggedIn) {
      print('🔓 No valid token found or token expired');
    } else {
      print('✅ Valid token found, user is logged in');
    }
  } catch (e) {
    print('❌ Error checking token on startup: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmailProvider()),
      ],
      child: MaterialApp(
        title: 'Premium Email App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.surface,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => LoginScreen(
            onSignupTap: () {
              Navigator.pushReplacementNamed(context, '/signup');
            },
            onLoginSuccess: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          '/signup': (context) => SignupScreen(
            onLoginTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            onSignupSuccess: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          '/dashboard': (context) => DashboardScreen(),
          '/email-setup': (context) => EmailSetupScreen(
            onSetupComplete: () {
              Navigator.pop(context);
            },
          ),
          '/compose-email': (context) => const ComposeEmailScreen(),
          '/email-history': (context) => const EmailHistoryScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        // GLOBAL TOKEN CHECK ON NAVIGATION
        navigatorObservers: [
          _TokenExpiryObserver(),
        ],
      ),
    );
  }
}

//  GLOBAL NAVIGATION OBSERVER FOR TOKEN CHECK
class _TokenExpiryObserver extends NavigatorObserver {
  final AuthService _authService = AuthService();
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _checkToken();
    super.didPush(route, previousRoute);
  }
  
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _checkToken();
    super.didPop(route, previousRoute);
  }
  
  Future<void> _checkToken() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        print('🚨 Token expired during navigation');
      }
    } catch (e) {
      print('❌ Error checking token during navigation: $e');
    }
  }
}
