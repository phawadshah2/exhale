import 'package:exhale/features/settings/domain/entities/currency_choices.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a known region gets its own currency', () {
    expect(CurrencyChoices.forRegion('AE'), 'AED');
    expect(CurrencyChoices.forRegion('SA'), 'SAR');
    expect(CurrencyChoices.forRegion('GB'), '£');
    expect(CurrencyChoices.forRegion('PK'), 'Rs');
    expect(CurrencyChoices.forRegion('IN'), '₹');
    expect(CurrencyChoices.forRegion('US'), r'$');
  });

  test('region match ignores case', () {
    expect(CurrencyChoices.forRegion('de'), '€');
    expect(CurrencyChoices.forRegion('ae'), 'AED');
  });

  test(r'a missing or unknown region falls back to $', () {
    expect(CurrencyChoices.forRegion(null), r'$');
    expect(CurrencyChoices.forRegion(''), r'$');
    expect(CurrencyChoices.forRegion('ZZ'), r'$');
  });

  test(r'$ is first and the list has about 25 entries', () {
    expect(CurrencyChoices.all.first.symbol, r'$');
    expect(CurrencyChoices.all.length, inInclusiveRange(20, 30));
  });

  test('every euro-area country maps to €', () {
    const euroArea = {
      'AT', 'BE', 'HR', 'CY', 'EE', 'FI', 'FR', 'DE', 'GR', 'IE', //
      'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PT', 'SK', 'SI', 'ES',
    };
    for (final region in euroArea) {
      expect(CurrencyChoices.forRegion(region), '€', reason: region);
    }
  });

  test('symbols are unique', () {
    final symbols = CurrencyChoices.all.map((c) => c.symbol).toList();
    expect(symbols.toSet().length, symbols.length);
  });

  test('no region appears twice', () {
    final regions = [for (final c in CurrencyChoices.all) ...c.regions];
    expect(regions.toSet().length, regions.length);
  });

  test('regions are stored upper case', () {
    for (final choice in CurrencyChoices.all) {
      for (final region in choice.regions) {
        expect(region, region.toUpperCase(), reason: choice.symbol);
      }
    }
  });
}
