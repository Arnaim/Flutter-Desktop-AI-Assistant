import 'package:url_launcher/url_launcher.dart';
import 'package:process_run/shell.dart';
import 'dart:io';

class CommandExecutor {
  final Shell _shell = Shell();

  Future<void> execute(String response) async {
    final text = response.toLowerCase();

    // 1. Open Folders/Files (Generic 'Open path: [path]')
    if (text.contains('open path:')) {
      final path = _extractValue(text, 'open path:');
      if (path != null) {
        await _shell.run('explorer.exe "$path"');
      }
    }

    // 2. Open System Apps
    else if (text.contains(RegExp(r'(open|launch) (text editor|notepad)'))) {
      await _shell.run('notepad.exe');
    } else if (text.contains('task manager')) {
      await _shell.run('taskmgr.exe');
    } else if (text.contains('control panel')) {
      await _shell.run('control.exe');
    } else if (text.contains('command prompt') || text.contains('terminal')) {
      await _shell.run('start cmd.exe');
    }

    // 3. System Actions
    else if (text.contains('list files in:')) {
      final path = _extractValue(text, 'list files in:');
      if (path != null) {
        // This is handled by the AI's personality, but we could trigger a UI popup
        // For now, we'll just open the folder
        await _shell.run('explorer.exe "$path"');
      }
    }

    // 4. Web Control
    else if (text.contains('search youtube for')) {
      final query = _extractValue(text, 'search youtube for');
      if (query != null) await _launchUrl('https://www.youtube.com/results?search_query=$query');
    } else if (text.contains('search google for')) {
      final query = _extractValue(text, 'search google for');
      if (query != null) await _launchUrl('https://www.google.com/search?q=$query');
    } else if (text.contains('open ')) {
      // Catch-all for basic "open [website]"
      if (text.contains('youtube')) await _launchUrl('https://youtube.com');
      else if (text.contains('facebook')) await _launchUrl('https://facebook.com');
      else if (text.contains('github')) await _launchUrl('https://github.com');
      else if (text.contains('google')) await _launchUrl('https://google.com');
    }
  }

  String? _extractValue(String text, String prefix) {
    try {
      final part = text.split(prefix).last.trim();
      // Take everything until the first period or end of line
      return part.split('.').first.trim();
    } catch (e) {
      return null;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
