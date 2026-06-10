import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ineffa_assistant_bot/shared/widgets/chat_bubble.dart';
import 'package:ineffa_assistant_bot/shared/widgets/glass_container.dart';
import 'package:ineffa_assistant_bot/shared/widgets/sidebar_widget.dart';
import 'package:ineffa_assistant_bot/shared/widgets/typing_indicator.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../provider/chat_provider.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_title_bar.dart';
import 'camera_capture_screen.dart';
import 'package:camera/camera.dart';

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
    
    // Initialize voice
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoiceService>().initSpeech();
    });
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

  void sendMessage(ChatProvider chat, {String? overrideText}) {
    final text = overrideText ?? controller.text.trim();
    if (text.isEmpty && chat.pickedFilePath == null && chat.capturedImageBytes == null) return;
    
    final String? filePath = chat.pickedFilePath;
    final Uint8List? imageBytes = chat.capturedImageBytes;
    
    chat.clearMedia(); // Clear preview immediately
    controller.clear();
    
    chat.addUserMessage(
      text.isEmpty ? "Analyze this visual context." : text, 
      filePath: filePath,
      imageBytes: imageBytes,
    );
    chat.sendToAI();
  }

  void _toggleVoice(ChatProvider chat, VoiceService voice) async {
    if (voice.isListening) {
      await voice.stopListening();
    } else {
      await voice.startListening(
        onResult: (text) {
          if (text.isNotEmpty) {
            sendMessage(chat, overrideText: text);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final voice = context.watch<VoiceService>();
    final theme = Theme.of(context);
    final isDesktop = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.windows || 
         defaultTargetPlatform == TargetPlatform.macOS || 
         defaultTargetPlatform == TargetPlatform.linux);

    // Update controller if listening
    if (voice.isListening && voice.lastWords.isNotEmpty) {
      controller.text = voice.lastWords;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
    }

    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: !isDesktop ? const Drawer(child: SidebarWidget()) : null,
      body: Stack(
        children: [
          // 1. Background Layer (Enhanced for Liquid Glass Visibility)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.scaffoldBackgroundColor,
                  theme.colorScheme.surface,
                ],
              ),
            ),
          ),
          
          // Decorative background elements
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: isDesktop ? 500 : 300,
              height: isDesktop ? 500 : 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.surface.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. UI Layer
          LayoutBuilder(
            builder: (context, constraints) {
              final showSidebar = constraints.maxWidth > 800 && isDesktop;
              
              return Column(
                children: [
                  CustomTitleBar(showDrawerTrigger: !showSidebar),
                  Expanded(
                    child: Row(
                      children: [
                        if (showSidebar) const SidebarWidget(),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  controller: scrollController,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 20, 
                                    horizontal: isDesktop ? 24 : 16
                                  ),
                                  itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (chat.isLoading && index == chat.messages.length) {
                                      return const TypingIndicator();
                                    }
                                    final msg = chat.messages[index];
                                    return ChatBubble(message: msg);
                                  },
                                ),
                              ),
                              if (chat.pickedFilePath != null || chat.capturedImageBytes != null) 
                                _buildFilePreview(chat, isDesktop),
                              _buildInputArea(chat, voice, isDesktop),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(ChatProvider chat, bool isDesktop) {
    String label = chat.pickedFilePath != null 
        ? p.basename(chat.pickedFilePath!) 
        : "Screen Capture Active";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: Colors.white,
        opacity: 0.05,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chat.capturedImageBytes != null ? Icons.visibility_rounded : Icons.attach_file, 
              size: 16, 
              color: AppTheme.primary
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: chat.clearMedia,
              child: const Icon(Icons.close, size: 16, color: AppTheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatProvider chat, VoiceService voice, bool isDesktop) {
    return Container(
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 12, 0, isDesktop ? 24 : 12, isDesktop ? 24 : 12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: Theme.of(context).colorScheme.primary,
        opacity: 0.08,
        blur: 15,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        child: Row(
          children: [
            if (isDesktop) ...[
              IconButton(
                icon: const Icon(Icons.attach_file_rounded, color: AppTheme.secondary),
                tooltip: "Attach File",
                onPressed: chat.pickFile,
              ),
              IconButton(
                icon: const Icon(Icons.visibility_rounded, color: AppTheme.secondary),
                tooltip: "Visual Scan",
                onPressed: chat.captureScreen,
              ),
            ] else 
              IconButton(
                icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.secondary),
                tooltip: "Camera Vision",
                onPressed: () async {
                  final XFile? image = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
                  );
                  
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    chat.sendToAI(customPrompt: "Analyze this image.", customImage: bytes);
                  }
                },
              ),
            
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  if (voice.isListening)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 32 + (voice.soundLevel * 2),
                      height: 32 + (voice.soundLevel * 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.error.withOpacity(0.1 + (voice.soundLevel / 10).clamp(0.0, 0.4)),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  Icon(
                    voice.isListening ? Icons.mic_rounded : Icons.mic_none_rounded, 
                    color: voice.isListening ? AppTheme.error : AppTheme.secondary,
                  ),
                ],
              ),
              tooltip: "Voice Command",
              onPressed: () => _toggleVoice(chat, voice),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: inputFocusNode,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: voice.isListening ? "Listening..." : "Message Ineffa...",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
