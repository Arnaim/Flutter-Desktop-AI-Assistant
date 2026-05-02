class Message {
  final String role; // "user" or "assistant"
  final String content;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}