/// The three things the App Store sells for Exhale, in paywall order.
enum PlanKind {
  annual('com.phawadshah.exhale.annual'),
  monthly('com.phawadshah.exhale.monthly'),
  lifetime('com.phawadshah.exhale.lifetime');

  PlanKind(this.productId);

  final String productId;

  /// The plan sold under [id], or null for a product that is not ours.
  static PlanKind? ofProductId(String id) {
    for (final plan in values) {
      if (plan.productId == id) return plan;
    }
    return null;
  }
}
