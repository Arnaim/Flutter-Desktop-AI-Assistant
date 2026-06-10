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

// Import only if on Windows to prevent Android crashes
import 'package:window_manager/window_manager.dart' deferred as window_manager;
import 'package:hotkey_manager/hotkey_manager.dart' deferred as hotkey_manager;
import 'package:speech_to_text_windows/speech_to_text_windows.dart' deferred as speech_to_text_windows;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Handler
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint("CRITICAL_STARTUP_ERROR: ${details.exception}");
    FlutterError.presentError(details);
  };

  if (!kIsWeb && Platform.isWindows) {
    await _initDesktop();
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

Future<void> _initDesktop() async {
  try {
    await window_manager.loadLibrary();
    await hotkey_manager.loadLibrary();
    await speech_to_text_windows.loadLibrary();

    await Process.run('pm2', ['delete', 'free-llm-proxy'], runInShell: true);
    await Process.run('pm2', ['start', 'E:/FreeAPIKey/freellmapi/app.js', '--name', 'free-llm-proxy', '--no-autorestart'], runInShell: true);
    
    speech_to_text_windows.SpeechToTextWindows.registerWith();
    
    await window_manager.windowManager.ensureInitialized();
    await window_manager.windowManager.waitUntilReadyToShow(const window_manager.WindowOptions(
      size: Size(1000, 700),
      titleBarStyle: window_manager.TitleBarStyle.hidden,
    ), () async {
      await window_manager.windowManager.show();
      await window_manager.windowManager.focus();
    });
    await hotkey_manager.hotKeyManager.unregisterAll();
  } catch (e) {
    debugPrint("Desktop init error: $e");
  }
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
