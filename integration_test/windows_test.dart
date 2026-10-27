import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:codex_thermometer/monitor.dart';
import 'package:codex_thermometer/thermo_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('read real Codex account and native window controls', (
    tester,
  ) async {
    final monitor = Monitor();
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ThermoApp(monitor: monitor, updates: false),
      ),
    );
    await tester.runAsync(() async {
      await monitor.start();
      expect(monitor.limitsError, isNull);
      expect(monitor.buckets, isNotEmpty);
      expect(monitor.activityError, isNull);
      expect(monitor.activity?.lifetime, isNotNull);
      expect(monitor.localError, isNull);
      expect(monitor.local.available, isTrue);
      expect(monitor.local.latest, isNotNull);
      await Future<void>.delayed(const Duration(seconds: 6));
      await monitor.refreshLocal();
      expect(monitor.tokensPerMinute, isNotNull);
      expect(monitor.tokensPerMinute, greaterThanOrEqualTo(0));
      if (monitor.pinned) await monitor.togglePin();
      if (monitor.compact) await monitor.toggleCompact();
      await monitor.togglePin();
      expect(monitor.pinned, isTrue);
      expect(
        (await windowChannel.invokeMapMethod<String, dynamic>(
          'state',
        ))!['pinned'],
        isTrue,
      );
      await monitor.togglePin();
      expect(monitor.pinned, isFalse);
      await monitor.toggleCompact();
      expect(monitor.compact, isTrue);
    });
    await tester.pumpAndSettle();
    expect(find.text('restantes'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Future<void> capture(String name) async {
      final image =
          await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('outputs').create();
      await File('outputs/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }

    await tester.runAsync(() => capture('compact'));
    await tester.runAsync(() async {
      await monitor.toggleCompact();
    });
    await tester.pumpAndSettle();
    expect(find.text('Seu ritmo, à vista.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => capture('dashboard'));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -450),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => capture('details'));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 450),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await monitor.toggleDark();
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() => capture('dark'));
    await tester.runAsync(() async {
      await monitor.toggleDark();
      await windowChannel.invokeMethod('tray');
      expect(
        (await windowChannel.invokeMapMethod<String, dynamic>(
          'state',
        ))!['visible'],
        isFalse,
      );
      await windowChannel.invokeMethod('show');
      expect(
        (await windowChannel.invokeMapMethod<String, dynamic>(
          'state',
        ))!['visible'],
        isTrue,
      );
    });
    monitor.dispose();
  });
}
