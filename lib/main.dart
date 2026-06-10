import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'core/services/gemini_service.dart';
import 'features/chat/ui/chat_screen.dart';
import 'features/chat/provider/chat_provider.dart';
import 'core/services/theme_service.dart';
import 'core/services/persona_service.dart';
import 'core/services/system_stats_provider.dart';
import 'core/services/voice_service.dart';

// Conditional import to prevent Android startup crashes
import 'core/services/desktop_stub.dart' if (dart.library.io) 'core/services/desktop_windows.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Handler
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("CRITICAL_STARTUP_ERROR: ${details.exception}");
    FlutterError.presentError(details);
  };

  if (!kIsWeb && Platform.isWindows) {
    await initDesktop();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => PersonaService()),
        if (!kIsWeb && Platform.isWindows) ...[
          ChangeNotifierProvider(create: (_) => VoiceService()),
          ChangeNotifierProvider(create: (_) => SystemStatsProvider()),
        ],
        ProxyProvider2<ThemeService, PersonaService, GeminiService>(
          update: (_, theme, persona, __) => GeminiService(theme, persona),
        ),
        ChangeNotifierProxyProvider2<GeminiService, ThemeService, ChatProvider>(
          create: (context) => ChatProvider(
            Provider.of<GeminiService>(context, listen: false),
            Provider.of<ThemeService>(context, listen: false),
          ),
          update: (_, gemini, theme, previous) => previous ?? ChatProvider(gemini, theme),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) => MaterialApp(
        title: 'Personal Assistant',
        debugShowCheckedModeBanner: false,
        theme: themeService.themeData,
        home: const ChatScreen(),
      ),
    );
  }
}
