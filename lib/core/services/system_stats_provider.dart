import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:process_run/shell.dart';
import 'package:battery_plus/battery_plus.dart';

class SystemStatsProvider extends ChangeNotifier {
  final Battery _battery = Battery();
  final Shell _shell = Shell(throwOnError: false);
  
  double _cpuUsage = 0.0;
  double _ramUsedGB = 0.0;
  double _ramTotalGB = 0.0;
  double _ramPercent = 0.0;
  int _batteryLevel = 100;
  Timer? _timer;

  double get cpuUsage => _cpuUsage;
  double get ramUsage => _ramUsedGB;
  double get ramTotal => _ramTotalGB;
  double get ramPercent => _ramPercent;
  int get batteryLevel => _batteryLevel;

  SystemStatsProvider() {
    _startUpdates();
  }

  void _startUpdates() {
    // Initial fetch
    _updateStats();
    // Update every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateStats();
    });
  }

  // Helper to extract digits from messy system output
  double _parseValue(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(digitsOnly) ?? 0.0;
  }

  Future<void> _updateStats() async {
    // 1. Fetch CPU Usage (WMIC is very direct)
    try {
      final res = await _shell.run('wmic cpu get loadpercentage');
      if (res.isNotEmpty) {
        final out = res.first.stdout.toString();
        final val = _parseValue(out);
        _cpuUsage = val / 100.0;
      }
    } catch (e) {
      debugPrint("CPU Fetch Error: $e");
    }

    // 2. Fetch RAM Info
    try {
      final resTotal = await _shell.run('wmic OS get TotalVisibleMemorySize');
      final resFree = await _shell.run('wmic OS get FreePhysicalMemory');
      
      if (resTotal.isNotEmpty && resFree.isNotEmpty) {
        final totalKB = _parseValue(resTotal.first.stdout.toString());
        final freeKB = _parseValue(resFree.first.stdout.toString());
        
        if (totalKB > 0) {
          final usedKB = totalKB - freeKB;
          _ramTotalGB = totalKB / (1024 * 1024);
          _ramUsedGB = usedKB / (1024 * 1024);
          _ramPercent = usedKB / totalKB;
        }
      }
    } catch (e) {
      debugPrint("RAM Fetch Error: $e");
    }

    // 3. Fetch Battery
    try {
      _batteryLevel = await _battery.batteryLevel;
    } catch (e) {
      _batteryLevel = 100; 
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
