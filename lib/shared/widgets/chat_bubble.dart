import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final dynamic message;
  const ChatBubble({super.key, required this.message});

  // Helper to clean command codes from the display text
  String _cleanContent(String content) {
    return content
        .replaceAll(RegExp(r'\[COMMAND:.*?\]'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == "user";
    final hasFilePath = message.filePath != null;
    final hasImageBytes = message.imageBytes != null;
    final cleanText = _cleanContent(message.content);

    // If the message only contained a command code, don't show an empty bubble
    if (cleanText.isEmpty && !hasFilePath && !hasImageBytes) {
       return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: theme.colorScheme.surface, 
              radius: 16,
              foregroundImage: const AssetImage('assets/ineffa_pfp.jpg'),
              child: Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary), 
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (hasFilePath) _buildFilePreview(message.filePath!),
                if (hasImageBytes) _buildBytesPreview(message.imageBytes),

                if (cleanText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isUser ? theme.colorScheme.primary.withOpacity(0.5) : Colors.white10,
                        width: 1,
                      ),
                    ),
                    child: SelectableText(
                      cleanText,
                      style: TextStyle(
                        color: isUser ? Colors.black87 : theme.textTheme.bodyMedium?.color,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildBytesPreview(dynamic bytes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.memory(bytes, fit: BoxFit.cover),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded, size: 10, color: Colors.white),
                  SizedBox(width: 4),
                  Text("SCREENSHOT", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(String path) {
    final isImage = ['.jpg', '.jpeg', '.png', '.webp'].any((ext) => path.toLowerCase().endsWith(ext));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: isImage
          ? Image.file(File(path), fit: BoxFit.cover)
          : Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.sidebarBackground,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      path.split(Platform.pathSeparator).last,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
