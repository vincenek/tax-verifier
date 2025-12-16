List<String> extractLinksFromCsv(String text, {String? columnName, int? columnIndex}) {
  final lines = text.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return [];
  final separator = lines.first.contains(',') ? ',' : '\t';
  List<String> headers = [];
  int start = 0;
  if (lines.first.contains(separator) && !lines.first.toLowerCase().contains('http') && !lines.first.contains('://')) {
    headers = lines.first.split(separator).map((s) => s.trim()).toList();
    start = 1;
  }
  final results = <String>[];
  for (int i = start; i < lines.length; i++) {
    final parts = lines[i].split(separator).map((s) => s.trim()).toList();
    String? candidate;
    if (columnName != null && headers.isNotEmpty) {
      final idx = headers.indexWhere((h) => h.toLowerCase() == columnName.toLowerCase());
      if (idx >= 0 && idx < parts.length) candidate = parts[idx];
    }
    if (candidate == null && columnIndex != null && columnIndex >= 0 && columnIndex < parts.length) {
      candidate = parts[columnIndex];
    }
    if (candidate == null) {
      for (final f in parts) {
        if (f.startsWith('http://') || f.startsWith('https://') || f.contains('www.') || f.contains('://')) {
          candidate = f;
          break;
        }
      }
    }
    if (candidate != null && candidate.isNotEmpty) results.add(candidate);
  }
  return results;
}

List<String> parseCsvLinks(String text) {
  final lines = text.split(RegExp(r'\r?\n'));
  final List<String> results = [];
  int start = 0;
  if (lines.isNotEmpty) {
    final first = lines[0];
    final hasComma = first.contains(',');
    final looksLikeHeader = hasComma && !first.toLowerCase().contains('http') && !first.contains('://');
    if (looksLikeHeader) start = 1;
  }
  for (int i = start; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;
    if (line.contains(',')) {
      final fields = line.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      String? picked;
      for (final f in fields) {
        if (f.startsWith('http://') || f.startsWith('https://') || f.contains('www.')) {
          picked = f;
          break;
        }
        if (f.contains('.') && f.contains('/')) {
          picked = f;
          break;
        }
      }
      if (picked != null) {
        results.add(picked);
        continue;
      }
      results.add(fields.last);
      continue;
    }
    results.add(line.trim());
  }
  return results;
}
