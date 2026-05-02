import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final dynamic message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == "user";
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.primary,
              radius: 16,
              child: Icon(Icons.auto_awesome, size: 16, color: AppTheme.secondary),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
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
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 12),
        ],
      ),
    );
  }
}
