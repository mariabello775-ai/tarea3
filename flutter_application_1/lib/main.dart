import 'package:flutter/material.dart';

import 'air_quality_page.dart';
import 'air_quality_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key, AirQualityService? service})
    : service = service ?? AirQualityService();

  final AirQualityService service;

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF145447);
    return MaterialApp(
      title: 'Aire local',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: forest,
          brightness: Brightness.light,
          primary: forest,
          surface: const Color(0xFFF5F6F1),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F6F1),
          foregroundColor: Color(0xFF173B34),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9DED6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9DED6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: forest, width: 1.5),
          ),
        ),
      ),
      home: AirQualityPage(service: service),
    );
  }
}
