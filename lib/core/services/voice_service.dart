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
          debugPrint('Speech error: ${errorNotification.errorMsg} - Permanent: ${errorNotification.permanent}');
          _isListening = false;
          _soundLevel = 0.0;
          notifyListeners();
        },
      );
      
      if (_isAvailable) {
        debugPrint("VoiceService: Successfully initialized.");
      } else {
        debugPrint("VoiceService: Initialization returned false (Available: false).");
      }
      notifyListeners();
    } catch (e) {
      debugPrint('VoiceService: Speech initialization failed with exception: $e');
      _isAvailable = false;
      notifyListeners();
    }
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
            debugPrint("VoiceService Words: '$_lastWords' (Final: ${result.finalResult})");
            
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
            _soundLevel = level;
            notifyListeners();
          },
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 5),
          cancelOnError: false,
          listenMode: ListenMode.confirmation, // Changed to confirmation for better Windows accuracy
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
