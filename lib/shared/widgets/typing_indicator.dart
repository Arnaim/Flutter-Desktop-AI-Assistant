import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.sidebarBackground,
            radius: 16,
            foregroundImage: AssetImage('assets/ineffa_pfp.jpg'),
            child: Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.sidebarBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.white10, width: 1),
            ),
            child: Row(
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (context, value, child) => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
