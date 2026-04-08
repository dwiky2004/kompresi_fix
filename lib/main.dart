import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/history_provider.dart';
import 'providers/compression_provider.dart';
import 'screens/splash_screen.dart';

import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Storage & Privacy: Auto-cleanup files > 24h
  await StorageService.init();

  debugPrint('main() started – running MyApp');
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp and setting up providers');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('Creating HistoryProvider and loading history');
            return HistoryProvider()..loadHistory();
          },
        ),
        ChangeNotifierProvider(create: (_) => CompressionProvider()),
      ],
      child: MaterialApp(
        title: 'Aplikasi Kompresi Citra Digital',
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFF1A237E),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
