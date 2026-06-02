import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'pages/observation_logs_page.dart';
import 'services/qliphoth_scheduler.dart';

void main() {
  runApp(const ProviderScope(child: LCorpApp()));
}

class LCorpApp extends ConsumerStatefulWidget {
  const LCorpApp({super.key});

  @override
  ConsumerState<LCorpApp> createState() => _LCorpAppState();
}

class _LCorpAppState extends ConsumerState<LCorpApp> {
  @override
  void initState() {
    super.initState();
    // 启动逆卡巴拉计数器衰减调度器（含离线追赶）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qliphothSchedulerProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Moon Life Record',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const ObservationLogsPage(),
    );
  }
}
