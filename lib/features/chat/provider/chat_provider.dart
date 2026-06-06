import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/models/messages.dart';
import '../../../core/models/mood.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/command_executor.dart';
import '../../../core/services/theme_service.dart';

class ChatProvider extends ChangeNotifier {
  final GeminiService _service;
  final HistoryService _historyService = HistoryService();
  final CommandExecutor _executor = CommandExecutor();
  final ThemeService _themeService;
  final Uuid _uuid = const Uuid();

  List<Message> messages = [];
  List<ChatSession> sessions = [];
  String? currentSessionId;
  bool isLoading = false;
  
  String get activeModel => _service.activeModel;
  List<String> get availableModels => _service.availableModels;
  ThemeService get themeService => _themeService;

  ChatProvider(this._service, this._themeService) {
    _loadHistory();
  }

  void setManualModel(String? modelId) {
    _service.setManualModel(modelId);
    notifyListeners();
  }

  Future<void> refreshModels() async {
    await _service.fetchAvailableModels();
    notifyListeners();
  }
  
  String? pickedFilePath;
  Uint8List? capturedImageBytes;
  
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );

    if (result != null) {
      pickedFilePath = result.files.single.path;
      capturedImageBytes = null; 
      notifyListeners();
    }
  }

  Future<Uint8List?> _captureWithPowerShell() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = "${tempDir.path}\\screenshot.jpg";

      final psScript = """
      Add-Type -AssemblyName System.Windows.Forms
      Add-Type -AssemblyName System.Drawing
      \$Screen = [System.Windows.Forms.Screen]::PrimaryScreen
      \$Width  = \$Screen.Bounds.Width
      \$Height = \$Screen.Bounds.Height
      \$Left   = \$Screen.Bounds.Left
      \$Top    = \$Screen.Bounds.Top
      \$Bitmap = New-Object System.Drawing.Bitmap \$Width, \$Height
      \$Graphics = [System.Drawing.Graphics]::FromImage(\$Bitmap)
      \$Graphics.CopyFromScreen(\$Left, \$Top, 0, 0, \$Bitmap.Size)
      
      \$Encoder = [System.Drawing.Imaging.Encoder]::Quality
      \$EncoderParameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
      \$EncoderParameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(\$Encoder, 70)
      \$ImageCodecInfo = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { \$_.MimeType -eq 'image/jpeg' }
      
      \$Bitmap.Save('$path', \$ImageCodecInfo, \$EncoderParameters)
      
      \$Graphics.Dispose()
      \$Bitmap.Dispose()
      """;

      final process = await Process.run('powershell', ['-Command', psScript]);
      if (process.exitCode == 0) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await file.delete(); 
          return bytes;
        }
      }
    } catch (e) {
      debugPrint("PowerShell capture failed: $e");
    }
    return null;
  }

  Future<void> captureScreen() async {
    try {
      await windowManager.hide();
      await Future.delayed(const Duration(milliseconds: 600));
      final Uint8List? imageBytes = await _captureWithPowerShell();
      await windowManager.show();
      await windowManager.focus();

      if (imageBytes != null) {
        capturedImageBytes = imageBytes;
        pickedFilePath = null;
        notifyListeners();
        sendToAI(customPrompt: "", customImage: imageBytes);
      }
    } catch (e) {
      debugPrint("Screen capture failed: $e");
      await windowManager.show();
    }
  }
  void clearMedia() {
    pickedFilePath = null;
    capturedImageBytes = null;
    notifyListeners();
  }

  void clearPickedFile() => clearMedia();

  Future<void> _loadHistory() async {
    sessions = await _historyService.loadAllSessions();
    notifyListeners();
  }

  void selectSession(ChatSession session) {
    messages = List.from(session.messages);
    currentSessionId = session.id;
    notifyListeners();
  }

  void startNewChat() {
    messages.clear();
    clearMedia();
    currentSessionId = _uuid.v4();
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _historyService.deleteSession(id);
    sessions.removeWhere((s) => s.id == id);
    if (currentSessionId == id) startNewChat();
    notifyListeners();
  }

  void addUserMessage(String text, {String? filePath, Uint8List? imageBytes}) {
    messages.add(
      Message(
        role: "user",
        content: text,
        filePath: filePath,
        imageBytes: imageBytes,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> sendToAI({String? customPrompt, Uint8List? customImage}) async {
    if (isLoading && customPrompt == null) return; 
    
    if (DateTime.now().difference(_lastRequestTime).inSeconds < 1 && customPrompt == null) return;
    _lastRequestTime = DateTime.now();

    isLoading = true;
    notifyListeners();

    if (customPrompt != null) {
       addUserMessage(customPrompt, imageBytes: customImage);
    }

    final List<Message> historyToSend = List.from(messages);
    messages.add(Message(role: "assistant", content: "", timestamp: DateTime.now()));
    notifyListeners();

    try {
      final String assistantResponse = await _service.sendMessage(historyToSend);
      messages[messages.length - 1] = Message(role: "assistant", content: assistantResponse, timestamp: DateTime.now());
      notifyListeners();
      await _executor.execute(assistantResponse, onCaptureRequest: () => captureScreen());
      if (currentSessionId == null) currentSessionId = _uuid.v4();
      final String firstMessage = messages.first.content;
      final session = ChatSession(id: currentSessionId!, title: firstMessage.length > 20 ? firstMessage.substring(0, 20) : firstMessage, messages: List.from(messages));
      await _historyService.saveSession(session);
      _loadHistory();
    } catch (e) {
      debugPrint("Ineffa encountered an error: $e");
      messages[messages.length - 1] = Message(role: "assistant", content: "Arnab, my networks are congested. (Error: $e)", timestamp: DateTime.now());
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    messages.clear();
    clearMedia();
    notifyListeners();
  }
}
