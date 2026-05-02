import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SystemInfoWidget extends StatelessWidget {
  const SystemInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: Colors.black12,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SYSTEM STATUS",
            style: TextStyle(color: AppTheme.neutral, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.memory, size: 12, color: AppTheme.secondary),
              SizedBox(width: 4),
              Text("Inference Engine: Active", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
