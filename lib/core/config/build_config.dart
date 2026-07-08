/// Compile-time build configuration.
///
/// Toggles internal/QA-only tooling that must not ship to beta testers or
/// production. Enabled by passing `--dart-define=INTERNAL_TOOLS=true` at build
/// time; defaults to false, so a plain `flutter build` produces a clean beta
/// build with the internal tools tree-shaken out of the binary entirely.
class BuildConfig {
  const BuildConfig._();

  /// Whether internal-only tools (e.g. the "Send a test notification" button)
  /// are compiled in.
  static const bool internalTools =
      bool.fromEnvironment('INTERNAL_TOOLS', defaultValue: false);
}
