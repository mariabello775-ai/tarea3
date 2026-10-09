// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/air_quality_service.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  group('Índice de exposición', () {
    test('multiplica PM2.5 por las horas al aire libre', () {
      expect(calculateExposureIndex(25, 4), 100);
    });

    test('clasifica correctamente los límites de riesgo', () {
      expect(classifyExposure(99.99), ExposureRisk.low);
      expect(classifyExposure(100), ExposureRisk.moderate);
      expect(classifyExposure(200), ExposureRisk.moderate);
      expect(classifyExposure(200.01), ExposureRisk.high);
    });
  });

  testWidgets('consulta PM2.5 y muestra el índice calculado', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'hourly': {
            'time': ['2026-10-09T00:00', '2026-10-09T01:00', '2026-10-09T02:00'],
            'pm2_5': [10, 20, 30],
          },
        }),
        200,
      );
    });

    await tester.pumpWidget(MyApp(service: AirQualityService(client: client)));
  final queryButton = find.byKey(const ValueKey('query-air-quality'));
  await tester.ensureVisible(queryButton);
  await tester.tap(queryButton);
    await tester.pumpAndSettle();

    expect(requestedUri?.host, 'air-quality-api.open-meteo.com');
    expect(requestedUri?.queryParameters['hourly'], 'pm2_5');
    expect(requestedUri?.queryParameters['timezone'], 'America/Bogota');
    expect(find.text('20.0 μg/m³'), findsOneWidget);
    expect(find.byKey(const ValueKey('exposure-index')), findsOneWidget);
    expect(find.text('Riesgo Bajo'), findsOneWidget);
  });
}
