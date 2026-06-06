import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../theme/app_theme.dart';

class ThemeService extends ChangeNotifier {
  Mood _currentMood = Mood.neutral;

  Mood get currentMood => _currentMood;

  ThemeData get themeData => AppTheme.getThemeData(_currentMood);

  void setMood(Mood newMood) {
    if (_currentMood != newMood) {
      _currentMood = newMood;
      notifyListeners();
    }
  }
}
