import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';

final ThemeProvider globalThemeProvider = ThemeProvider();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SmartCampusApp(themeProvider: globalThemeProvider));
}

/// Root Application Widget for Smart Campus Placement.
class SmartCampusApp extends StatelessWidget {
  final ThemeProvider? themeProvider;

  const SmartCampusApp({
    super.key,
    this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final activeThemeProvider = themeProvider ?? globalThemeProvider;
    return ListenableBuilder(
      listenable: activeThemeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: activeThemeProvider.themeMode,
          initialRoute: AppRoutes.welcome,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
