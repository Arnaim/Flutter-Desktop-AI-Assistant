import 'dart:typed_data';

class Message {
  final String role; // "user" or "assistant"
  final String content;
  final String? reasoningDetails; // Advanced thinking context for 2026 models
  final String? filePath; // Optional path for images/files
  final Uint8List? imageBytes; // Optional bytes for screenshots
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    this.reasoningDetails,
    this.filePath,
    this.imageBytes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'reasoningDetails': reasoningDetails,
    'filePath': filePath,
    // Note: imageBytes are not saved to disk for privacy
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    role: json['role'],
    content: json['content'],
    reasoningDetails: json['reasoningDetails'],
    filePath: json['filePath'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class ChatSession {
  final String id;
  final String title;
  final List<Message> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList(),
    );
  }
}
