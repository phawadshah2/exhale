/// Every address the app links to, for Settings and the paywall alike. A
/// null link or address hides its row; set them before release (spec Open).
abstract final class AppLinks {
  /// Apple's standard EULA.
  static const terms =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String? privacy = null;
  static const String? feedbackEmail = null;

  /// The App Store ID, for Rate's write-a-review page.
  static const String? appStoreId = null;

  static const about = AboutLinks(
    privacyPolicy: privacy,
    terms: terms,
    feedbackEmail: feedbackEmail,
    appStoreId: appStoreId,
  );
}

/// The About section's links, read through `aboutLinksProvider` so tests can
/// supply their own.
class AboutLinks {
  const AboutLinks({
    required this.privacyPolicy,
    required this.terms,
    required this.feedbackEmail,
    required this.appStoreId,
  });

  final String? privacyPolicy;
  final String? terms;
  final String? feedbackEmail;
  final String? appStoreId;
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
