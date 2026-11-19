/// Addresses Settings' About section links to. A null link or address hides
/// its row; a null [appStoreId] only drops Rate's fallback.
abstract final class AppLinks {
  /// Privacy policy, terms and the feedback address, filled when Fawad gives
  /// them (spec Open).
  static const about = AboutLinks();
  static const String? appStoreId = null;
}

/// The About section's links, read through `aboutLinksProvider` so tests can
/// supply their own.
class AboutLinks {
  const AboutLinks({this.privacyPolicy, this.terms, this.feedbackEmail});

  final Uri? privacyPolicy;
  final Uri? terms;
  final String? feedbackEmail;
}

/// A `mailto:` for Send feedback, signed with the app and iOS versions.
Uri feedbackMailUri({
  required String to,
  required String appVersion,
  required String iosVersion,
}) => Uri(
  scheme: 'mailto',
  path: to,
  query: _encode({
    'subject': 'Exhale feedback',
    'body': '\n\n—\nExhale $appVersion, iOS $iosVersion',
  }),
);

// Mail apps read `+` literally, so spaces must be `%20`, not
// `queryParameters`' `+`.
String _encode(Map<String, String> params) => params.entries
    .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
    .join('&');
