import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uuid/uuid.dart';

class Persona {
  final String id;
  final String name;
  final String preferredUserName;
  final String tone;
  final String background;
  final String quirks;
  final String? imagePath;

  Persona({
    String? id,
    required this.name,
    required this.preferredUserName,
    required this.tone,
    required this.background,
    required this.quirks,
    this.imagePath,
  }) : this.id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'preferredUserName': preferredUserName,
    'tone': tone,
    'background': background,
    'quirks': quirks,
    'imagePath': imagePath,
  };

  factory Persona.fromJson(Map<String, dynamic> json) => Persona(
    id: json['id'],
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
  static const String _key = 'all_personas';
  static const String _activeIdKey = 'active_persona_id';
  
  List<Persona> _personas = [];
  String? _activePersonaId;

  List<Persona> get personas => _personas;
  
  Persona get currentPersona {
    if (_activePersonaId == null || _personas.isEmpty) return Persona.defaultPersona;
    return _personas.firstWhere((p) => p.id == _activePersonaId, orElse: () => Persona.defaultPersona);
  }

  PersonaService() {
    loadPersonas();
  }

  Future<void> loadPersonas() async {
    final prefs = await SharedPreferences.getInstance();
    final String? personasJson = prefs.getString(_key);
    _activePersonaId = prefs.getString(_activeIdKey);
    
    if (personasJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(personasJson);
        _personas = decoded.map((p) => Persona.fromJson(p)).toList();
      } catch (e) {
        _personas = [Persona.defaultPersona];
      }
    } else {
      _personas = [Persona.defaultPersona];
    }
    notifyListeners();
  }

  Future<void> addPersona(Persona p) async {
    _personas.add(p);
    await _save();
    notifyListeners();
  }

  Future<void> deletePersona(String id) async {
    _personas.removeWhere((p) => p.id == id);
    if (_activePersonaId == id) _activePersonaId = _personas.isNotEmpty ? _personas.first.id : null;
    await _save();
    notifyListeners();
  }

  Future<void> setActivePersona(String id) async {
    _activePersonaId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeIdKey, id);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_personas.map((p) => p.toJson()).toList()));
  }
}
