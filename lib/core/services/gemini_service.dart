import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:herta_assistant_bot/core/ai/system_prompt.dart';
import 'package:herta_assistant_bot/core/models/messages.dart' as models;
import 'package:flutter/foundation.dart';

class GeminiService {
  static const String apiKey = 'AIzaSyDAMfCajOx98GCaqegH5I6ty1Zsc0FYl4o'; 

  // List of models to try in order of preference
  final List<String> _models = ['gemini-2.5-flash', 'gemini-1.5-flash', 'gemini-3.1-flash-lite-preview'];
  int _currentModelIndex = 0;

  GenerativeModel _createModel() {
    return GenerativeModel(
      model: _models[_currentModelIndex],
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
    );
  }

  Stream<String> sendMessageStream(List<models.Message> messages) async* {
    final lastMessage = messages.last;

    try {
      final model = _createModel();
      final chat = model.startChat(history: []);
      final responseStream = chat.sendMessageStream(Content.text(lastMessage.content));

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      debugPrint("Error with model ${_models[_currentModelIndex]}: $e");

      // Attempt fallback if we have more models
      if (_currentModelIndex < _models.length - 1) {
        _currentModelIndex++;
        debugPrint("Falling back to model: ${_models[_currentModelIndex]}");
        yield* sendMessageStream(messages);
      } else {
        yield "Arnab, my networks are congested. Try again in a moment.";
      }
    }
  }
}

