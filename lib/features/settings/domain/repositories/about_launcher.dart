/// Leaves the app for Settings' About rows.
abstract interface class AboutLauncher {
  /// Opens [url] in Safari's in-app view; false when it could not.
  Future<bool> openInApp(Uri url);

  /// Opens Mail with [mailto]; false when nothing can send mail.
  Future<bool> composeMail(Uri mailto);

  /// The App Store's write-a-review page for [appStoreId].
  Future<void> writeReview(String appStoreId);
}
