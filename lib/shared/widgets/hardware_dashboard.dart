import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/system_stats_provider.dart';
import 'glass_container.dart';

class HardwareDashboard extends StatelessWidget {
  const HardwareDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<SystemStatsProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(12),
        opacity: 0.1,
        blur: 10,
        color: AppTheme.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monitor_heart_rounded, size: 16, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  "SYSTEM STATUS",
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              "CPU LOAD",
              "${(stats.cpuUsage * 100).toStringAsFixed(1)}%",
              stats.cpuUsage,
              Icons.memory_rounded,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              "RAM USED",
              _formatRam(stats.ramUsage, stats.ramTotal),
              stats.ramPercent,
              Icons.speed_rounded,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              "BATTERY",
              "${stats.batteryLevel}%",
              stats.batteryLevel / 100,
              Icons.battery_charging_full_rounded,
            ),
          ],
        ),
      ),
    );
  }

  String _formatRam(double usedGB, double totalGB) {
    if (usedGB < 1.0) {
      final mb = (usedGB * 1024).toStringAsFixed(0);
      return "$mb MB / ${totalGB.toStringAsFixed(0)} GB";
    }
    return "${usedGB.toStringAsFixed(1)} / ${totalGB.toStringAsFixed(0)} GB";
  }

  Widget _buildStatItem(String label, String value, double percent, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
              ],
            ),
            Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 2,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              percent > 0.8 ? AppTheme.error : AppTheme.primary.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }
}
