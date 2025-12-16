import 'package:flutter_test/flutter_test.dart';
import 'package:tax/utils/csv_utils.dart';

void main() {
  test('extractLinksFromCsv extracts single-column links', () {
    final input = 'https://example.com/pay\nhttps://phish.example/attack';
    final res = extractLinksFromCsv(input);
    expect(res.length, 2);
    expect(res[0], 'https://example.com/pay');
  });

  test('parseCsvLinks picks URL from comma-separated fields', () {
    final input = 'name,url,amount\nAlice,https://example.com/pay,100\nBob,https://example.org/pay,200';
    final res = parseCsvLinks(input);
    expect(res.length, 2);
    expect(res[0], 'https://example.com/pay');
  });

  test('extractLinksFromCsv handles headers and column name', () {
    final input = 'id,link,amount\n1,https://foo/pay,10\n2,https://bar/pay,20';
    final res = extractLinksFromCsv(input, columnName: 'link');
    expect(res, ['https://foo/pay', 'https://bar/pay']);
  });

  test('parseCsvLinks falls back to last field', () {
    final input = 'a,b,c\n1,2,https://x/z\n3,4,somehost/path';
    final res = parseCsvLinks(input);
    expect(res[0], 'https://x/z');
    expect(res[1], 'somehost/path');
  });
}
