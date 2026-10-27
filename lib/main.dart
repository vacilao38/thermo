import 'dart:async';
import 'package:flutter/material.dart';
import 'monitor.dart';
import 'thermo_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final monitor = Monitor();
  runApp(ThermoApp(monitor: monitor));
  unawaited(monitor.start());
}
