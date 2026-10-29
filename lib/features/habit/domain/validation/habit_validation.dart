abstract final class HabitValidation {
  static const int maxReasonLength = 80;
  static const int maxUnitsPerContainer = 100;
  static const int maxPriceCents = 100000;

  static String? validate({
    required int? priceCents,
    required int unitsPerContainer,
  }) {
    if (unitsPerContainer < 1 || unitsPerContainer > maxUnitsPerContainer) {
      return 'Units per container must be between 1 and '
          '$maxUnitsPerContainer.';
    }
    if (priceCents != null && (priceCents < 0 || priceCents > maxPriceCents)) {
      return 'Price is out of range.';
    }
    return null;
  }

  static String? normalizeReason(String? reason) {
    final trimmed = reason?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
