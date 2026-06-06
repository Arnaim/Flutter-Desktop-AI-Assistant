import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MemoryService {
  Future<File> _getMemoryFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/global_memory.json');
  }

  Future<List<String>> loadMemories() async {
    try {
      final file = await _getMemoryFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> json = jsonDecode(content);
      return json.cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveMemory(String fact) async {
    final memories = await loadMemories();
    if (!memories.contains(fact)) {
      memories.add(fact);
      final file = await _getMemoryFile();
      await file.writeAsString(jsonEncode(memories));
    }
  }

  Future<void> clearMemories() async {
    final file = await _getMemoryFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
