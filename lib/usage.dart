import 'dart:math' as math;

typedef Json = Map<String, dynamic>;
Json object(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
int? integer(dynamic value) =>
    value is num && value.isFinite ? value.toInt() : null;

class QuotaWindow {
  final double used;
  final int? minutes;
  final DateTime? resetsAt;
  const QuotaWindow(this.used, this.minutes, this.resetsAt);
  double get remaining => (100 - used).clamp(0, 100);
  bool expired(DateTime now) => resetsAt != null && !resetsAt!.isAfter(now);
  String get label => minutes == 10080
      ? 'Semanal'
      : minutes == 300
      ? 'Janela de 5 horas'
      : minutes == null
      ? 'Janela de uso'
      : minutes! % 60 == 0
      ? 'Janela de ${minutes! ~/ 60} horas'
      : 'Janela de $minutes min';
  static QuotaWindow? parse(dynamic raw) {
    final v = object(raw);
    final used = v['usedPercent'];
    if (used is! num || !used.isFinite) return null;
    final reset = integer(v['resetsAt']);
    return QuotaWindow(
      used.toDouble().clamp(0, 100),
      integer(v['windowDurationMins']),
      reset == null ? null : DateTime.fromMillisecondsSinceEpoch(reset * 1000),
    );
  }
}

class QuotaBucket {
  final String id, label;
  final String? plan;
  final List<QuotaWindow> windows;
  const QuotaBucket(this.id, this.label, this.plan, this.windows);
  static List<QuotaBucket> parse(Json response) {
    final multiple = object(response['rateLimitsByLimitId']);
    final entries = multiple.isNotEmpty
        ? multiple.entries.toList()
        : [MapEntry('codex', object(response['rateLimits']))];
    final result = entries
        .map((e) {
          final v = object(e.value);
          return QuotaBucket(
            e.key,
            v['limitName'] as String? ?? (e.key == 'codex' ? 'Codex' : e.key),
            v['planType'] as String?,
            [
              QuotaWindow.parse(v['primary']),
              QuotaWindow.parse(v['secondary']),
            ].whereType<QuotaWindow>().toList(),
          );
        })
        .where((b) => b.windows.isNotEmpty)
        .toList();
    result.sort(
      (a, b) => a.id == 'codex'
          ? -1
          : b.id == 'codex'
          ? 1
          : a.id.compareTo(b.id),
    );
    return result;
  }

  QuotaWindow? tightest(DateTime now) {
    final valid = windows.where((w) => !w.expired(now)).toList()
      ..sort((a, b) => a.remaining.compareTo(b.remaining));
    return valid.firstOrNull;
  }
}

class AccountActivity {
  final int? lifetime;
  final Map<String, int> daily;
  final DateTime fetchedAt;
  AccountActivity(this.lifetime, this.daily, this.fetchedAt);
  factory AccountActivity.parse(Json raw, DateTime now) {
    final daily = <String, int>{};
    final buckets = raw['dailyUsageBuckets'];
    if (buckets is List) {
      for (final item in buckets) {
        final b = object(item);
        final date = b['startDate'];
        final tokens = integer(b['tokens']);
        if (date is String &&
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) &&
            tokens != null &&
            tokens >= 0) {
          daily[date] = tokens;
        }
      }
    }
    return AccountActivity(
      integer(object(raw['summary'])['lifetimeTokens']),
      daily,
      now,
    );
  }
  int? day(DateTime now) => daily[dateKey(now)];
  int? week(DateTime now) {
    final dates = List.generate(
      7,
      (i) => dateKey(DateTime(now.year, now.month, now.day - i)),
    );
    final values = dates.where(daily.containsKey).map((d) => daily[d]!);
    return values.isEmpty ? null : values.fold<int>(0, (a, b) => a + b);
  }
}

String dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String pretty(num? n) {
  if (n == null) return '—';
  if (n >= 1000000000) {
    return '${(n / 1000000000).toStringAsFixed(2).replaceAll('.', ',')} bi';
  }
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(2).replaceAll('.', ',')} mi';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1).replaceAll('.', ',')} mil';
  }
  return n.round().toString();
}

String exact(num n) => n.round().toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]}.',
);
String countdown(DateTime? reset, DateTime now) {
  if (reset == null) return 'Horário não informado';
  final d = reset.difference(now);
  if (d.inSeconds <= 0) return 'Aguardando confirmação da renovação';
  if (d.inDays > 0) return 'Renova em ${d.inDays}d ${d.inHours % 24}h';
  return 'Renova em ${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}min';
}

class LocalActivity {
  final int input, cached, output, total;
  final DateTime? latest;
  final int? contextWindow, contextUsed;
  final bool available;
  const LocalActivity({
    this.input = 0,
    this.cached = 0,
    this.output = 0,
    this.total = 0,
    this.latest,
    this.contextWindow,
    this.contextUsed,
    this.available = false,
  });
  int? get contextRemaining => contextWindow == null || contextUsed == null
      ? null
      : math.max(0, contextWindow! - contextUsed!);
}
