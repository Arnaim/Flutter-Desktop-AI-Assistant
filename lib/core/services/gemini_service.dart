import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ineffa_assistant_bot/core/ai/system_prompt.dart';
import 'package:ineffa_assistant_bot/core/models/messages.dart' as models;
import 'package:ineffa_assistant_bot/core/services/settings_service.dart';
import 'package:ineffa_assistant_bot/core/services/memory_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'theme_service.dart';
import '../models/mood.dart';

class CustomBaseUrlClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final String customBaseUrl;

  CustomBaseUrlClient(this.customBaseUrl);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final uri = Uri.parse(customBaseUrl);
    
    // Merge the custom base URL with the request URL
    // We prepend the custom path if it exists (e.g. /v1)
    String newPath = uri.path;
    if (newPath.endsWith('/')) {
      newPath = newPath.substring(0, newPath.length - 1);
    }
    newPath += request.url.path;

    final newUri = request.url.replace(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.port,
      path: newPath,
    );
    
    final newRequest = http.Request(request.method, newUri)
      ..headers.addAll(request.headers)
      ..bodyBytes = (request as http.Request).bodyBytes;

    // Some unified APIs require 'Authorization: Bearer <key>' 
    // instead of the 'x-goog-api-key' header used by the Gemini SDK.
    if (request.headers.containsKey('x-goog-api-key')) {
      final apiKey = request.headers['x-goog-api-key'];
      newRequest.headers['Authorization'] = 'Bearer $apiKey';
    }

    return _inner.send(newRequest);
  }
}

class GeminiService {
  final SettingsService _settings = SettingsService();
  final MemoryService _memoryService = MemoryService();
  final ThemeService _themeService;

  GeminiService(this._themeService) {
    _initializeModels();
  }

  void _initializeModels() async {
    // Try to fetch models if we have a key
    await fetchAvailableModels();
  }

  (Mood, String) _extractMood(String raw) {
    final moodPattern = RegExp(r'\[MOOD:\s*(\w+)\s*\]', caseSensitive: false);
    final match = moodPattern.firstMatch(raw);

    Mood mood = Mood.neutral;
    if (match != null) {
      mood = Mood.values.firstWhere(
        (m) => m.name.toLowerCase() == match.group(1)?.toLowerCase(),
        orElse: () => Mood.neutral,
      );
    }

    final cleaned = raw.replaceAll(moodPattern, '').trim();
    return (mood, cleaned);
  }

  // Expanded Model Pool - Mixture of Gemini and other popular models
  List<String> _models = [
    "gemini-3.1-flash-lite",       
    "gemini-2.0-flash-exp",        
    "gemini-2.0-pro-exp-02-05",    
    "gemini-1.5-flash",            
    "gemini-1.5-pro",             
    "gpt-4o",
    "gpt-4o-mini",
    "claude-3-5-sonnet",
    "llama-3.1-405b",
    "o1-preview",
  ];

  int _currentModelIndex = 0;
  String? _manualModelOverride;

  String get activeModel => _manualModelOverride ?? _models[_currentModelIndex];
  List<String> get availableModels => _models;

  void setManualModel(String? modelId) {
    _manualModelOverride = modelId;
    if (modelId == null) _currentModelIndex = 0; 
  }

  Future<void> fetchAvailableModels() async {
    try {
      final rawKeyInput = await _settings.getGeminiKey();
      if (rawKeyInput == null || rawKeyInput.isEmpty) return;

      final parts = rawKeyInput.split('|');
      final apiKey = parts[0].trim();
      String? customUrl = parts.length > 1 ? parts[1].trim() : null;

      if (!apiKey.startsWith('freellmapi-')) return;

      final String url = (customUrl != null && customUrl.isNotEmpty) 
          ? customUrl 
          : "http://localhost:3001/v1";
      
      final endpoint = url.endsWith('/') ? "${url}models" : "$url/models";

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {"Authorization": "Bearer $apiKey"},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'] is List) {
          final List<String> fetched = [];
          for (var m in data['data']) {
            if (m['id'] != null) fetched.add(m['id']);
          }
          if (fetched.isNotEmpty) {
            _models = fetched;
            debugPrint("Ineffa: Synced ${fetched.length} models from proxy.");
          }
        }
      }
    } catch (e) {
      debugPrint("Ineffa: Could not fetch dynamic models: $e");
    }
  }

  Future<String> _getSystemInstruction() async {
    final String homeDir = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\naimu';
    final String userName = p.basename(homeDir); 
    final String os = Platform.operatingSystem;

    final memories = await _memoryService.loadMemories();
    final memoryContext = memories.isNotEmpty 
      ? "\n\nGLOBAL MEMORIES OF ARNAB:\n${memories.map((m) => '- $m').join('\n')}"
      : "";

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

    return systemPrompt + memoryContext + "\n\n" + envContext;
  }

  String _getMimeType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg': return 'image/jpeg';
      case '.png': return 'image/png';
      case '.webp': return 'image/webp';
      case '.pdf': return 'application/pdf';
      default: return 'image/jpeg';
    }
  }

  Future<String> sendMessage(List<models.Message> messages) async {
    final String modelId = _manualModelOverride ?? _models[_currentModelIndex];
    
    try {
      final rawKeyInput = await _settings.getGeminiKey();
      if (rawKeyInput == null || rawKeyInput.isEmpty) {
        throw Exception("Intelligence Key missing, Arnab. Please add it in settings.");
      }

      // Smart Key Parsing: "key" or "key|url"
      final parts = rawKeyInput.split('|');
      final apiKey = parts[0].trim();
      String? customUrl = parts.length > 1 ? parts[1].trim() : null;

      // Detect Provider
      final isFreeLLM = apiKey.startsWith('freellmapi-');

      if (isFreeLLM) {
        // FreeLLMAPI / OpenAI-compatible direct logic
        return await _sendOpenAiRequest(apiKey, customUrl, modelId, messages);
      } else {
        // Standard Google Gemini logic
        return await _sendGeminiRequest(apiKey, customUrl, modelId, messages);
      }
    } catch (e) {
      debugPrint("Ineffa Error ($modelId): $e");
      return "Arnab, I encountered a system glitch. (Error: $e)";
    }
  }

  Future<String> _sendGeminiRequest(String apiKey, String? baseUrl, String modelId, List<models.Message> messages) async {
    final systemInstruction = await _getSystemInstruction();
    
    final model = GenerativeModel(
      model: modelId,
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
      httpClient: baseUrl != null && baseUrl.isNotEmpty 
          ? CustomBaseUrlClient(baseUrl) 
          : null,
    );

    final List<Content> history = [];
    for (var m in messages) {
      List<Part> parts = [TextPart(m.content)];
      if (m.imageBytes != null) parts.add(DataPart('image/jpeg', m.imageBytes!));
      else if (m.filePath != null) {
        final file = File(m.filePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          parts.add(DataPart(_getMimeType(m.filePath!), bytes));
        }
      }
      history.add(Content(m.role == 'assistant' ? 'model' : 'user', parts));
    }

    final response = await model.generateContent(history);
    return _processResponse(response.text ?? "");
  }

  Future<String> _sendOpenAiRequest(String apiKey, String? baseUrl, String modelId, List<models.Message> messages) async {
    // Use 127.0.0.1 instead of localhost to avoid DNS/IPv6 issues on Windows
    final String url = (baseUrl != null && baseUrl.isNotEmpty) 
        ? baseUrl 
        : "http://127.0.0.1:3001/v1";
    
    final endpoint = url.endsWith('/') ? "${url}chat/completions" : "$url/chat/completions";

    final systemInstruction = await _getSystemInstruction();
    
    final List<Map<String, dynamic>> openAiMessages = [
      {"role": "system", "content": systemInstruction}
    ];

    for (var m in messages) {
      // Basic support for Vision if the proxy supports it (OpenAI format)
      if (m.imageBytes != null || m.filePath != null) {
        // Multi-modal message format
        List<Map<String, dynamic>> content = [
          {"type": "text", "text": m.content}
        ];
        
        String? base64Image;
        if (m.imageBytes != null) {
          base64Image = base64Encode(m.imageBytes!);
        } else if (m.filePath != null) {
          final file = File(m.filePath!);
          if (await file.exists()) {
            base64Image = base64Encode(await file.readAsBytes());
          }
        }

        if (base64Image != null) {
          content.add({
            "type": "image_url",
            "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
          });
        }

        openAiMessages.add({
          "role": m.role == 'assistant' ? 'assistant' : 'user',
          "content": content,
        });
      } else {
        // Standard text message
        openAiMessages.add({
          "role": m.role == 'assistant' ? 'assistant' : 'user',
          "content": m.content,
        });
      }
    }

    debugPrint("Ineffa: Sending request to $endpoint using model $modelId");

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": modelId,
        "messages": openAiMessages,
        "temperature": 0.7,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      debugPrint("Ineffa: Proxy error body: ${response.body}");
      throw Exception("Proxy Error (${response.statusCode}): ${response.body}");
    }

    final data = jsonDecode(response.body);
    final String content = data['choices'][0]['message']['content'] ?? "";
    return _processResponse(content);
  }

  String _processResponse(String rawText) {
    // Detailed debug
    debugPrint("--- Mood Debug Start ---");
    debugPrint("Raw Text: $rawText");
    
    final (detectedMood, cleanedText) = _extractMood(rawText);
    debugPrint("Detected Mood: $detectedMood");
    
    _themeService.setMood(detectedMood);
    debugPrint("ThemeService Mood updated to: ${_themeService.currentMood}");
    debugPrint("--- Mood Debug End ---");
    
    return cleanedText;
  }

  // Fallback streaming for backward compatibility or future use
  Stream<String> sendMessageStream(List<models.Message> messages, {Function(String)? onReasoningReceived}) async* {
    final response = await sendMessage(messages);
    yield response;
  }
}
