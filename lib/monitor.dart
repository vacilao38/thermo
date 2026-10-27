import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'codex_client.dart';
import 'local_activity.dart';
import 'usage.dart';

const windowChannel = MethodChannel('clustter.thermo/window');

class Monitor extends ChangeNotifier {
  final CodexClient client;
  List<QuotaBucket> buckets = [];
  String? selectedId;
  AccountActivity? activity;
  LocalActivity local = const LocalActivity();
  DateTime now = DateTime.now();
  DateTime? limitsAt, localAt;
  String? limitsError, activityError, localError;
  bool loading = false,
      localBusy = false,
      pinned = false,
      compact = false,
      dark = false,
      paused = false;
  bool _disposed = false;
  bool _usageBusy = false;
  Timer? _clock, _poll;
  LocalScanner? _scanner;
  File? _settings;
  final List<(DateTime, int)> _samples = [];
  Monitor({CodexClient? client}) : client = client ?? CodexClient();
  QuotaBucket? get selected =>
      buckets.where((b) => b.id == selectedId).firstOrNull ??
      buckets.firstOrNull;
  QuotaWindow? get limiting => selected?.tightest(now);
  bool get stale =>
      limitsError != null ||
      limitsAt == null ||
      now.difference(limitsAt!).inSeconds > 150;
  double? get tokensPerMinute {
    if (_samples.length < 2) return null;
    final elapsed =
        _samples.last.$1.difference(_samples.first.$1).inMilliseconds / 60000;
    return elapsed < 0.08
        ? null
        : ((_samples.last.$2 - _samples.first.$2) / elapsed).clamp(
            0,
            double.infinity,
          );
  }

  Future<void> start() async {
    final home =
        Platform.environment['CODEX_HOME'] ??
        '${Platform.environment['USERPROFILE']}/.codex';
    _scanner = LocalScanner(home);
    try {
      _settings = File(
        '${(await getApplicationSupportDirectory()).path}/preferences.json',
      );
      if (await _settings!.exists()) {
        final prefs = object(jsonDecode(await _settings!.readAsString()));
        pinned = prefs['pinned'] == true;
        dark = prefs['dark'] == true;
        compact = prefs['compact'] == true;
      }
      if (pinned) await windowChannel.invokeMethod('pin', true);
      if (compact) await windowChannel.invokeMethod('compact', true);
    } catch (_) {
      /* Missing/corrupt preferences cannot block the monitor. */
    }
    if (_disposed) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      now = DateTime.now();
      _notify();
    });
    int ticks = 0;
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      if (paused) return;
      unawaited(refreshLocal());
      if (++ticks % 12 == 0) unawaited(refresh());
    });
    final firstLocal = refreshLocal();
    await refresh(forceActivity: true);
    await firstLocal;
  }

  Future<void> refresh({bool forceActivity = false}) async {
    if (loading || _disposed) return;
    loading = true;
    _notify();
    final wantActivity =
        forceActivity ||
        activity == null ||
        now.difference(activity!.fetchedAt).inMinutes >= 5;
    // Independent errors: unsupported token history must not hide valid limits.
    final usageTask = wantActivity && !_usageBusy
        ? refreshActivity()
        : Future<void>.value();
    try {
      final raw = await client.limits();
      if (_disposed) return;
      buckets = QuotaBucket.parse(raw);
      limitsAt = DateTime.now();
      limitsError = buckets.isEmpty
          ? 'A conta não informou janelas de uso. Entre com ChatGPT no Codex.'
          : null;
    } catch (e) {
      limitsError = e is CodexException
          ? e.message
          : 'Não foi possível consultar os limites. Tente atualizar.';
    }
    await usageTask;
    loading = false;
    _notify();
  }

  Future<void> refreshActivity() async {
    _usageBusy = true;
    try {
      final raw = await client.activity();
      if (_disposed) return;
      activity = AccountActivity.parse(raw, DateTime.now());
      activityError = null;
    } catch (_) {
      activityError = 'Histórico da conta indisponível nesta leitura.';
    } finally {
      _usageBusy = false;
    }
  }

  Future<void> refreshLocal() async {
    if (localBusy || _scanner == null || _disposed) return;
    localBusy = true;
    try {
      _scanner = await scanInBackground(_scanner!, DateTime.now());
      if (_disposed) return;
      local = _scanner!.snapshot;
      localAt = DateTime.now();
      localError = null;
      if (_samples.isNotEmpty && local.total < _samples.last.$2) {
        _samples.clear();
      }
      _samples.add((localAt!, local.total));
      _samples.removeWhere((s) => localAt!.difference(s.$1).inSeconds > 60);
    } catch (_) {
      localError =
          'Atividade local indisponível. Os limites da conta continuam separados.';
    } finally {
      localBusy = false;
      _notify();
    }
  }

  void select(String id) {
    selectedId = id;
    _notify();
  }

  void togglePause() {
    paused = !paused;
    _notify();
    if (!paused) {
      unawaited(refresh());
      unawaited(refreshLocal());
    }
  }

  Future<void> togglePin() async {
    await windowChannel.invokeMethod('pin', !pinned);
    pinned = !pinned;
    await _save();
    _notify();
  }

  Future<void> toggleCompact() async {
    await windowChannel.invokeMethod('compact', !compact);
    compact = !compact;
    await _save();
    _notify();
  }

  Future<void> toggleDark() async {
    dark = !dark;
    await _save();
    _notify();
  }

  Future<void> _save() async {
    try {
      await _settings?.parent.create(recursive: true);
      await _settings?.writeAsString(
        jsonEncode({
          'schema': 1,
          'pinned': pinned,
          'compact': compact,
          'dark': dark,
        }),
        flush: true,
      );
    } catch (_) {
      /* Visual preferences are optional; usage is never persisted. */
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _clock?.cancel();
    _poll?.cancel();
    unawaited(client.close());
    super.dispose();
  }
}
