class CurrencyChoice {
  const CurrencyChoice(this.symbol, this.regions);

  /// Display string stored in `AppSettings.currencySymbol`.
  final String symbol;

  /// Upper-case ISO 3166 region codes that default to [symbol].
  final Set<String> regions;
}

/// Currencies offered in onboarding and Settings. The first entry is the
/// fallback for an unknown region.
abstract final class CurrencyChoices {
  static const List<CurrencyChoice> all = [
    CurrencyChoice(r'$', {'US', 'PR', 'EC', 'SV', 'PA'}),
    CurrencyChoice('€', {
      'AT', 'BE', 'HR', 'CY', 'EE', 'FI', 'FR', 'DE', 'GR', 'IE', 'IT', //
      'LV', 'LT', 'LU', 'MT', 'NL', 'PT', 'SK', 'SI', 'ES', 'AD', 'MC', //
      'SM', 'VA', 'ME', 'XK',
    }),
    CurrencyChoice('£', {'GB', 'IM', 'JE', 'GG'}),
    CurrencyChoice('AED', {'AE'}),
    CurrencyChoice('SAR', {'SA'}),
    CurrencyChoice('QAR', {'QA'}),
    CurrencyChoice('KWD', {'KW'}),
    CurrencyChoice('BHD', {'BH'}),
    CurrencyChoice('OMR', {'OM'}),
    CurrencyChoice('EGP', {'EG'}),
    CurrencyChoice('Rs', {'PK'}),
    CurrencyChoice('₹', {'IN'}),
    CurrencyChoice('৳', {'BD'}),
    CurrencyChoice(r'C$', {'CA'}),
    CurrencyChoice(r'A$', {'AU'}),
    CurrencyChoice(r'NZ$', {'NZ'}),
    CurrencyChoice(r'S$', {'SG'}),
    CurrencyChoice('RM', {'MY'}),
    CurrencyChoice('Rp', {'ID'}),
    CurrencyChoice('₱', {'PH'}),
    CurrencyChoice('¥', {'JP'}),
    CurrencyChoice('₩', {'KR'}),
    CurrencyChoice('CHF', {'CH', 'LI'}),
    CurrencyChoice('kr', {'SE', 'NO', 'DK', 'IS'}),
    CurrencyChoice('₺', {'TR'}),
    CurrencyChoice('R', {'ZA'}),
    CurrencyChoice(r'R$', {'BR'}),
    CurrencyChoice(r'MX$', {'MX'}),
  ];

  static final Map<String, String> _byRegion = {
    for (final choice in all)
      for (final region in choice.regions) region: choice.symbol,
  };

  static String forRegion(String? region) =>
      _byRegion[region?.toUpperCase()] ?? all.first.symbol;
}
