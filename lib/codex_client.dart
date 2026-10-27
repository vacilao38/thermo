import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'usage.dart';

class CodexException implements Exception {
  final String message;
  const CodexException(this.message);
  @override
  String toString() => message;
}

/// Read-only client: never starts model turns and never reads auth.json.
class CodexClient {
  Process? _process;
  Future<void>? _starting;
  StreamSubscription<String>? _lines;
  StreamSubscription<List<int>>? _errors;
  final _pending = <int, Completer<Json>>{};
  int _id = 0;
  bool _closed = false;
  String? executable;
  static Future<String?> locate() async {
    final local = Platform.environment['LOCALAPPDATA'];
    if (local != null) {
      final root = Directory('$local/OpenAI/Codex/bin');
      if (await root.exists()) {
        final dated = <(File, DateTime)>[];
        await for (final entry in root.list(followLinks: false)) {
          final f = File('${entry.path}/codex.exe');
          if (entry is Directory && await f.exists()) {
            dated.add((f, (await f.stat()).modified));
          }
        }
        dated.sort((a, b) => b.$2.compareTo(a.$2));
        if (dated.isNotEmpty) return dated.first.$1.path;
      }
    }
    for (final dir in (Platform.environment['PATH'] ?? '').split(';')) {
      final f = File('$dir/codex.exe');
      if (await f.exists()) return f.path;
    }
    return null;
  }

  Future<void> connect() async {
    if (_closed) throw const CodexException('Monitor encerrado.');
    if (_starting != null) return _starting;
    if (_process != null) return;
    _starting = _connect();
    try {
      await _starting;
    } finally {
      _starting = null;
    }
  }

  Future<void> _connect() async {
    executable ??= await locate();
    if (executable == null) {
      throw const CodexException(
        'Codex não encontrado. Instale o Codex para Windows e entre na sua conta.',
      );
    }
    try {
      final p = await Process.start(executable!, [
        'app-server',
        '--listen',
        'stdio://',
      ], mode: ProcessStartMode.normal);
      if (_closed) {
        p.kill();
        return;
      }
      _process = p;
      _errors = p.stderr.listen((_) {});
      _lines = p.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_receive, onError: (_) => _lost(p), onDone: () => _lost(p));
      await _request('initialize', {
        'clientInfo': {
          'name': 'clustter_thermometer',
          'title': 'Thermo',
          'version': '0.1.0',
        },
        'capabilities': {'experimentalApi': true},
      });
      p.stdin.writeln(jsonEncode({'method': 'initialized', 'params': {}}));
    } catch (_) {
      await _disconnect();
      throw const CodexException(
        'Não foi possível conectar ao Codex. Abra o Codex, confirme o login e tente atualizar.',
      );
    }
  }

  void _receive(String line) {
    try {
      final v = object(jsonDecode(line));
      final pending = _pending.remove(integer(v['id']));
      if (pending == null) return;
      if (v.containsKey('error')) {
        pending.completeError(
          const CodexException(
            'Consulta indisponível. Confirme o login ChatGPT no Codex e a conexão.',
          ),
        );
      } else {
        pending.complete(object(v['result']));
      }
    } on FormatException {
      /* Non-protocol output. */
    }
  }

  void _lost(Process p) {
    if (_process != p) return;
    _process = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(
          const CodexException(
            'A conexão com o Codex foi encerrada. Tente atualizar.',
          ),
        );
      }
    }
    _pending.clear();
  }

  Future<Json> _request(String method, Json params) async {
    final id = ++_id;
    final completer = Completer<Json>();
    _pending[id] = completer;
    try {
      _process!.stdin.writeln(
        jsonEncode({'id': id, 'method': method, 'params': params}),
      );
      return await completer.future.timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const CodexException(
        'O Codex demorou a responder. Tente atualizar novamente.',
      );
    } finally {
      _pending.remove(id);
    }
  }

  Future<Json> limits() async {
    await connect();
    return _request('account/rateLimits/read', {
      'excludeResetCreditDetails': true,
    });
  }

  Future<Json> activity() async {
    await connect();
    return _request('account/usage/read', {});
  }

  Future<void> _disconnect() async {
    final p = _process;
    _process = null;
    await _lines?.cancel();
    await _errors?.cancel();
    p?.kill();
  }

  Future<void> close() async {
    _closed = true;
    await _disconnect();
  }
}
