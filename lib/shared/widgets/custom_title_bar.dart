import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../../core/theme/app_theme.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Container(
        height: 40,
        color: AppTheme.sidebarBackground,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppTheme.secondary),
            const SizedBox(width: 8),
            const Text(
              "GENIUS ASSISTANT",
              style: TextStyle(
                color: AppTheme.tertiary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            WindowCaptionButton.minimize(onPressed: () => windowManager.minimize()),
            WindowCaptionButton.maximize(onPressed: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            }),
            WindowCaptionButton.close(onPressed: () => windowManager.close()),
          ],
        ),
      ),
    );
  }
}
