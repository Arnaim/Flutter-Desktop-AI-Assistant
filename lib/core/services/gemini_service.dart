import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ineffa_assistant_bot/core/ai/system_prompt.dart';
import 'package:ineffa_assistant_bot/core/models/messages.dart' as models;
import 'package:ineffa_assistant_bot/core/services/settings_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class GeminiService {
  final SettingsService _settings = SettingsService();

  // List of models to try in order of preference
  final List<String> _models = ['gemini-1.5-flash', 'gemini-2.5-flash'];
  int _currentModelIndex = 0;

  Future<GenerativeModel> _createModel() async {
    final apiKey = await _settings.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("API Key missing, Arnab. Please add it in settings.");
    }
    
    // Gather environmental context
    final String homeDir = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\naimu';
    final String userName = p.basename(homeDir); // Extracts 'naimu' from 'C:\Users\naimu'
    final String os = Platform.operatingSystem;
    
    final envContext = """
ENVIRONMENTAL CONTEXT:
- Operating System: $os
- Current User Folder: $userName
- Home Directory Path: $homeDir
- Common Paths: 
  - Documents: $homeDir\\Documents
  - Desktop: $homeDir\\Desktop
  - Downloads: $homeDir\\Downloads
""";

    return GenerativeModel(
      model: _models[_currentModelIndex],
      apiKey: apiKey,
      systemInstruction: Content('system', [TextPart(systemPrompt + "\n\n" + envContext)]),
    );
  }

  String _getMimeType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Stream<String> sendMessageStream(List<models.Message> messages) async* {
    if (_currentModelIndex >= _models.length) _currentModelIndex = 0;
    
    final lastMessage = messages.last;

    try {
      final model = await _createModel();
      final chat = model.startChat(history: []);
      
      final List<Part> parts = [Content.text(lastMessage.content).parts.first];
      
      if (lastMessage.filePath != null) {
        final file = File(lastMessage.filePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final mimeType = _getMimeType(lastMessage.filePath!);
          parts.add(DataPart(mimeType, bytes));
        }
      }

      final responseStream = chat.sendMessageStream(Content.multi(parts));

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint("Ineffa Error (${_models[_currentModelIndex]}): $errorMsg");

      if (errorMsg.contains("API_KEY_INVALID") || errorMsg.contains("API Key missing") || errorMsg.contains("PERMISSION_DENIED")) {
        yield "Arnab, there is an issue with your API Key. Please check it in Settings.";
        return;
      }

      if (_currentModelIndex < _models.length - 1) {
        _currentModelIndex++;
        yield* sendMessageStream(messages);
      } else {
        if (errorMsg.contains("429")) {
          yield "Arnab, you are talking too fast! My processors are overheating (Rate Limit). Try again in 60 seconds.";
        } else {
          yield "Arnab, I encountered a system glitch. (Error: $errorMsg)";
        }
      }
    }
  }
}
