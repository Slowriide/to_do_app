import 'dart:io';
import 'package:flutter/foundation.dart';

bool localFileExists(String path) {
  try {
    return File(path).existsSync();
  } catch (e, st) {
    debugPrint('utils/local-file-exists failed: $e\n$st');
    return false;
  }
}
