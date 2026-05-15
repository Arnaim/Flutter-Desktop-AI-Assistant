import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _geminiKey = 'gemini_api_key';

  Future<void> saveGeminiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, key);
  }

  Future<String?> getGeminiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKey);
  }
}