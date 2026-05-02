import 'package:url_launcher/url_launcher.dart';
import 'package:process_run/shell.dart';

class CommandExecutor {
  final Shell _shell = Shell();

  Future<void> execute(String response) async {
    final text = response.toLowerCase();

    // 1. Open Apps
    if (text.contains(RegExp(r'(open|launch) (text editor|notepad)'))) {
      await _shell.run('notepad.exe');
    } else if (text.contains('task manager')) {
      await _shell.run('taskmgr.exe');
    } else if (text.contains('open brave')) {
      // Use full path for reliability
      try {
        await _shell.run(r'start "" "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"');
      } catch (e) {
        await _launchUrl('https://brave.com');
      }
    }

    // 2. Open Websites
    else if (text.contains('open facebook')) {
      await _launchUrl('https://facebook.com');
    } else if (text.contains('open youtube')) {
      await _launchUrl('https://youtube.com');
    } else if (text.contains('open github')) {
      await _launchUrl('https://github.com');
    }

    // 3. Search
    else if (text.contains('search youtube for')) {
      final query = text.split("search youtube for").last.trim().replaceAll(RegExp(r'[^\w\s]'), '');
      await _launchUrl('https://www.youtube.com/results?search_query=$query');
    } else if (text.contains('search facebook for')) {
      final query = text.split("search facebook for").last.trim().replaceAll(RegExp(r'[^\w\s]'), '');
      await _launchUrl('https://www.facebook.com/search/top?q=$query');
    } else if (text.contains('search google for')) {
      final query = text.split("search google for").last.trim().replaceAll(RegExp(r'[^\w\s]'), '');
      await _launchUrl('https://www.google.com/search?q=$query');
    } else if (text.contains('search github for')) {
      final query = text.split("search github for").last.trim().replaceAll(RegExp(r'[^\w\s]'), '');
      await _launchUrl('https://github.com/search?q=$query');
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
