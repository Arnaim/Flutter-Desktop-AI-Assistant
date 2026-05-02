import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/chat/provider/chat_provider.dart';
import 'system_info_widget.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBackground,
        border: Border(right: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: chat.startNewChat,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text("NEW RESEARCH"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary.withOpacity(0.8),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: chat.sessions.length,
              itemBuilder: (context, index) {
                final session = chat.sessions[index];
                final isSelected = chat.currentSessionId == session.id;
                return ListTile(
                  onTap: () => chat.selectSession(session),
                  selected: isSelected,
                  selectedTileColor: AppTheme.primary.withOpacity(0.2),
                  leading: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: isSelected ? AppTheme.secondary : AppTheme.textSecondary,
                  ),
                  title: Text(
                    session.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  trailing: isSelected
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          onPressed: () => chat.deleteSession(session.id),
                        )
                      : null,
                );
              },
            ),
          ),
          const SystemInfoWidget(),
        ],
      ),
    );
  }
}
