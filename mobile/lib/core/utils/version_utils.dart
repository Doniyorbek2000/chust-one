/// Compares two dotted version strings (e.g. "1.2.0" vs "1.10.3") numerically
/// per segment, unlike a plain string comparison which would sort "1.10" before
/// "1.2". Returns < 0 if [current] is older than [minimum], 0 if equal, > 0 if newer.
int compareVersions(String current, String minimum) {
  final currentParts = current.trim().split('.');
  final minimumParts = minimum.trim().split('.');
  final length = currentParts.length > minimumParts.length ? currentParts.length : minimumParts.length;

  for (var i = 0; i < length; i++) {
    final currentSegment = i < currentParts.length ? int.tryParse(currentParts[i]) ?? 0 : 0;
    final minimumSegment = i < minimumParts.length ? int.tryParse(minimumParts[i]) ?? 0 : 0;
    if (currentSegment != minimumSegment) return currentSegment - minimumSegment;
  }
  return 0;
}

/// True when the installed app [currentVersion] is older than [minimumVersion].
bool isAppVersionOutdated(String currentVersion, String minimumVersion) {
  return compareVersions(currentVersion, minimumVersion) < 0;
}
