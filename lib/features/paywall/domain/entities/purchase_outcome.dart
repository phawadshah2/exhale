/// How a purchase sheet ended, short of an error.
enum PurchaseOutcome {
  purchased,
  cancelled,

  /// Waiting on approval (Ask to Buy); a later store change brings access.
  pending,
}

/// How a restore ended.
enum RestoreOutcome {
  restored,
  nothingFound,

  /// The App Store could not be reached.
  failed,
}
