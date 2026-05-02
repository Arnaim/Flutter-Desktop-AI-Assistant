import 'package:flutter/material.dart';
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
    inputFocusNode.dispose();
    super.dispose();
  }

  void sendMessage(ChatProvider chat) {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    controller.clear();
    chat.addUserMessage(text);
    chat.sendToAI();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

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
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          itemCount: chat.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chat.messages[index];
                            return ChatBubble(message: msg);
                          },
                        ),
                      ),
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
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: inputFocusNode,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: "Ask something worthy of a genius...",
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
