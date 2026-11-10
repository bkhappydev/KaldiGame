import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/coffee3d/coffee_dialogs.dart';
import 'package:kaldi_app/common/effects/bouncy_button.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/rewards/reward_store.dart';
import 'package:kaldi_app/ui/level/level_screen.dart';
import 'package:kaldi_app/ui/progress/progress_screen.dart';
import 'package:kaldi_app/ui/settings/settings_screen.dart';
import 'package:kaldi_app/ui/treats/treats_screen.dart';
import 'package:kaldi_app/utils/game_audio.dart';

/// The app's home: four tabs (Play, Treats, My Level, Settings) under a 3D
/// coffee bottom bar. Quizzes open full screen on top of it.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _exitDialogOpen = false;

  static const List<Widget> _tabs = [
    LevelScreen(),
    TreatsScreen(),
    ProgressScreen(),
    SettingsScreen(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    RewardStore.instance.load();
  }

  Future<void> _onBack() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    if (_exitDialogOpen) return;
    _exitDialogOpen = true;
    final bool? exit = await showCoffeeConfirm(
      context,
      message: Languages.of(context)!.txtAreYouSureYouWantToExit,
      image: 'ui_goat',
    );
    _exitDialogOpen = false;
    if (exit == true) {
      await GameAudio.pauseMusic();
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: BackgroundTheme.of(context).base,
        extendBody: true,
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: _CoffeeBottomBar(
          index: _index,
          onSelect: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

/// Floating espresso bar: 3D pictures sit right on it, and a caramel pill
/// slides behind the selected tab.
class _CoffeeBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _CoffeeBottomBar({required this.index, required this.onSelect});

  static const double barHeight = 74;

  @override
  Widget build(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final items = [
      ('nav_play', lang.txtPlay),
      ('nav_treats', lang.txtTreats),
      ('nav_level', lang.txtProgress),
      ('nav_settings', lang.txtSettings),
    ];

    // Attached to the bottom edge: only the top corners are (gently) rounded.
    return Container(
      height: barHeight + bottomInset,
      padding: EdgeInsets.fromLTRB(8, 6, 8, 6 + bottomInset),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CoffeePalette.mocha, CoffeePalette.roast],
        ),
        border: Border(
          top: BorderSide(
            color: CoffeePalette.caramel.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _NavItem(
                image: items[i].$1,
                label: items[i].$2,
                selected: i == index,
                badge: i == 1,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  /// Icon3D name of the tab's 3D picture.
  final String image;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.image,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget picture = AnimatedScale(
      scale: selected ? 1.12 : 0.9,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: Opacity(
        opacity: selected ? 1 : 0.8,
        child: Icon3D(image, size: 32),
      ),
    );

    if (badge) {
      picture = ListenableBuilder(
        listenable: RewardStore.instance,
        builder: (context, child) {
          final int pending = RewardStore.instance.pendingGifts;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              if (pending > 0)
                Positioned(
                  right: -10,
                  top: -6,
                  child: Pulse(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: CoffeePalette.cherry,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$pending',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: kGameFont,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        child: picture,
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: BouncyButton(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          // Active tab: a clean white pill with a soft shadow.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? Colors.white : Colors.transparent,
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              picture,
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? CoffeePalette.roast : CoffeePalette.latte,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
