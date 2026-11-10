import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaldi_app/common/coffee3d/coffee_3d.dart';
import 'package:kaldi_app/common/effects/motion.dart';
import 'package:kaldi_app/localization/language/languages.dart';
import 'package:kaldi_app/utils/app_updater.dart';

/// Shown instead of the game when a newer version is on Google Play and the
/// update was declined or could not run. The only ways out are updating or
/// closing the app, so nobody keeps playing an outdated (broken) version.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Languages lang = Languages.of(context)!;
    return PopScope(
      // Back closes the app instead of skipping the update.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: BackgroundTheme.of(context).base,
        body: CoffeeBackdrop(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PopIn(
                  child: Coffee3DPanel(
                    title: lang.txtUpdateTitle,
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Float(child: Icon3D('ui_goat', size: 110)),
                        const SizedBox(height: 14),
                        Text(
                          lang.txtUpdateMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: CoffeePalette.roast,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Pulse(
                          amount: 0.04,
                          child: Coffee3DButton(
                            semanticLabel: lang.txtUpdateNow,
                            color: CoffeePalette.leaf,
                            height: 62,
                            depth: 7,
                            borderRadius: BorderRadius.circular(31),
                            onTap: AppUpdater.updateNow,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.system_update_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: OutlinedGameText(
                                      lang.txtUpdateNow,
                                      fontSize: 24,
                                      strokeWidth: 5,
                                      stroke: shade(CoffeePalette.leaf, 0.3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
