/// Thrown when an Android OEM restricts [NetworkStatsManager] access even
/// after the user has granted PACKAGE_USAGE_STATS permission.
/// Common on MIUI, EMUI (HarmonyOS), and ColorOS.
class NetworkStatsRestrictedException implements Exception {
  const NetworkStatsRestrictedException([this.message]);
  final String? message;

  @override
  String toString() =>
      'NetworkStatsRestrictedException: ${message ?? "Per-app data unavailable on this device."}';
}
