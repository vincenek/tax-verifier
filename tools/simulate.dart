import 'dart:io';
import 'package:tax/web3_utils.dart';

int aiRiskScore(String link, List<String> customRules) {
  final patterns = [
    'http://',
    'payee-',
    'secure-',
    'verify-',
    'login',
    'update',
    'phish',
    'scam',
    'fake',
    'suspicious',
    'invoice-now',
    'urgent',
    'wire-transfer',
  ] + customRules;
  int matches = 0;
  for (final p in patterns) {
    if (link.toLowerCase().contains(p)) {
      matches++;
    }
  }
  int score = (50 + matches * 10).clamp(0, 100);
  if (link.startsWith('http://')) score = (score + 20).clamp(0, 100);
  if (link.contains('bit.ly') || link.contains('tinyurl.com')) score = (score + 10).clamp(0, 100);
  return score;
}

bool isRiskyLink(String link, List<String> customRules) {
  final riskyPatterns = [
    'http://',
    'payee-',
    'secure-',
    'verify-',
    'login',
    'update',
    'phish',
    'scam',
    'fake',
    'suspicious',
    'paypal-',
    'venmo-',
    'giftcard',
    'bit.ly/',
    'tinyurl.com/',
    'invoice-now',
    'urgent',
    'wire-transfer',
    'bank-details',
    'account-change',
    'payment-redirect',
    '.ru/',
    '.cn/',
    '.tk/',
    '.ml/',
    '.ga/',
    '.cf/',
    '.gq/',
  ] + customRules;
  for (final pattern in riskyPatterns) {
    if (link.toLowerCase().contains(pattern)) {
      return true;
    }
  }
  if (link.startsWith('http://')) return true;
  if (link.length < 10) return true;
  if (link.contains(' ')) return true;
  final uncommonTlds = ['.ru', '.cn', '.tk', '.ml', '.ga', '.cf', '.gq'];
  for (final tld in uncommonTlds) {
    if (link.endsWith(tld)) return true;
  }
  return false;
}

String lookupVendor(String link) {
  final uri = Uri.tryParse(link);
  final domain = uri?.host ?? '';
  final trusted = ['paypal.com', 'stripe.com', 'squareup.com', 'wise.com', 'transferwise.com'];
  final flagged = ['scam-site.com', 'badvendor.example'];
  for (final t in trusted) {
    if (domain.contains(t)) {
      return 'Trusted Vendor';
    }
  }
  for (final f in flagged) {
    if (domain.contains(f)) {
      return 'Flagged Vendor';
    }
  }
  if (domain.endsWith('.com') && (domain.split('.').first.length > 3)) return 'Likely Legitimate';
  return 'Unknown Vendor';
}

void main() {
  final customRules = ['phish', 'scam', 'fake'];

  final samples = [
    'https://paypal.com/invoice/12345',
    'http://suspicious-site.ru/payme',
    'https://bit.ly/abc123',
    'https://example.com/payee-urgent',
    '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
    'https://etherscan.io/address/0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
  ];

  print('=== Simulation: single verifications ===');
  for (final s in samples) {
    final score = aiRiskScore(s, customRules);
    final risky = isRiskyLink(s, customRules);
    final vendor = lookupVendor(s);
    final eth = extractEthAddress(s);
    print('\nLink: $s');
    print('  Score: $score');
    print('  Risky: $risky');
    print('  Vendor: $vendor');
    print('  Eth detected: ${eth ?? 'no'}');
    if (eth != null) print('  Identicon: ${identiconUrl(eth)}');
  }

  print('\n=== Simulation: batch verification CSV output ===');
  final batch = samples;
  final rows = <List<String>>[];
  for (final link in batch) {
    final s = aiRiskScore(link, customRules);
    final v = lookupVendor(link);
    final r = isRiskyLink(link, customRules);
    final eth = extractEthAddress(link) ?? '';
    rows.add([DateTime.now().toIso8601String(), link, eth, r ? 'Risky' : 'Safe', s.toString(), v, '']);
  }
  final csv = rows.map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(',')).join('\n');
  final out = File('tools/simulated_audit.csv');
  out.writeAsStringSync(csv);
  print('Wrote tools/simulated_audit.csv (${rows.length} rows)');

  print('\n=== Done ===');
}
