import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  bool _isAvailable = false;
  double _soundLevel = 0.0;
  String? _lastError;

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  bool get isAvailable => _isAvailable;
  double get soundLevel => _soundLevel;
  String? get lastError => _lastError;

  Future<void> initSpeech() async {
    try {
      _lastError = null;
      debugPrint("VoiceService: Attempting initialization...");
      _isAvailable = await _speech.initialize(
        debugLogging: true,
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _soundLevel = 0.0;
            notifyListeners();
          }
        },
        onError: (errorNotification) {
          _lastError = "${errorNotification.errorMsg} (${errorNotification.permanent ? 'Permanent' : 'Transient'})";
          debugPrint('VoiceService Error: $_lastError');
          _isListening = false;
          _soundLevel = 0.0;
          notifyListeners();
        },
      );
      
      if (!_isAvailable) {
        _lastError = "Speech recognition not available on this device. Ensure 'Online Speech Recognition' is enabled in Windows Settings.";
      }
      
      notifyListeners();
    } catch (e) {
      _lastError = "Initialization failed: $e";
      debugPrint('VoiceService Exception: $e');
      _isAvailable = false;
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isAvailable) {
      debugPrint("VoiceService: Not available, re-initializing...");
      await initSpeech();
    }

    if (_isAvailable && !_isListening) {
      _lastWords = '';
      _isListening = true;
      _soundLevel = 0.0;
      notifyListeners();

      debugPrint("VoiceService: Starting to listen (no-locale-lock mode)...");
      
      try {
        await _speech.listen(
          onResult: (result) {
            _lastWords = result.recognizedWords;
            debugPrint("VoiceService: [RESULT] recognizedWords: '$_lastWords' (Final: ${result.finalResult})");
            
            if (result.finalResult) {
              _isListening = false;
              _soundLevel = 0.0;
              notifyListeners();
              
              if (_lastWords.trim().isNotEmpty) {
                onResult(_lastWords);
              }
            } else {
              notifyListeners();
            }
          },
          onSoundLevelChange: (level) {
            // Log if sound is actually detected
            if (level > 0.5) {
               debugPrint("VoiceService: [LEVEL DETECTED] $level");
            }
            _soundLevel = level;
            notifyListeners();
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 10),
          cancelOnError: false,
          listenMode: ListenMode.dictation, // Dictation is often more reliable for long speech on Windows
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
