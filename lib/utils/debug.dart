import 'dart:developer';

import 'package:flutter/foundation.dart';

class Debug {
  /// Logs only in debug builds; release builds stay silent.
  static const debug = kDebugMode;

  static printLog(String str) {
    if (debug) log(str);
  }
}