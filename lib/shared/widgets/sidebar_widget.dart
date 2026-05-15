import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/chat/provider/chat_provider.dart';
import '../../../core/services/settings_service.dart';
import 'system_info_widget.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  void _showSettingsDialog(BuildContext context) async {
    final settings = SettingsService();
    final currentKey = await settings.getGeminiKey() ?? "";
    final controller = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.sidebarBackground,
        title: const Text("System Settings", style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gemini API Key", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Enter your API key here...",
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.saveGeminiKey(controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("SAVE CHANGES"),
          ),
        ],
      ),
    );
  }

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
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            onTap: () => _showSettingsDialog(context),
            leading: const Icon(Icons.settings_rounded, size: 20, color: AppTheme.textSecondary),
            title: const Text(
              "SETTINGS",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SystemInfoWidget(),
        ],
      ),
    );
  }
}
