import 'package:exhale/features/settings/domain/repositories/about_launcher.dart';

class FakeAboutLauncher implements AboutLauncher {
  final List<Uri> opened = [];
  final List<Uri> mails = [];
  final List<String> reviews = [];

  /// What [composeMail] returns.
  bool composeMailResult = true;

  @override
  Future<bool> openInApp(Uri url) async {
    opened.add(url);
    return true;
  }

  @override
  Future<bool> composeMail(Uri mailto) async {
    mails.add(mailto);
    return composeMailResult;
  }

  @override
  Future<void> writeReview(String appStoreId) async => reviews.add(appStoreId);
}
