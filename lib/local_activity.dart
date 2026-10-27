import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'usage.dart';

class LogCursor {
  int offset = 0;
  List<int> pending = [];
  Json previous = {};
  bool discarding = false;
}

/// Incremental counters only. Conversation bodies never leave this reader.
class LocalScanner {
  final String root;
  final Map<String, LogCursor> cursors = {};
  final Set<String> seen = {};
  String? day;
  int input = 0, cached = 0, output = 0, total = 0;
  DateTime? latest;
  int? contextWindow, contextUsed;
  LocalScanner(this.root);

  Future<LocalScanner> update(DateTime now) async {
    if (day != dateKey(now)) {
      day = dateKey(now);
      cursors.clear();
      seen.clear();
      input = cached = output = total = 0;
      latest = null;
      contextWindow = contextUsed = null;
    }
    final base = Directory('$root/sessions');
    if (!await base.exists()) return this;
    // Session files are partitioned by creation date, including long-running chats.
    // Enumerate metadata, then read only appended bytes; no fixed recent-day cutoff.
    await for (final f in base.list(recursive: true, followLinks: false)) {
      if (f is! File || !f.path.endsWith('.jsonl')) continue;
      try {
        final stat = await f.stat();
        if (stat.modified.isBefore(
          DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 1)),
        )) {
          continue;
        }
        final cursor = cursors.putIfAbsent(f.path, LogCursor.new);
        if (stat.size < cursor.offset) {
          cursor.offset = 0;
          cursor.pending = [];
          cursor.previous = {};
          cursor.discarding = false;
        }
        if (stat.size == cursor.offset) continue;
        final handle = await f.open();
        try {
          await handle.setPosition(cursor.offset);
          // Bounded chunks prevent a large history from blocking the UI or spiking RAM.
          while (cursor.offset < stat.size) {
            final length = (stat.size - cursor.offset).clamp(0, 256 * 1024);
            final chunk = await handle.read(length);
            if (chunk.isEmpty) break;
            cursor.offset += chunk.length;
            final bytes = [...cursor.pending, ...chunk];
            int start = 0;
            for (int i = 0; i < bytes.length; i++) {
              if (bytes[i] != 10) continue;
              if (!cursor.discarding && i - start < 2 * 1024 * 1024) {
                consume(
                  utf8.decode(bytes.sublist(start, i), allowMalformed: true),
                  cursor,
                  now,
                );
              }
              cursor.discarding = false;
              start = i + 1;
            }
            cursor.pending = bytes.sublist(start);
            // Oversized non-metric lines are discarded through their next newline.
            if (cursor.pending.length > 2 * 1024 * 1024) {
              cursor.pending = [];
              cursor.discarding = true;
            }
          }
        } finally {
          await handle.close();
        }
      } on FileSystemException {
        /* A Codex session may be rotated during a read. */
      }
    }
    return this;
  }

  void consume(String line, LogCursor cursor, DateTime now) {
    if (!line.contains('"token_count"')) return;
    try {
      final event = object(jsonDecode(line));
      final payload = object(event['payload']);
      if (event['type'] != 'event_msg' || payload['type'] != 'token_count') {
        return;
      }
      final timestamp = event['timestamp'];
      final stamp = timestamp is String
          ? DateTime.tryParse(timestamp)?.toLocal()
          : null;
      final info = object(payload['info']);
      final cumulative = object(info['total_token_usage']);
      final last = object(info['last_token_usage']);
      if (cumulative.isEmpty) return;
      // Repeated snapshots have zero delta. A fork's inherited total is not new usage.
      int delta(String key) {
        final current = integer(cumulative[key]) ?? 0;
        final prior = integer(cursor.previous[key]);
        if (prior == null || current < prior) {
          return (integer(last[key]) ?? 0).clamp(0, current);
        }
        return (current - prior).clamp(0, current);
      }

      final signature =
          '$timestamp:${jsonEncode(cumulative)}:${jsonEncode(last)}';
      if (stamp != null &&
          dateKey(stamp) == dateKey(now) &&
          seen.add(signature)) {
        input += delta('input_tokens');
        cached += delta('cached_input_tokens');
        output += delta('output_tokens');
        total += delta('total_tokens');
        if (latest == null || !stamp.isBefore(latest!)) {
          latest = stamp;
          contextWindow = integer(info['model_context_window']);
          contextUsed = integer(last['total_tokens']);
        }
      }
      cursor.previous = cumulative;
    } on FormatException {
      /* Partial/corrupt lines are not measurements. */
    }
  }

  LocalActivity get snapshot => LocalActivity(
    input: input,
    cached: cached,
    output: output,
    total: total,
    latest: latest,
    contextWindow: contextWindow,
    contextUsed: contextUsed,
    available: cursors.isNotEmpty,
  );
}

Future<LocalScanner> scanInBackground(LocalScanner scanner, DateTime now) =>
    Isolate.run(() => scanner.update(now));
