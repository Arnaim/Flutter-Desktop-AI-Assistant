import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ineffa_assistant_bot/core/services/gemini_service.dart';
import 'package:ineffa_assistant_bot/features/chat/ui/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'features/chat/provider/chat_provider.dart';
import 'core/services/theme_service.dart';
import 'core/services/voice_service.dart';
import 'core/services/persona_service.dart';
import 'core/services/system_stats_provider.dart';
import 'package:speech_to_text_windows/speech_to_text_windows.dart';
import 'package:flutter/foundation.dart';

void _manageLocalProxy() async {
  try {
    // 1. Clean up any stale instances first
    await Process.run('pm2', ['delete', 'free-llm-proxy'], runInShell: true);

    // 2. Start the proxy in the background using absolute path to the script
    await Process.run(
      'pm2', 
      ['start', 'E:/FreeAPIKey/freellmapi/app.js', '--name', 'free-llm-proxy', '--no-autorestart'], 
      runInShell: true,
    );
    
    debugPrint("Ineffa: Background Proxy Initialized.");
  } catch (e) {
    debugPrint("Ineffa: Proxy Error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  if (isWindows) {
    // Start the background proxy server only on Windows
    _manageLocalProxy();
    
    SpeechToTextWindows.registerWith();
    
    // Initialize window manager
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // Modern borderless look
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // Allow the app to handle the close event manually
      await windowManager.setPreventClose(true);
    });

    // Initialize hotkey manager
    await hotKeyManager.unregisterAll();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ChangeNotifierProvider(create: (_) => PersonaService()),
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
        ChangeNotifierProvider(create: (_) => SystemStatsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      // Completely remove the proxy when the app exits
      await Process.run('pm2', ['delete', 'free-llm-proxy'], runInShell: true);
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeService.themeData,
          home: const ChatScreen(),
        );
      },
    );
  }
}
