import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/chat/provider/chat_provider.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/persona_service.dart';
import '../../../core/services/voice_service.dart';
import 'hardware_dashboard.dart';
import 'glass_container.dart';

import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  void _showPersonaDialog(BuildContext context) {
    final personaService = context.read<PersonaService>();
    final current = personaService.currentPersona;
    
    final nameController = TextEditingController(text: current.name);
    final toneController = TextEditingController(text: current.tone);
    final backgroundController = TextEditingController(text: current.background);
    final quirksController = TextEditingController(text: current.quirks);
    String? pickedImagePath = current.imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900]?.withOpacity(0.95),
          title: const Text("Persona Editor", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                    if (result != null) {
                      setDialogState(() => pickedImagePath = result.files.single.path);
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white10,
                    backgroundImage: pickedImagePath != null 
                        ? (pickedImagePath!.startsWith('assets') ? AssetImage(pickedImagePath!) as ImageProvider : FileImage(File(pickedImagePath!)))
                        : null,
                    child: pickedImagePath == null ? const Icon(Icons.add_a_photo, color: Colors.white54) : null,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPersonaField("Identity Name", nameController),
                _buildPersonaField("Behavioral Tone", toneController),
                _buildPersonaField("Lore Background", backgroundController, maxLines: 3),
                _buildPersonaField("Unique Quirks", quirksController, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                personaService.resetToDefault();
                Navigator.pop(context);
              },
              child: const Text("RESET", style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
                personaService.updatePersona(Persona(
                  name: nameController.text.trim(),
                  tone: toneController.text.trim(),
                  background: backgroundController.text.trim(),
                  quirks: quirksController.text.trim(),
                  imagePath: pickedImagePath,
                ));
                Navigator.pop(context);
              },
              child: const Text("APPLY"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) async {
    final settings = SettingsService();
    final currentKey = await settings.getGeminiKey() ?? "";
    final keyController = TextEditingController(text: currentKey);
    final voiceService = context.read<VoiceService>();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Consumer<VoiceService>(
        builder: (context, voice, child) => AlertDialog(
          backgroundColor: AppTheme.sidebarBackground.withOpacity(0.95),
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
              const SizedBox(height: 24),
              const Text("Voice System Status", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: voice.isAvailable ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          voice.isAvailable ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: voice.isAvailable ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          voice.isAvailable ? "Speech Engine Ready" : "Speech Engine Offline",
                          style: TextStyle(color: voice.isAvailable ? Colors.green : Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (voice.lastError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Error: ${voice.lastError}",
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => voice.initSpeech(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text("RE-INITIALIZE MIC"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
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
            onTap: () => _showPersonaDialog(context),
            leading: Icon(Icons.face_retouching_natural_rounded, size: 20, color: theme.colorScheme.primary),
            title: Text(
              "PERSONA",
              style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
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
