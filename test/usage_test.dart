import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:codex_thermometer/usage.dart';
import 'package:codex_thermometer/local_activity.dart';

void main() {
  final now = DateTime(2026, 10, 27, 12);
  final future =
      now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  test(
    'multi-bucket response wins over legacy and uses actual window duration',
    () {
      final b = QuotaBucket.parse({
        'rateLimits': {
          'primary': {'usedPercent': 99},
        },
        'rateLimitsByLimitId': {
          'codex': {
            'primary': {
              'usedPercent': 23,
              'windowDurationMins': 10080,
              'resetsAt': future,
            },
            'secondary': null,
          },
          'other': {
            'primary': {'usedPercent': 4},
          },
        },
      });
      expect(b.first.id, 'codex');
      expect(b.first.windows.single.label, 'Semanal');
      expect(b.first.tightest(now)!.remaining, 77);
    },
  );
  test(
    'missing usage is unknown; overshoot clamps; expired window is not reset to 100%',
    () {
      expect(QuotaWindow.parse({'usedPercent': null}), isNull);
      expect(QuotaWindow.parse({'usedPercent': double.nan}), isNull);
      expect(QuotaWindow.parse({'usedPercent': 125})!.remaining, 0);
      expect(
        QuotaBucket('x', 'x', null, [QuotaWindow(100, 300, now)]).tightest(now),
        isNull,
      );
      expect(countdown(now, now), contains('confirmação'));
    },
  );
  test(
    'missing daily buckets stay missing and 7-day sum excludes older data',
    () {
      final a = AccountActivity.parse({
        'summary': {'lifetimeTokens': 500},
        'dailyUsageBuckets': [
          {'startDate': '2026-10-21', 'tokens': 30},
          {'startDate': '2026-10-20', 'tokens': 70},
          {'startDate': '2026-10-26', 'tokens': 50},
        ],
      }, now);
      expect(a.day(now), isNull);
      expect(a.week(now), 80);
    },
  );
  String event(int total, int last, DateTime time) => jsonEncode({
    'type': 'event_msg',
    'timestamp': time.toUtc().toIso8601String(),
    'payload': {
      'type': 'token_count',
      'info': {
        'total_token_usage': {
          'total_tokens': total,
          'input_tokens': total - 2,
          'cached_input_tokens': 4,
          'output_tokens': 2,
        },
        'last_token_usage': {
          'total_tokens': last,
          'input_tokens': last - 2,
          'cached_input_tokens': 1,
          'output_tokens': 2,
        },
        'model_context_window': 1000,
      },
    },
  });
  test(
    'local snapshots deduplicate repeats and do not count inherited fork total',
    () {
      final scanner = LocalScanner('unused');
      final cursor = LogCursor();
      scanner.consume(event(900, 20, now), cursor, now);
      scanner.consume(event(900, 20, now), cursor, now);
      scanner.consume(event(950, 50, now), cursor, now);
      expect(scanner.total, 70);
      expect(scanner.snapshot.contextRemaining, 950);
    },
  );
  test('old baseline is retained but not counted in local today', () {
    final scanner = LocalScanner('unused');
    final cursor = LogCursor();
    scanner.consume(
      event(900, 20, now.subtract(const Duration(days: 1))),
      cursor,
      now,
    );
    scanner.consume(event(930, 30, now), cursor, now);
    expect(scanner.total, 30);
    scanner.consume('{partial', cursor, now);
    expect(scanner.total, 30);
  });
  test('replayed events in a fork do not count again across files', () {
    final scanner = LocalScanner('unused');
    final original = LogCursor();
    final fork = LogCursor();
    for (final cursor in [original, fork]) {
      scanner.consume(event(100, 20, now), cursor, now);
      scanner.consume(
        event(140, 40, now.add(const Duration(seconds: 1))),
        cursor,
        now,
      );
    }
    expect(scanner.total, 60);
    scanner.consume(
      event(180, 40, now.add(const Duration(seconds: 2))),
      fork,
      now,
    );
    expect(scanner.total, 100);
  });
  test(
    'reader handles partial appends, multibyte text, and unchanged files',
    () async {
      final temp = await Directory.systemTemp.createTemp('thermo-test-');
      try {
        final dir = await Directory('${temp.path}/sessions').create();
        final file = File('${dir.path}/rollout.jsonl');
        final line = event(100, 10, now);
        await file.writeAsString(
          '{"type":"message","text":"criação"}\n${line.substring(0, line.length ~/ 2)}',
        );
        final scanner = LocalScanner(temp.path);
        await scanner.update(now);
        expect(scanner.total, 0);
        await file.writeAsString(
          '${line.substring(line.length ~/ 2)}\n',
          mode: FileMode.append,
        );
        await scanner.update(now);
        expect(scanner.total, 10);
        await scanner.update(now);
        expect(scanner.total, 10);
      } finally {
        await temp.delete(recursive: true);
      }
    },
  );
}
