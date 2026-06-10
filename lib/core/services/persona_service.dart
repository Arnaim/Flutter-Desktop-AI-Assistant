import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Persona {
  final String name;
  final String tone;
  final String background;
  final String quirks;

  Persona({
    required this.name,
    required this.tone,
    required this.background,
    required this.quirks,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'tone': tone,
    'background': background,
    'quirks': quirks,
  };

  factory Persona.fromJson(Map<String, dynamic> json) => Persona(
    name: json['name'] ?? 'Ineffa',
    tone: json['tone'] ?? 'Cheery, robotic, and polite.',
    background: json['background'] ?? 'A robotic assistant from Nod-Krai, designed to help Arnab.',
    quirks: json['quirks'] ?? 'Uses puns, refers to the user as Arnab, and has a slight robotic stutter in text sometimes.',
  );

  static Persona get defaultPersona => Persona(
    name: 'Ineffa',
    tone: 'Cheery, robotic, and polite.',
    background: 'A robotic assistant from Nod-Krai, designed to help Arnab.',
    quirks: 'Uses puns, refers to the user as Arnab, and loves to express her moods via system-wide color changes.',
  );
}

class PersonaService extends ChangeNotifier {
  static const String _key = 'custom_persona';
  Persona _currentPersona = Persona.defaultPersona;

  Persona get currentPersona => _currentPersona;

  PersonaService() {
    loadPersona();
  }

  Future<void> loadPersona() async {
    final prefs = await SharedPreferences.getInstance();
    final String? personaJson = prefs.getString(_key);
    if (personaJson != null) {
      try {
        _currentPersona = Persona.fromJson(jsonDecode(personaJson));
      } catch (e) {
        debugPrint("PersonaService: Failed to decode persona: $e");
        _currentPersona = Persona.defaultPersona;
      }
    } else {
      _currentPersona = Persona.defaultPersona;
    }
    notifyListeners();
  }

  Future<void> updatePersona(Persona newPersona) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(newPersona.toJson()));
    _currentPersona = newPersona;
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _currentPersona = Persona.defaultPersona;
    notifyListeners();
  }
}
