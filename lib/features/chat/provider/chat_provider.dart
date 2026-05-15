import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/models/messages.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/command_executor.dart';

class ChatProvider extends ChangeNotifier {
  final GeminiService _service = GeminiService();
  final HistoryService _historyService = HistoryService();
  final CommandExecutor _executor = CommandExecutor();
  final Uuid _uuid = const Uuid();

  List<Message> messages = [];
  List<ChatSession> sessions = [];
  String? currentSessionId;
  bool isLoading = false;
  String? pickedFilePath;
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  ChatProvider() {
    _loadHistory();
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );

    if (result != null) {
      pickedFilePath = result.files.single.path;
      notifyListeners();
    }
  }

  void clearPickedFile() {
    pickedFilePath = null;
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    sessions = await _historyService.loadAllSessions();
    notifyListeners();
  }

  void selectSession(ChatSession session) {
    messages = session.messages.map((m) => Message(
      role: m['role'],
      content: m['content'],
      filePath: m['filePath'],
      timestamp: DateTime.now(), // Simplified for now
    )).toList();
    currentSessionId = session.id;
    notifyListeners();
  }

  void startNewChat() {
    messages.clear();
    pickedFilePath = null;
    currentSessionId = _uuid.v4();
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _historyService.deleteSession(id);
    sessions.removeWhere((s) => s.id == id);
    if (currentSessionId == id) startNewChat();
    notifyListeners();
  }

  void addUserMessage(String text, {String? filePath}) {
    messages.add(
      Message(
        role: "user",
        content: text,
        filePath: filePath,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> sendToAI() async {
    if (isLoading) return; 
    
    // Cooldown logic
    if (DateTime.now().difference(_lastRequestTime).inSeconds < 1) {
      return;
    }
    _lastRequestTime = DateTime.now();

    isLoading = true;
    notifyListeners();

    // 1. Snapshot history BEFORE adding the assistant placeholder
    final List<Message> historyToSend = List.from(messages);

    // 2. Add the empty assistant message for the UI
    messages.add(
      Message(
        role: "assistant",
        content: "",
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    final buffer = StringBuffer();
    int tokenCount = 0;

    try {
      final stream = _service.sendMessageStream(historyToSend);
      
      await for (final token in stream) {
        buffer.write(token);
        tokenCount++;

        messages[messages.length - 1] = Message(
          role: "assistant",
          content: buffer.toString(),
          timestamp: DateTime.now(),
        );

        if (tokenCount % 5 == 0) {
          notifyListeners();
        }
      }
      notifyListeners();
      
      final String lastAssistantResponse = messages.last.content;
      _executor.execute(lastAssistantResponse);

      if (currentSessionId == null) currentSessionId = _uuid.v4();
      final String firstMessage = messages.first.content;
      final session = ChatSession(
        id: currentSessionId!,
        title: firstMessage.length > 20 ? firstMessage.substring(0, 20) : firstMessage,
        messages: messages.map((m) => {
          'role': m.role, 
          'content': m.content,
          'filePath': m.filePath,
        }).toList(),
      );
      await _historyService.saveSession(session);
      _loadHistory();
    } catch (e) {
      debugPrint("Ineffa encountered an error: $e");
      messages[messages.length - 1] = Message(
        role: "assistant",
        content: "Arnab, my networks are congested. (Error: $e)",
        timestamp: DateTime.now(),
      );
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    messages.clear();
    pickedFilePath = null;
    notifyListeners();
  }
}
