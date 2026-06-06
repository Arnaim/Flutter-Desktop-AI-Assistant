import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/messages.dart';

class HistoryService {
  Future<Directory> _getStorageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final historyDir = Directory('${appDir.path}/chat_history');
    if (!await historyDir.exists()) {
      await historyDir.create(recursive: true);
    }
    return historyDir;
  }

  Future<List<ChatSession>> loadAllSessions() async {
    final dir = await _getStorageDir();
    final files = dir.listSync().whereType<File>();
    final sessions = <ChatSession>[];
    for (var file in files) {
      try {
        final content = await file.readAsString();
        sessions.add(ChatSession.fromJson(jsonDecode(content)));
      } catch (e) {
        // Skip corrupted files
        continue;
      }
    }
    return sessions;
  }

  Future<void> saveSession(ChatSession session) async {
    final dir = await _getStorageDir();
    final file = File('${dir.path}/${session.id}.json');
    await file.writeAsString(jsonEncode(session.toJson()));
  }

  Future<void> deleteSession(String id) async {
    final dir = await _getStorageDir();
    final file = File('${dir.path}/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
