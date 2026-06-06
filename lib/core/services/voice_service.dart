import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  bool _isAvailable = false;
  double _soundLevel = 0.0;

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  bool get isAvailable => _isAvailable;
  double get soundLevel => _soundLevel;

  Future<void> initSpeech() async {
    try {
      _isAvailable = await _speech.initialize(
        debugLogging: true, // Enable detailed Windows logs
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _soundLevel = 0.0;
            notifyListeners();
          }
        },
        onError: (errorNotification) {
          debugPrint('Speech error: $errorNotification');
          _isListening = false;
          _soundLevel = 0.0;
          notifyListeners();
        },
      );
      
      if (_isAvailable) {
        var locales = await _speech.locales();
        debugPrint("VoiceService: Available locales: ${locales.map((l) => l.localeId).join(', ')}");
      }
      
      debugPrint("VoiceService: Initialized, available: $_isAvailable");
      notifyListeners();
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
      _isAvailable = false;
      notifyListeners();
    }
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isAvailable) {
      debugPrint("VoiceService: Not available, attempting to re-init...");
      await initSpeech();
    }

    if (_isAvailable && !_isListening) {
      _lastWords = '';
      _isListening = true;
      _soundLevel = 0.0;
      notifyListeners();

      debugPrint("VoiceService: Starting to listen...");
      
      // Try to find a default locale
      String? localeId;
      try {
        final locales = await _speech.locales();
        if (locales.any((l) => l.localeId == 'en-US')) {
          localeId = 'en-US';
        } else if (locales.isNotEmpty) {
          localeId = locales.first.localeId;
        }
      } catch (_) {}

      try {
        await _speech.listen(
          onResult: (result) {
            _lastWords = result.recognizedWords;
            debugPrint("VoiceService Words: '$_lastWords' (Final: ${result.finalResult})");
            
            if (result.finalResult) {
              _isListening = false;
              _soundLevel = 0.0;
              if (_lastWords.trim().isNotEmpty) {
                onResult(_lastWords);
              } else {
                debugPrint("VoiceService: Listening ended, but no words were recognized.");
              }
              notifyListeners();
            } else {
              notifyListeners();
            }
          },
          onSoundLevelChange: (level) {
            _soundLevel = level;
            notifyListeners();
          },
          localeId: localeId,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 10),
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        );
      } catch (e) {
        debugPrint("VoiceService Listen Error: $e");
        _isListening = false;
        notifyListeners();
      }
    } else {
      debugPrint("VoiceService: Cannot start. Available: $_isAvailable, Listening: $_isListening");
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  void resetWords() {
    _lastWords = '';
    notifyListeners();
  }
}
