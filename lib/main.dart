import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/facility_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/theme_provider.dart';

import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/notification_provider.dart';
import 'providers/activity_log_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const UnesaSportHubApp());
}

class UnesaSportHubApp extends StatelessWidget {
  const UnesaSportHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<FacilityProvider>(
          create: (_) => FacilityProvider(),
        ),
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider<ActivityLogProvider>(
          create: (_) => ActivityLogProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'UNESA SportHub',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              primaryColor: AppColors.primaryDarkGreen,
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryDarkGreen,
                secondary: AppColors.secondaryGreen,
                tertiary: AppColors.accentGreen,
                surface: AppColors.card,
                error: AppColors.danger,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: AppColors.textPrimary,
                onError: Colors.white,
              ),
              fontFamily: 'Roboto',
              textTheme: const TextTheme(
                headlineSmall: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
                titleLarge: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
                titleMedium: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
                bodyLarge: TextStyle(
                  color: AppColors.textPrimary,
                  letterSpacing: 0,
                ),
                bodyMedium: TextStyle(
                  color: AppColors.textSecondary,
                  letterSpacing: 0,
                ),
                labelLarge: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              cardTheme: CardThemeData(
                color: AppColors.card,
                elevation: 0,
                margin: EdgeInsets.zero,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                labelStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                hintStyle: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w400,
                ),
                prefixIconColor: AppColors.secondaryGreen,
                suffixIconColor: AppColors.secondaryGreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.secondaryGreen,
                    width: 1.4,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.danger),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: AppColors.danger,
                    width: 1.4,
                  ),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryDarkGreen
                      .withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shadowColor: AppColors.primaryDarkGreen.withValues(
                    alpha: 0.18,
                  ),
                  minimumSize: const Size(double.infinity, 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDarkGreen,
                  side: const BorderSide(
                    color: AppColors.secondaryGreen,
                    width: 1.2,
                  ),
                  minimumSize: const Size(double.infinity, 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDarkGreen,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: AppColors.card,
                selectedItemColor: AppColors.primaryDarkGreen,
                unselectedItemColor: AppColors.muted,
                selectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
                type: BottomNavigationBarType.fixed,
                elevation: 12,
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: AppColors.card,
                indicatorColor: AppColors.lightGreenSurface,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return TextStyle(
                    color: isSelected
                        ? AppColors.primaryDarkGreen
                        : AppColors.muted,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: isSelected
                        ? AppColors.primaryDarkGreen
                        : AppColors.muted,
                  );
                }),
              ),
              snackBarTheme: SnackBarThemeData(
                backgroundColor: AppColors.textPrimary,
                contentTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryDarkGreen,
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primaryDarkGreen,
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
