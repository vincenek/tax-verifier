import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'web3_utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8FA),
        canvasColor: Colors.white,
        // cardTheme removed for broader Flutter compatibility across CI runners
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFFEFF3F6),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A2540),
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF1A2A3A)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Color(0xFF0A2540)),
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A2540),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const PaymentLinkVerifier(),
    );
  }
}

class PaymentLinkVerifier extends StatefulWidget {
  const PaymentLinkVerifier({super.key});

  @override
  State<PaymentLinkVerifier> createState() => _PaymentLinkVerifierState();
}

class AuditEntry {
  DateTime time;
  String link;
  bool isRisky;
  int score;
  String vendor;
  String? note;
  String? cryptoAddress;

  AuditEntry({
    required this.time,
    required this.link,
    required this.isRisky,
    required this.score,
    required this.vendor,
    this.note,
    this.cryptoAddress,
  });

  String get display =>
      '${time.toLocal()} - $link - ${isRisky ? 'Risky' : 'Safe'}';

  List<String> toCsvRow() {
    return [
      time.toIso8601String(),
      link,
      cryptoAddress ?? '',
      isRisky ? 'Risky' : 'Safe',
      score.toString(),
      vendor,
      note ?? ''
    ];
  }
}

class _PaymentLinkVerifierState extends State<PaymentLinkVerifier>
  with TickerProviderStateMixin {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _ruleController = TextEditingController();
  bool _isLoading = false;
  String? _result;
  String? _riskScore;
  String? _vendorStatus;
  String? _faviconUrl;
  String? _screenshotUrl;
  final List<AuditEntry> _auditLog = [];
  late final AnimationController _bgController;
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  String? _cryptoAddress;
  String? _cryptoIdenticonUrl;
  String? _explorerUrl;
  String? _lastVerifiedLink;
  List<AuditEntry> _batchEntries = [];
  String? _extensionModeNote;
  bool _extensionMode = false;
  List<String> _customRules = ["phish", "scam", "fake"];
  int _auditFilter = 0; // 0=All,1=Risky,2=Safe,3=Notes

  // Persistence keys
  final String _kCustomRules = 'plv_custom_rules';

  // Hover state helpers
  bool _hoveringHero = false;

  Future<void> _shareOrCopy(String text) async {
    try {
      // try navigator.share when available
      // dart:html share isn't stable across browsers; fallback to clipboard
      await html.window.navigator.clipboard?.writeText(text);
    } catch (_) {}
  }

  void _verifyLink() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate loading
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      setState(() {
        _result = 'Please enter a link.';
        _riskScore = null;
        _vendorStatus = null;
        _faviconUrl = null;
        _screenshotUrl = null;
      });
      return;
    }

    // AI-powered risk scoring (stub)
    int score = _aiRiskScore(link);
    _riskScore = 'Risk Score: $score/100';

    // Vendor reputation lookup (stub)
    _vendorStatus = _lookupVendor(link);

    // Visual link preview (favicon and screenshot placeholder)
    _faviconUrl = _getFavicon(link);
    _screenshotUrl = _getScreenshot(link);

    // Web3: detect Ethereum address and prepare identicon/explorer
    final eth = extractEthAddress(link);
    _cryptoAddress = eth;
    _cryptoIdenticonUrl = eth != null ? identiconUrl(eth) : null;
    _explorerUrl = eth != null ? explorerUrl(eth) : null;

    // Enhanced verification logic
    bool isRisky = _isRiskyLink(link);
    setState(() {
      _result = isRisky
          ? 'Risky: This link may be unsafe.'
          : 'Safe: No obvious risks detected.';
      _lastVerifiedLink = link;
      final entry = AuditEntry(
        time: DateTime.now(),
        link: link,
        isRisky: isRisky,
        score: score,
        vendor: _vendorStatus ?? 'Unknown',
        cryptoAddress: _cryptoAddress,
        note: '',
      );
      _auditLog.insert(0, entry);
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // auto-check query param ?url=... for extension integration
    final initial = Uri.base.queryParameters['url'];
    if (initial != null && initial.isNotEmpty) {
      _linkController.text = Uri.decodeComponent(initial);
      // slight delay so widgets mount
      Future.delayed(const Duration(milliseconds: 250), () => _verifyLink());
    }
    _loadCustomRules();
    // background animation controller (subtle color shifts)
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    // pulsing FAB
    _fabController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _fabScale = Tween<double>(begin: 0.98, end: 1.04).animate(
        CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _linkController.dispose();
    _ruleController.dispose();
    _bgController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // Paste from clipboard (works in secure contexts and with user gesture)
  Future<void> _pasteFromClipboard() async {
    try {
      final txt = await html.window.navigator.clipboard?.readText();
      if (txt != null && txt.trim().isNotEmpty) {
        setState(() {
          _linkController.text = txt.trim();
        });
        _verifyLink();
      }
    } catch (e) {
      // ignore clipboard errors
    }
  }

  void _showBookmarkletDialog() {
    final code =
        "javascript:(function(){window.open('${Uri.base.origin + Uri.base.path}?url='+encodeURIComponent(location.href),'_blank');})()";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bookmarklet (click & drag to bookmarks)'),
        content: SelectableText(code),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              try {
                html.window.navigator.clipboard?.writeText(code);
              } catch (_) {}
              Navigator.of(ctx).pop();
            },
            child: const Text('Copy Code'),
          ),
        ],
      ),
    );
  }

  // Batch verification (CSV upload stub)
  void _verifyBatch(List<String> links) {
    final List<AuditEntry> entries = [];
    for (final link in links) {
      final score = _aiRiskScore(link);
      final vendor = _lookupVendor(link);
      final risky = _isRiskyLink(link);
      final eth = extractEthAddress(link);
      final entry = AuditEntry(
        time: DateTime.now(),
        link: link,
        isRisky: risky,
        score: score,
        vendor: vendor,
        cryptoAddress: eth,
        note: '',
      );
      entries.add(entry);
    }
    setState(() {
      _batchEntries = entries;
    });
  }

  // Show dialog to paste CSV or newline-separated links
  void _showBatchInputDialog() {
    final TextEditingController pasteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste CSV or links'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: pasteController,
            maxLines: 8,
            decoration: const InputDecoration(
                hintText: 'Paste one link per line or a CSV with links'),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = pasteController.text.trim();
              if (text.isEmpty) return;
              // split by newlines or commas
              final parts = text
                  .split(RegExp(r'[,\n]'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              _verifyBatch(parts);
              Navigator.of(ctx).pop();
            },
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }

  void _applyBatchToAudit({bool clearAfter = true}) {
    setState(() {
      for (final e in _batchEntries.reversed) {
        _auditLog.insert(0, e);
      }
      if (clearAfter) _batchEntries.clear();
    });
  }

  // AI risk scoring stub
  int _aiRiskScore(String link) {
    // Simulate a more nuanced risk score based on matched patterns
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
        ] +
        _customRules;
    int matches = 0;
    for (final p in patterns) {
      if (link.toLowerCase().contains(p)) {
        matches++;
      }
    }
    // base score: 50, add 10 per match, clamp 0-100
    int score = (50 + matches * 10).clamp(0, 100);
    // slightly increase for non-https or shorteners
    if (link.startsWith('http://')) score = (score + 20).clamp(0, 100);
    if (link.contains('bit.ly') || link.contains('tinyurl.com'))
      score = (score + 10).clamp(0, 100);
    return score;
  }

  // Vendor reputation lookup stub
  String _lookupVendor(String link) {
    final domain = Uri.tryParse(link)?.host ?? '';
    final trusted = [
      'paypal.com',
      'stripe.com',
      'squareup.com',
      'wise.com',
      'transferwise.com'
    ];
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
    // heuristic: long-established-looking domains
    if (domain.endsWith('.com') && domain.split('.').first.length > 3)
      return 'Likely Legitimate';
    return 'Unknown Vendor';
  }

  // Favicon placeholder
  String? _getFavicon(String link) {
    Uri? uri = Uri.tryParse(link);
    if (uri != null && uri.host.isNotEmpty) {
      return 'https://www.google.com/s2/favicons?domain=${uri.host}';
    }
    return null;
  }

  // Screenshot placeholder
  String? _getScreenshot(String link) {
    try {
      final uri = Uri.tryParse(link);
      if (uri == null || uri.host.isEmpty) return null;
      // Use WordPress mShots (free) for a quick preview — may have rate limits
      final encoded = Uri.encodeComponent(link);
      return 'https://s.wordpress.com/mshots/v1/$encoded?w=600';
    } catch (_) {
      return null;
    }
  }

  // Audit notes
  void _editAuditNote(AuditEntry entry) {
    final TextEditingController noteController =
        TextEditingController(text: entry.note ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add note'),
        content: TextField(controller: noteController, maxLines: 4),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                entry.note = noteController.text.trim();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Download audit log as CSV in browser
  void _downloadAuditCsv() {
    final rows = <List<String>>[];
    for (final entry in _auditLog) {
      rows.add(entry.toCsvRow());
    }
    final csv = rows
        .map((r) => r.map((c) => '"${c.replaceAll('"', '""')}"').join(','))
        .join('\n');
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'audit_log.csv';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  // Custom rules management
  void _addCustomRule(String rule) {
    if (rule.trim().isEmpty) return;
    if (_customRules.contains(rule)) return;
    setState(() {
      _customRules.add(rule);
      _saveCustomRules();
    });
  }

  void _removeCustomRule(String rule) {
    setState(() {
      _customRules.remove(rule);
      _saveCustomRules();
    });
  }

  void _saveCustomRules() {
    try {
      html.window.localStorage[_kCustomRules] = jsonEncode(_customRules);
    } catch (_) {}
  }

  void _loadCustomRules() {
    try {
      final s = html.window.localStorage[_kCustomRules];
      if (s != null && s.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(s);
        _customRules = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
  }

  void _exportCustomRulesToClipboard() {
    try {
      final txt = _customRules.join('\n');
      html.window.navigator.clipboard?.writeText(txt);
    } catch (_) {}
  }

  void _importCustomRulesFromText(String txt) {
    final parts = txt
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;
    setState(() {
      for (final p in parts) {
        if (!_customRules.contains(p)) {
          _customRules.add(p);
        }
      }
      _saveCustomRules();
    });
  }

  // (Previously had an export helper; CSV export implemented in _downloadAuditCsv)

  bool _isRiskyLink(String link) {
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
        ] +
        _customRules;
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
      if (link.endsWith(tld)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.tealAccent, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Payment Link Verifier',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.extension),
            tooltip: 'Extension Mode',
            onPressed: () {
              setState(() {
                _extensionMode = !_extensionMode;
                // clear the short note when entering extension mode
                if (_extensionMode) _extensionModeNote = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Audit Log',
            onPressed: _downloadAuditCsv,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: _verifyLink,
          icon: const Icon(Icons.search),
          label: const Text('Quick Verify'),
          backgroundColor: Colors.teal,
        ),
      ),
      body: Stack(
        children: [
          // animated background gradient
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final t = _bgController.value;
              final c1 = Color.lerp(const Color(0xFF071826),
                  const Color(0xFF0A2540), 0.5 + 0.5 * sin(2 * pi * t))!;
              final c2 = Color.lerp(const Color(0xFF0A2540),
                  const Color(0xFF2AB7CA), 0.5 + 0.5 * cos(2 * pi * t))!;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c1,
                      c2,
                      const Color(0xFF2AB7CA),
                      const Color(0xFFF5F8FA)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding:
                const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Intro / hero card with brief pitch
                      MouseRegion(
                        onEnter: (_) => setState(() => _hoveringHero = true),
                        onExit: (_) => setState(() => _hoveringHero = false),
                        child: AnimatedSlide(
                          offset: Offset(0, _hoveringHero ? -0.03 : 0.0),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: AnimatedScale(
                            scale: _hoveringHero ? 1.01 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: Card(
                              elevation: _hoveringHero ? 14 : 10,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Payment Link Verifier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8),
                                    Text(
                                      'Quickly check payment, invoice, or vendor links for obvious fraud indicators. This client-side tool helps reduce social-engineering risks by surfacing suspicious patterns, Web3 addresses, and vendor signals without sending your URLs to any server.',
                                    ),
                                    SizedBox(height: 8),
                                    Text('Why this matters:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('- Scams use crafted links to trick payers into sending funds.'),
                                    Text('- Fast, local checks complement manual diligence.'),
                                    Text('- Integrates Web3 address checks for crypto payments.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_extensionMode || _extensionModeNote != null)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _extensionMode
                              ? Card(
                                  key: const ValueKey('ext-mode'),
                                  color: Colors.teal[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.extension,
                                                color: Colors.teal),
                                            const SizedBox(width: 8),
                                            const Text('Extension Mode',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.teal)),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () => setState(
                                                  () => _extensionMode = false),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                            'Quick actions to verify the current page or clipboard.'),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: _pasteFromClipboard,
                                              icon: const Icon(Icons.paste),
                                              label:
                                                  const Text('Paste & Verify'),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: _showBookmarkletDialog,
                                              icon: const Icon(Icons.link),
                                              label:
                                                  const Text('Get Bookmarklet'),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: () {
                                                // copy instructions to clipboard
                                                final txt =
                                                    'Load the extension from the project `extension/` folder in Edge (enable Developer Mode -> Load unpacked).';
                                                try {
                                                  html.window.navigator
                                                      .clipboard
                                                      ?.writeText(txt);
                                                } catch (_) {}
                                              },
                                              icon: const Icon(
                                                  Icons.info_outline),
                                              label: const Text(
                                                  'Copy Install Steps'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                            'Notes: bookmarklet opens the verifier with the current page URL using `?url=`. Use the extension popup for a one-click workflow.'),
                                      ],
                                    ),
                                  ),
                                )
                              : Card(
                                  key: ValueKey(_extensionModeNote),
                                  color: Colors.teal[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      _extensionModeNote!,
                                      style: const TextStyle(
                                        color: Colors.teal,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        child: Card(
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Paste a payment, invoice, or vendor link below to check if it is safe.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _linkController,
                                  decoration: const InputDecoration(
                                    labelText: 'Payment/Invoice/Vendor Link',
                                    prefixIcon:
                                        Icon(Icons.link, color: Colors.teal),
                                  ),
                                  onSubmitted: (_) => _verifyLink(),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _verifyLink,
                                  icon: const Icon(Icons.search),
                                  label: const Text('Verify'),
                                ),
                                if (_isLoading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.teal),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_cryptoAddress != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                if (_cryptoIdenticonUrl != null)
                                  Image.network(
                                    _cryptoIdenticonUrl!,
                                    width: 48,
                                    height: 48,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Web3 Address Detected',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      Text(
                                        _cryptoAddress ?? '',
                                        style: const TextStyle(
                                            fontFamily: 'monospace'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              if (_explorerUrl != null)
                                                html.window.open(
                                                    _explorerUrl!, '_blank');
                                            },
                                            child:
                                                const Text('Open on Etherscan'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // CTA / Marketing section
                              const Text('Share & Install',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                  'Show this tool to a colleague or install the browser extension for quick access.'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final link =
                                          Uri.base.origin + Uri.base.path;
                                      _shareOrCopy(link);
                                    },
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share Link'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // open extension folder README on GitHub
                                      html.window.open(
                                          'https://github.com/vincenek/tax-verifier/tree/main/extension',
                                          '_blank');
                                    },
                                    icon:
                                        const Icon(Icons.download_for_offline),
                                    label: const Text('Extension'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _ruleController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Add Custom Rule (keyword/domain)',
                                        prefixIcon: Icon(
                                          Icons.rule,
                                          color: Colors.teal,
                                        ),
                                      ),
                                      onSubmitted: (rule) {
                                        if (rule.trim().isNotEmpty) {
                                          _addCustomRule(rule.trim());
                                          _ruleController.clear();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      final r = _ruleController.text.trim();
                                      if (r.isNotEmpty) {
                                        _addCustomRule(r);
                                        _ruleController.clear();
                                      }
                                    },
                                    child: const Text('Add'),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label:
                                        Text('Rules: ${_customRules.length}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _exportCustomRulesToClipboard,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Export'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) {
                                          final TextEditingController
                                              importCtrl =
                                              TextEditingController();
                                          return AlertDialog(
                                            title: const Text('Import Rules'),
                                            content: TextField(
                                                controller: importCtrl,
                                                maxLines: 6,
                                                decoration: const InputDecoration(
                                                    hintText:
                                                        'Paste rules, one per line')),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  child: const Text('Cancel')),
                                              ElevatedButton(
                                                onPressed: () {
                                                  _importCustomRulesFromText(
                                                      importCtrl.text);
                                                  Navigator.of(ctx).pop();
                                                },
                                                child: const Text('Import'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.download),
                                    label: const Text('Import'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: _customRules
                                    .map((r) => Chip(
                                          label: Text(r),
                                          onDeleted: () => _removeCustomRule(r),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_faviconUrl != null ||
                          _screenshotUrl != null ||
                          _riskScore != null ||
                          _vendorStatus != null ||
                          _result != null)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Card(
                            key: ValueKey(_result),
                            color: _result?.startsWith('Risky') == true
                                ? Colors.red[50]
                                : Colors.green[50],
                            elevation: 8,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_faviconUrl != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.network(
                                          _faviconUrl!,
                                          width: 24,
                                          height: 24,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                            child: Text('Favicon detected',
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  if (_screenshotUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxHeight: 140),
                                        child: Image.network(
                                          _screenshotUrl!,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                  if (_riskScore != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.shield,
                                            color: Colors.teal),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _riskScore!,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (_vendorStatus != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.business,
                                            color: Colors.teal),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _vendorStatus!,
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 12),
                                  if (_result != null)
                                    Row(
                                      children: [
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 350),
                                          transitionBuilder: (child, anim) =>
                                              ScaleTransition(
                                                  scale: anim, child: child),
                                          child: Icon(
                                            _result!.startsWith('Risky')
                                                ? Icons.warning
                                                : Icons.check_circle,
                                            key: ValueKey(
                                                _result!.startsWith('Risky')),
                                            color: _result!.startsWith('Risky')
                                                ? Colors.red
                                                : Colors.green,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _result!,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color:
                                                  _result!.startsWith('Risky')
                                                      ? Colors.red
                                                      : Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 12),
                                  // Actions for the verified link: paste, clear, remove from audit
                                  if (_lastVerifiedLink != null)
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _pasteFromClipboard,
                                          icon: const Icon(Icons.paste),
                                          label: const Text('Paste & Verify'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              _linkController.clear();
                                              _result = null;
                                              _riskScore = null;
                                              _vendorStatus = null;
                                              _faviconUrl = null;
                                              _screenshotUrl = null;
                                              _cryptoAddress = null;
                                              _cryptoIdenticonUrl = null;
                                              _explorerUrl = null;
                                              _lastVerifiedLink = null;
                                            });
                                          },
                                          child: const Text('Clear Input'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () {
                                            if (_lastVerifiedLink == null)
                                              return;
                                            setState(() {
                                              _auditLog.removeWhere((e) =>
                                                  e.link == _lastVerifiedLink);
                                              _lastVerifiedLink = null;
                                            });
                                          },
                                          icon: const Icon(Icons.delete_forever,
                                              color: Colors.red),
                                          label: const Text('Remove from Audit',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.batch_prediction,
                                    color: Colors.teal,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Batch Verification (CSV):',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _showBatchInputDialog,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload / Paste CSV'),
                              ),
                              if (_batchEntries.isNotEmpty)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _applyBatchToAudit(),
                                          child: const Text(
                                              'Add all to Audit Log'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => setState(
                                              () => _batchEntries.clear()),
                                          child: const Text('Clear Batch'),
                                        ),
                                        const Spacer(),
                                        Text('${_batchEntries.length} results',
                                            style: const TextStyle(
                                                color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.28,
                                          maxWidth: double.infinity),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: _batchEntries.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 8),
                                        itemBuilder: (context, i) {
                                          final e = _batchEntries[i];
                                          return TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 18.0, end: 0.0),
                                            duration: Duration(
                                                milliseconds: 300 + (i * 30)),
                                            builder: (context, val, child) =>
                                                Transform.translate(
                                              offset: Offset(0, val),
                                              child: Opacity(
                                                  opacity: 1.0 -
                                                      (val / 30.0)
                                                          .clamp(0.0, 1.0),
                                                  child: child),
                                            ),
                                            child: ListTile(
                                              title: Text(e.display,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              subtitle: Text(
                                                  'Score: ${e.score} • ${e.vendor}'),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                    Icons.add_circle_outline),
                                                tooltip: 'Add to Audit Log',
                                                onPressed: () {
                                                  setState(() {
                                                    _auditLog.insert(0, e);
                                                    _batchEntries.removeAt(i);
                                                  });
                                                },
                                              ),
                                              onTap: () => _editAuditNote(e),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.history, color: Colors.teal),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Audit Log:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('All'),
                                    selected: _auditFilter == 0,
                                    onSelected: (v) => setState(() =>
                                        _auditFilter = v ? 0 : _auditFilter),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Risky'),
                                    selected: _auditFilter == 1,
                                    onSelected: (v) => setState(() =>
                                        _auditFilter = v ? 1 : _auditFilter),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Safe'),
                                    selected: _auditFilter == 2,
                                    onSelected: (v) => setState(() =>
                                        _auditFilter = v ? 2 : _auditFilter),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Notes'),
                                    selected: _auditFilter == 3,
                                    onSelected: (v) => setState(() =>
                                        _auditFilter = v ? 3 : _auditFilter),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: MediaQuery.of(context).size.height *
                                            0.32 <
                                        300
                                    ? MediaQuery.of(context).size.height * 0.32
                                    : 300,
                                child: Builder(builder: (context) {
                                  final filtered = _auditLog.where((e) {
                                    if (_auditFilter == 1) return e.isRisky;
                                    if (_auditFilter == 2) return !e.isRisky;
                                    if (_auditFilter == 3)
                                      return e.note != null &&
                                          e.note!.isNotEmpty;
                                    return true;
                                  }).toList();

                                  if (filtered.isEmpty) {
                                    return const Center(
                                      child: Text('No audit entries',
                                          style: TextStyle(color: Colors.grey)),
                                    );
                                  }

                                  return ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final entry = filtered[index];
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 18.0, end: 0.0),
                                        duration: Duration(
                                            milliseconds: 300 + (index * 25)),
                                        builder: (context, val, child) =>
                                            Transform.translate(
                                          offset: Offset(0, val),
                                          child: Opacity(
                                              opacity: 1.0 -
                                                  (val / 30.0).clamp(0.0, 1.0),
                                              child: child),
                                        ),
                                        child: Card(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: ListTile(
                                            leading: Icon(
                                              entry.isRisky
                                                  ? Icons.warning
                                                  : Icons.check_circle,
                                              color: entry.isRisky
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            title: Text(entry.display,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            subtitle: entry.note != null &&
                                                    entry.note!.isNotEmpty
                                                ? Text(entry.note!)
                                                : null,
                                            onTap: () => _editAuditNote(entry),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.grey),
                                              onPressed: () {
                                                setState(() {
                                                  _auditLog.remove(entry);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
