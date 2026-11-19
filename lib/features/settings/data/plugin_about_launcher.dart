import 'package:exhale/features/settings/domain/repositories/about_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

class PluginAboutLauncher implements AboutLauncher {
  PluginAboutLauncher({InAppReview? review})
    : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<bool> openInApp(Uri url) => _launch(url, LaunchMode.inAppBrowserView);

  @override
  Future<bool> composeMail(Uri mailto) =>
      _launch(mailto, LaunchMode.externalApplication);

  @override
  Future<void> writeReview(String appStoreId) async {
    try {
      await _review.openStoreListing(appStoreId: appStoreId);
    } on Exception {
      // Nothing to show; the row simply does nothing.
    }
  }

  static Future<bool> _launch(Uri url, LaunchMode mode) async {
    try {
      return await launchUrl(url, mode: mode);
    } on Exception {
      return false;
    }
  }
}
