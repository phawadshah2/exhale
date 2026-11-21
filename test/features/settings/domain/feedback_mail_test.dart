import 'package:exhale/features/settings/domain/entities/app_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uri mail() => feedbackMailUri(
    to: 'hello@example.com',
    appVersion: '0.1.0',
    iosVersion: '26.1',
  );

  test('address is the to', () {
    expect(mail().scheme, 'mailto');
    expect(mail().path, 'hello@example.com');
  });

  test('subject is Exhale feedback', () {
    expect(mail().queryParameters['subject'], 'Exhale feedback');
  });

  test('body ends with app and iOS versions', () {
    expect(
      mail().queryParameters['body'],
      endsWith('\n\n—\nExhale 0.1.0, iOS 26.1'),
    );
  });
}
