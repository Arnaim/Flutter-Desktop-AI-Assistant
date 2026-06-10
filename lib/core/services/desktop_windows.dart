import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:speech_to_text_windows/speech_to_text_windows.dart';

Future<void> initDesktop() async {
  try {
    await Process.run('pm2', ['delete', 'free-llm-proxy'], runInShell: true);
    await Process.run('pm2', ['start', 'E:/FreeAPIKey/freellmapi/app.js', '--name', 'free-llm-proxy', '--no-autorestart'], runInShell: true);
    
    SpeechToTextWindows.registerWith();
    
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(const WindowOptions(
      size: Size(1000, 700),
      titleBarStyle: TitleBarStyle.hidden,
    ), () async {
      await windowManager.show();
      await windowManager.focus();
    });
    await hotKeyManager.unregisterAll();
  } catch (e) {
    debugPrint("Desktop init error: $e");
  }
}
