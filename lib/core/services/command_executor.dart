import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:process_run/shell.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'memory_service.dart';

class CommandExecutor {
  final Shell _shell = Shell();
  final MemoryService _memoryService = MemoryService();

  Future<void> execute(String response, {Function? onCaptureRequest}) async {
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    
    // New regex: Looks for [COMMAND: ACTION: VALUE] or [COMMAND: ACTION]
    final commandRegex = RegExp(r'\[COMMAND:\s*([^\]:]+)(?::\s*([^\]]+))?\]', caseSensitive: false);
    final matches = commandRegex.allMatches(response);

    debugPrint("Parsing response for commands...");

    for (var match in matches) {
      final action = match.group(1)?.trim().toUpperCase() ?? '';
      final value = match.group(2)?.trim() ?? '';

      debugPrint("Matched Command: Action=$action, Value=$value");

      if (action == 'MEMORIZE') {
        await _memoryService.saveMemory(value);
      } else if (action == 'INITIATE_OPTICAL_SCAN') {
        if (onCaptureRequest != null) onCaptureRequest();
      } else if (action == 'SEARCH GOOGLE') {
        await _launchUrl('https://www.google.com/search?q=$value');
      } else if (action == 'SEARCH YOUTUBE') {
        await _launchUrl('https://www.youtube.com/results?search_query=$value');
      } 
      
      // Platform Specific Logic
      if (isWindows) {
        await _executeWindowsCommand(action, value);
      } else {
        await _executeAndroidCommand(action, value);
      }
    }
  }

  Future<void> _executeWindowsCommand(String action, String value) async {
    if (action == 'WRITE NOTEPAD') {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}\\ineffa_note.txt');
      await file.writeAsString(value);
      await _shell.run('notepad.exe "${file.path}"');
    } else if (action == 'TYPE') {
      final escaped = value.replaceAll("'", "''").replaceAll('"', '`"');
      await _shell.run('powershell -Command "Add-Type -AssemblyName System.Windows.Forms; Start-Sleep -Milliseconds 800; [System.Windows.Forms.SendKeys]::SendWait(\'$escaped\')"');
    } else if (action == 'OPEN PATH') {
      await _shell.run('explorer.exe "$value"');
    } else if (action == 'OPEN APP') {
      await _handleWindowsAppLaunch(value.toLowerCase());
    } else if (action == 'SYSTEM COMMAND' || action == 'RUN') {
      try {
         await _shell.run(value);
      } catch (e) {
         debugPrint("Windows Command failed: $e");
      }
    }
  }

  Future<void> _executeAndroidCommand(String action, String value) async {
    if (action == 'OPEN APP') {
      // On Android, we just try to launch via URL scheme or common search
      debugPrint("Android: Attempting to launch app: $value");
      if (value.contains("note")) {
        // Many Androids respond to 'content://' or generic intents, but browser is safer
        await _launchUrl("https://keep.google.com"); 
      }
    } else if (action == 'OPEN PATH') {
      debugPrint("Android: Path opening is restricted. URL launch instead.");
    }
  }

  Future<void> _handleWindowsAppLaunch(String appName) async {
    if (appName.contains('notepad')) await _shell.run('notepad.exe');
    else if (appName.contains('paint')) await _shell.run('mspaint.exe');
    else if (appName.contains('task manager')) await _shell.run('taskmgr.exe');
    else if (appName.contains('control panel')) await _shell.run('control.exe');
    else if (appName.contains('terminal')) await _shell.run('start cmd.exe');
    else if (appName.contains('brave')) await _shell.run('start brave');
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
