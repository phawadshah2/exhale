enum LimitStatus {
  /// Room left today (also a smoke-free day on a zero limit).
  under,

  /// Exactly at the limit; logging is still allowed.
  at,

  /// Past the limit.
  over;

  static LimitStatus of({required int count, required int limit}) {
    if (count > limit) return LimitStatus.over;
    if (count == limit && limit > 0) return LimitStatus.at;
    return LimitStatus.under;
  }
}
