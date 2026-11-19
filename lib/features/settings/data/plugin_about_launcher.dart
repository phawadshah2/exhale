import 'package:exhale/features/settings/domain/entities/app_links.dart';
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
  Future<void> requestReview() async {
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
      } else if (AppLinks.appStoreId case final id?) {
        await _review.openStoreListing(appStoreId: id);
      }
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
