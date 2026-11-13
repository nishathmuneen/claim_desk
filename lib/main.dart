import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/claim_desk_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClaimDeskProvider()),
      ],
      child: const ClaimDeskApp(),
    ),
  );
}

class ClaimDeskApp extends StatelessWidget {
  const ClaimDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClaimDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightNavyTheme,
      home: const SplashScreen(),
    );
  }
}
