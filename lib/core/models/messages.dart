class Message {
  final String role; // "user" or "assistant"
  final String content;
  final String? filePath; // Optional path for images/files
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    this.filePath,
    required this.timestamp,
  });
}