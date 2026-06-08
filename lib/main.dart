import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'pages/observation_logs_page.dart';

void main() {
  runApp(const ProviderScope(child: LCorpApp()));
}

class LCorpApp extends StatelessWidget {
  const LCorpApp({super.key});

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
