import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Persona {
  final String name;
  final String preferredUserName;
  final String tone;
  final String background;
  final String quirks;
  final String? imagePath;

  Persona({
    required this.name,
    required this.preferredUserName,
    required this.tone,
    required this.background,
    required this.quirks,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'preferredUserName': preferredUserName,
    'tone': tone,
    'background': background,
    'quirks': quirks,
    'imagePath': imagePath,
  };

  factory Persona.fromJson(Map<String, dynamic> json) => Persona(
    name: json['name'] ?? 'Ineffa',
    preferredUserName: json['preferredUserName'] ?? 'Arnab',
    tone: json['tone'] ?? 'Cheery, robotic, and polite.',
    background: json['background'] ?? 'A robotic assistant designed to help.',
    quirks: json['quirks'] ?? 'Uses puns and refers to the user warmly.',
    imagePath: json['imagePath'],
  );

  static Persona get defaultPersona => Persona(
    name: 'Unconfigured Identity',
    preferredUserName: 'User',
    tone: 'Polite and awaiting instructions.',
    background: 'A new assistant waiting for its creator to define its purpose and personality.',
    quirks: 'Reminds the user to set a personality in the PERSONA menu.',
    imagePath: null,
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
