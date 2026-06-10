import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/theme_service.dart';

class CustomTitleBar extends StatelessWidget {
  final bool showDrawerTrigger;
  const CustomTitleBar({super.key, this.showDrawerTrigger = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeService = context.watch<ThemeService>();
    final persona = context.watch<PersonaService>().currentPersona;
    final moodName = themeService.currentMood.name.toUpperCase();
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

    Widget content = Container(
      height: isWindows ? 40 : 60,
      color: isWindows ? theme.colorScheme.surface : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isWindows ? 0 : 8),
      child: Row(
        children: [
          if (showDrawerTrigger)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            "ASSISTANT ${persona.name.toUpperCase()}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "MOOD: $moodName",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          if (isWindows) ...[
            // Minimize - Light/Thin
            IconButton(
              onPressed: () => windowManager.minimize(),
              icon: Opacity(
                opacity: 0.5,
                child: const Icon(Icons.remove, size: 18, color: Colors.white),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              hoverColor: Colors.white10,
            ),
            // Maximize/Screen - Larger
            IconButton(
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              icon: const Icon(Icons.crop_square_rounded, size: 22, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              hoverColor: Colors.white10,
            ),
            // Close - Larger
            IconButton(
              onPressed: () => windowManager.close(),
              icon: const Icon(Icons.close_rounded, size: 24, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              hoverColor: Colors.redAccent.withOpacity(0.8),
            ),
          ],
        ],
      ),
    );

    return isWindows ? DragToMoveArea(child: content) : SafeArea(child: content);
  }
}
