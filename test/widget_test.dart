import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:codex_thermometer/monitor.dart';
import 'package:codex_thermometer/thermo_app.dart';
import 'package:codex_thermometer/usage.dart';

void main() {
  testWidgets('unknown data is not displayed as zero or a token budget', (
    tester,
  ) async {
    final monitor = Monitor();
    await tester.binding.setSurfaceSize(const Size(1120, 900));
    await tester.pumpWidget(ThermoApp(monitor: monitor, updates: false));
    expect(find.text('Não informado'), findsOneWidget);
    expect(find.text('Seu ritmo, à vista.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    monitor.dispose();
  });
  for (final width in [360.0, 790.0, 1120.0]) {
    testWidgets(
      'layout at width $width with large text and actual quota states',
      (tester) async {
        final monitor = Monitor();
        monitor.buckets = [
          QuotaBucket('codex', 'Codex', 'plus', [
            QuotaWindow(23, 300, DateTime.now().add(const Duration(hours: 1))),
            QuotaWindow(41, 10080, DateTime.now().add(const Duration(days: 2))),
          ]),
        ];
        await tester.binding.setSurfaceSize(Size(width, 900));
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Dashboard(monitor: monitor),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        monitor.dispose();
      },
    );
  }
}
