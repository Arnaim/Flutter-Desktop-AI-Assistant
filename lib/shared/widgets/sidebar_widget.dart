import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/chat/provider/chat_provider.dart';
import '../../../core/services/settings_service.dart';
import 'hardware_dashboard.dart';
import 'glass_container.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  void _showSettingsDialog(BuildContext context) async {
    final settings = SettingsService();
    final currentKey = await settings.getGeminiKey() ?? "";
    final keyController = TextEditingController(text: currentKey);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.sidebarBackground.withOpacity(0.8),
        title: const Text("System Settings", style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ineffa Intelligence Key", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: keyController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: "Key (e.g. freellmapi-xxx) or Key|URL",
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
              await settings.saveGeminiKey(keyController.text.trim());
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
    final theme = Theme.of(context);
    return GlassContainer(
      width: 260,
      color: theme.colorScheme.surface,
      opacity: 0.15,
      blur: 12,
      border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
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
                backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
                foregroundColor: Colors.white,
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
                  selectedTileColor: theme.colorScheme.primary.withOpacity(0.2),
                  leading: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.tertiary,
                  ),
                  title: Text(
                    session.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.secondary,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub_rounded, size: 14, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      "ACTIVE INTELLIGENCE",
                      style: TextStyle(color: theme.colorScheme.tertiary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTapDown: (details) {
                    final List<PopupMenuEntry<String?>> items = [
                      PopupMenuItem<String?>(
                        onTap: () => chat.refreshModels(),
                        child: const Row(
                          children: [
                            Icon(Icons.sync_rounded, size: 14, color: Colors.greenAccent),
                            SizedBox(width: 8),
                            Text("SYNC: Live Models", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String?>(
                        value: null,
                        child: Text("AUTO: Neural Sync", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const PopupMenuDivider(),
                      ...chat.availableModels.map((m) => PopupMenuItem<String>(
                        value: m,
                        child: Text(m.toUpperCase(), style: const TextStyle(fontSize: 11)),
                      )),
                    ];

                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                      ),
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      items: items,
                    ).then((value) {
                      if (value != null || value == null) {
                         chat.setManualModel(value);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            chat.activeModel.split('/').last.toUpperCase(),
                            style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.swap_vert_rounded, size: 14, color: theme.colorScheme.secondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            onTap: () => _showSettingsDialog(context),
            leading: Icon(Icons.settings_rounded, size: 20, color: theme.colorScheme.tertiary),
            title: Text(
              "SETTINGS",
              style: TextStyle(color: theme.colorScheme.tertiary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const HardwareDashboard(),
        ],
      ),
    );
  }
}
