class IdGenerator {
  static int _lastIssued = 0;

  static int next() {
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now <= _lastIssued) {
      _lastIssued++;
    } else {
      _lastIssued = now;
    }
    return _lastIssued;
  }
}
