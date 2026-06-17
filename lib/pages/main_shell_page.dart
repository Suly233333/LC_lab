import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/abnormality.dart';
import '../state/app_providers.dart';
import '../widgets/extraction_ceremony_widget.dart';
import 'abnormality_gallery_page.dart';
import 'communication_list_page.dart';
import 'observation_logs_page.dart';
import 'settings_page.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  int _index = 0;
  bool _showingCeremony = false;

  static const List<String> _titles = <String>[
    'OBSERVATION / LOGS',
    'ABNORMALITY / GALLERY',
    'COMMUNICATION / COMMS',
    'SYSTEM / CONTROL',
  ];

  static const List<Widget> _pages = <Widget>[
    ObservationLogsPage(showAppBar: false),
    AbnormalityGalleryPage(showAppBar: false),
    CommunicationListPage(),
    SettingsPage(),
  ];

  Future<void> _maybeRunCeremony() async {
    if (_showingCeremony) return;
    final List<Abnormality> queue = ref.read(pendingUnlocksProvider);
    if (queue.isEmpty) return;

    _showingCeremony = true;
    try {
      for (final Abnormality a in queue) {
        if (!mounted) break;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(24),
            child: ExtractionCeremonyWidget(abnormality: a),
          ),
        );
      }
      ref.read(pendingUnlocksProvider.notifier).clear();
    } finally {
      _showingCeremony = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Abnormality>>(pendingUnlocksProvider, (prev, next) {
      if (next.isNotEmpty) _maybeRunCeremony();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.primary, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.hint,
          selectedLabelStyle: const TextStyle(
            fontFamily: AppTheme.monoFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: AppTheme.monoFontFamily,
            fontSize: 10,
          ),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'LOGS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_special_outlined),
              activeIcon: Icon(Icons.folder_special),
              label: 'GALLERY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: 'COMMS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'SYSTEM',
            ),
          ],
        ),
      ),
    );
  }
}
