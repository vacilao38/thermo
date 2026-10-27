import 'package:flutter_test/flutter_test.dart';
import 'package:codex_thermometer/codex_client.dart';
import 'package:codex_thermometer/monitor.dart';
import 'package:codex_thermometer/usage.dart';

class FixtureClient extends CodexClient {
  bool failLimits = false, failActivity = false;
  @override
  Future<Json> limits() async {
    if (failLimits) throw const CodexException('Offline');
    return {
      'rateLimits': {
        'primary': {'usedPercent': 18, 'windowDurationMins': 300},
      },
    };
  }

  @override
  Future<Json> activity() async {
    if (failActivity) throw const CodexException('Unsupported');
    return {
      'summary': {'lifetimeTokens': 400},
      'dailyUsageBuckets': [],
    };
  }

  @override
  Future<void> close() async {}
}

void main() {
  test('history failure does not discard valid account limits', () async {
    final client = FixtureClient()..failActivity = true;
    final monitor = Monitor(client: client);
    await monitor.refresh(forceActivity: true);
    expect(monitor.limiting!.remaining, 82);
    expect(monitor.limitsError, isNull);
    expect(monitor.activityError, isNotNull);
    expect(monitor.loading, isFalse);
    monitor.dispose();
  });
  test('offline marks old limits stale; recovery replaces error', () async {
    final client = FixtureClient();
    final monitor = Monitor(client: client);
    await monitor.refresh(forceActivity: true);
    final last = monitor.limitsAt;
    client.failLimits = true;
    await monitor.refresh();
    expect(monitor.limitsAt, last);
    expect(monitor.stale, isTrue);
    expect(monitor.limiting!.remaining, 82);
    client.failLimits = false;
    await monitor.refresh();
    expect(monitor.stale, isFalse);
    expect(monitor.limitsError, isNull);
    monitor.dispose();
  });
}
