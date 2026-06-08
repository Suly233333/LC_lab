import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/abnormality.dart';

/// 预设资源加载器。
///
/// - `assets/presets/abnormalities.json`：初始异想体档案
class PresetLoader {
  PresetLoader._();

  static const String abnormalityAssetPath =
      'assets/presets/abnormalities.json';

  /// 加载所有预设异想体。
  static Future<List<Abnormality>> loadAbnormalities() async {
    final String raw = await rootBundle.loadString(abnormalityAssetPath);
    final List<dynamic> list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => Abnormality.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// 工厂式：基于预设构造一个"开局态"的异想体列表：
  /// - `isInitial = true` 的异想体自动解锁，[unlockDate] = [now]。
  /// - 其余保持锁定状态，等待共鸣度累积自动解锁。
  static Future<List<Abnormality>> bootstrapAbnormalities({
    DateTime? now,
  }) async {
    final List<Abnormality> presets = await loadAbnormalities();
    final DateTime stamp = now ?? DateTime.now();
    for (final Abnormality a in presets) {
      if (a.isInitial) {
        a.isUnlocked = true;
        a.unlockDate = stamp;
      }
    }
    return presets;
  }
}
