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
    // New regex: Looks for [COMMAND: ACTION: VALUE] or [COMMAND: ACTION]
    final commandRegex = RegExp(r'\[COMMAND:\s*([^\]:]+)(?::\s*([^\]]+))?\]', caseSensitive: false);
    final matches = commandRegex.allMatches(response);

    print("Parsing response: $response");

    for (var match in matches) {
      final action = match.group(1)?.trim().toUpperCase() ?? '';
      final value = match.group(2)?.trim() ?? '';

      debugPrint("Matched Command: Action=$action, Value=$value");

      if (action == 'MEMORIZE') {
        await _memoryService.saveMemory(value);
      } else if (action == 'INITIATE_OPTICAL_SCAN') {
        if (onCaptureRequest != null) onCaptureRequest();
      } else if (action == 'WRITE NOTEPAD') {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}\\ineffa_note.txt');
        await file.writeAsString(value);
        await _shell.run('notepad.exe "${file.path}"');
      } else if (action == 'TYPE') {
        // More robust PowerShell escaping for SendKeys
        final escaped = value.replaceAll("'", "''").replaceAll('"', '`"');
        await _shell.run('powershell -Command "Add-Type -AssemblyName System.Windows.Forms; Start-Sleep -Milliseconds 800; [System.Windows.Forms.SendKeys]::SendWait(\'$escaped\')"');
      } else if (action == 'OPEN PATH') {
        await _shell.run('explorer.exe "$value"');
      } else if (action == 'OPEN APP') {
        await _handleAppLaunch(value.toLowerCase());
      } else if (action == 'SEARCH GOOGLE') {
        await _launchUrl('https://www.google.com/search?q=$value');
      } else if (action == 'SEARCH YOUTUBE') {
        await _launchUrl('https://www.youtube.com/results?search_query=$value');
      } else if (action == 'SYSTEM COMMAND' || action == 'RUN') {
        // Allow direct execution of system commands like WMIC
        try {
           await _shell.run(value);
        } catch (e) {
           debugPrint("Command Execution failed: $e");
        }
      }
    }
  }

  Future<void> _handleAppLaunch(String appName) async {
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
      await launchUrl(url);
    }
  }
}
