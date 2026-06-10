import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/chat/provider/chat_provider.dart';
import 'core/services/theme_service.dart';
import 'core/services/persona_service.dart';
import 'core/services/gemini_service.dart';
import 'features/chat/ui/chat_screen.dart';
import 'core/services/voice_service.dart';
import 'core/services/system_stats_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => PersonaService()),
        if (Platform.isWindows) ChangeNotifierProvider(create: (_) => VoiceService()),
        if (Platform.isWindows) ChangeNotifierProvider(create: (_) => SystemStatsProvider()),
        
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
