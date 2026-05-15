import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final dynamic message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == "user";
    final hasAttachment = message.filePath != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.sidebarBackground, // Darker background for fallback
              radius: 16,
              foregroundImage: AssetImage('assets/ineffa_pfp.jpg'),
              // Fallback icon shown if image fails to load
              child: Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary), 
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (hasAttachment) _buildAttachmentPreview(message.filePath!),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primary : AppTheme.sidebarBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser ? AppTheme.secondary.withOpacity(0.2) : Colors.white10,
                      width: 1,
                    ),
                  ),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      color: isUser ? AppTheme.background : AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
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

  Widget _buildAttachmentPreview(String path) {
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
