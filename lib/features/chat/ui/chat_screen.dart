import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../provider/chat_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_title_bar.dart';
import '../../../shared/widgets/sidebar_widget.dart';
import '../../../shared/widgets/chat_bubble.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initHotkeys();
    inputFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
        if (!HardwareKeyboard.instance.isShiftPressed) {
          sendMessage(context.read<ChatProvider>());
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _initHotkeys() async {
    await hotKeyManager.register(
      HotKey(
        key: LogicalKeyboardKey.space,
        modifiers: [HotKeyModifier.alt],
        scope: HotKeyScope.system,
      ),
      keyDownHandler: (hotKey) async {
        bool isVisible = await windowManager.isVisible();
        if (isVisible) {
          await windowManager.hide();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    inputFocusNode.dispose();
    super.dispose();
  }

  void sendMessage(ChatProvider chat) {
    final text = controller.text.trim();
    if (text.isEmpty && chat.pickedFilePath == null) return;
    
    final String? filePath = chat.pickedFilePath;
    chat.clearPickedFile(); // Clear preview immediately
    controller.clear();
    
    chat.addUserMessage(text.isEmpty ? "Analyze this file." : text, filePath: filePath);
    chat.sendToAI();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      body: Column(
        children: [
          const CustomTitleBar(),
          Expanded(
            child: Row(
              children: [
                const SidebarWidget(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chat.messages[index];
                            return ChatBubble(message: msg);
                          },
                        ),
                      ),
                      if (chat.pickedFilePath != null) _buildFilePreview(chat),
                      _buildInputArea(chat),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_file, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                p.basename(chat.pickedFilePath!),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: chat.clearPickedFile,
              child: const Icon(Icons.close, size: 16, color: AppTheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.sidebarBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: AppTheme.secondary),
              onPressed: chat.pickFile,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: inputFocusNode,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "How can Ineffa assist you today, Arnab?",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppTheme.secondary),
              onPressed: () => sendMessage(chat),
            ),
          ],
        ),
      ),
    );
  }
}
