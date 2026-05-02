import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
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
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  ChatProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    sessions = await _historyService.loadAllSessions();
    notifyListeners();
  }

  void selectSession(ChatSession session) {
    messages = session.messages.map((m) => Message(
      role: m['role'],
      content: m['content'],
      timestamp: DateTime.now(), // Simplified for now
    )).toList();
    currentSessionId = session.id;
    notifyListeners();
  }

  void startNewChat() {
    messages.clear();
    currentSessionId = _uuid.v4();
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _historyService.deleteSession(id);
    sessions.removeWhere((s) => s.id == id);
    if (currentSessionId == id) startNewChat();
    notifyListeners();
  }

  void addUserMessage(String text) {
    messages.add(
      Message(
        role: "user",
        content: text,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> sendToAI() async {
    if (isLoading) return; 
    
    // Cooldown logic
    if (DateTime.now().difference(_lastRequestTime).inSeconds < 2) {
      debugPrint("Too fast, Arnab!");
      return;
    }
    _lastRequestTime = DateTime.now();

    isLoading = true;
    notifyListeners();

    // 1. Snapshot history BEFORE adding the assistant placeholder
    // Only keep the last 6 messages to stay within API rate limits
    final List<Message> fullHistory = List.from(messages);
    final List<Message> historyToSend = fullHistory.length > 6 
        ? fullHistory.sublist(fullHistory.length - 6) 
        : fullHistory;

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
      // 3. Listen to the raw stream
      final stream = _service.sendMessageStream(historyToSend);
      
      await for (final token in stream) {
        buffer.write(token);
        tokenCount++;

        // Update the last message
        messages[messages.length - 1] = Message(
          role: "assistant",
          content: buffer.toString(),
          timestamp: DateTime.now(),
        );

        // Throttle: rebuild UI only every 5 tokens
        if (tokenCount % 5 == 0) {
          notifyListeners();
        }
      }
      // Final update
      notifyListeners();
      
      // Parse for command execution (simple keyword check)
      final String lastAssistantResponse = messages.last.content;
      _executor.execute(lastAssistantResponse);

      // Save session
      if (currentSessionId == null) currentSessionId = _uuid.v4();
      final String firstMessage = messages.first.content;
      final session = ChatSession(
        id: currentSessionId!,
        title: firstMessage.length > 20 ? firstMessage.substring(0, 20) : firstMessage,
        messages: messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      );
      await _historyService.saveSession(session);
      _loadHistory();
    } catch (e) {
      debugPrint("Herta encountered an error: $e");
      messages[messages.length - 1] = Message(
        role: "assistant",
        content: "Hmph. My brilliance is too much for this network. (Error: $e)",
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
    notifyListeners();
  }
}
