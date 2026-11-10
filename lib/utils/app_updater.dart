import 'dart:async';
import 'dart:io';

import 'package:in_app_update/in_app_update.dart';
import 'package:kaldi_app/utils/constant.dart';
import 'package:kaldi_app/utils/debug.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of the start-up update check.
enum UpdateCheck {
  /// Nothing to do (no update, update just installed, or the check could not
  /// run, e.g. the app was not installed from Google Play).
  upToDate,

  /// A newer version is on Google Play and was not installed: block play
  /// until the child (or parent) updates.
  mustUpdate,
}

/// Forces players onto the latest Google Play version, using Play's own
/// "immediate" in-app update: a full-screen Play screen that downloads and
/// installs the update, then restarts the app.
///
/// Only works for installs that came from Google Play (including testing
/// tracks and internal app sharing). Debug, emulator and sideloaded installs
/// always get [UpdateCheck.upToDate], so nobody is ever locked out by mistake.
class AppUpdater {
  AppUpdater._();

  /// Checks Google Play and, if a newer version exists, starts the immediate
  /// update flow. Returns [UpdateCheck.mustUpdate] only when an update exists
  /// and was not installed (declined, failed, or immediate mode not allowed).
  static Future<UpdateCheck> check() async {
    if (!Platform.isAndroid) return UpdateCheck.upToDate;
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate()
          .timeout(const Duration(seconds: 8));
      final bool pending =
          info.updateAvailability == UpdateAvailability.updateAvailable ||
              info.updateAvailability ==
                  UpdateAvailability.developerTriggeredUpdateInProgress;
      if (!pending) return UpdateCheck.upToDate;

      Debug.printLog(
        "Update available: version code ${info.availableVersionCode}",
      );
      if (info.immediateUpdateAllowed) {
        final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
        // On success Play installs the update and restarts the app.
        if (result == AppUpdateResult.success) return UpdateCheck.upToDate;
      }
      return UpdateCheck.mustUpdate;
    } catch (e) {
      // Not installed from Play, no Play Store, offline or timed out:
      // never block the game because of the check itself.
      Debug.printLog("Update check skipped: $e");
      return UpdateCheck.upToDate;
    }
  }

  /// Tries the in-app update again, falling back to the app's Play Store
  /// page if Play does not allow an immediate update.
  static Future<void> updateNow() async {
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate()
          .timeout(const Duration(seconds: 8));
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }
    } catch (_) {
      // Fall through to the store page.
    }
    await launchUrl(
      Uri.parse(Constant.shareLink),
      mode: LaunchMode.externalApplication,
    );
  }
}
