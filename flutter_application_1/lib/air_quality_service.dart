import 'dart:convert';

import 'package:http/http.dart' as http;

class CityLocation {
  const CityLocation({
    required this.name,
    required this.department,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String department;
  final double latitude;
  final double longitude;
}

const colombianCities = [
  CityLocation(name: 'Bogotá', department: 'Cundinamarca', latitude: 4.61, longitude: -74.08),
  CityLocation(name: 'Medellín', department: 'Antioquia', latitude: 6.25, longitude: -75.56),
  CityLocation(name: 'Cali', department: 'Valle del Cauca', latitude: 3.45, longitude: -76.53),
  CityLocation(name: 'Barranquilla', department: 'Atlántico', latitude: 10.98, longitude: -74.80),
  CityLocation(name: 'Cartagena', department: 'Bolívar', latitude: 10.39, longitude: -75.51),
  CityLocation(name: 'Bucaramanga', department: 'Santander', latitude: 7.12, longitude: -73.12),
  CityLocation(name: 'Pereira', department: 'Risaralda', latitude: 4.81, longitude: -75.69),
  CityLocation(name: 'Santa Marta', department: 'Magdalena', latitude: 11.24, longitude: -74.20),
  CityLocation(name: 'Manizales', department: 'Caldas', latitude: 5.07, longitude: -75.52),
  CityLocation(name: 'Pasto', department: 'Nariño', latitude: 1.21, longitude: -77.28),
  CityLocation(name: 'Cúcuta', department: 'Norte de Santander', latitude: 7.89, longitude: -72.50),
  CityLocation(name: 'Villavicencio', department: 'Meta', latitude: 4.15, longitude: -73.64),
];

class DailyAirQuality {
  const DailyAirQuality({required this.averagePm25, required this.sampleCount});

  final double averagePm25;
  final int sampleCount;
}

enum ExposureRisk { low, moderate, high }

double calculateExposureIndex(double averagePm25, double outdoorHours) =>
    averagePm25 * outdoorHours;

ExposureRisk classifyExposure(double index) {
  if (index < 100) return ExposureRisk.low;
  if (index <= 200) return ExposureRisk.moderate;
  return ExposureRisk.high;
}

class AirQualityException implements Exception {
  const AirQualityException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AirQualityService {
  AirQualityService({http.Client? client}) : _client = client ?? http.Client();

  static final _endpoint = Uri.parse(
    'https://air-quality-api.open-meteo.com/v1/air-quality',
  );

  final http.Client _client;

  Future<DailyAirQuality> getDailyAverage(
    CityLocation city,
    DateTime date,
  ) async {
    final day = _formatDate(date);
    final uri = _endpoint.replace(
      queryParameters: {
        'latitude': city.latitude.toString(),
        'longitude': city.longitude.toString(),
        'hourly': 'pm2_5',
        'start_date': day,
        'end_date': day,
        'timezone': 'America/Bogota',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw AirQualityException(
        'Open-Meteo respondió con el código ${response.statusCode}. Inténtalo de nuevo más tarde.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AirQualityException('La respuesta del servicio no tiene el formato esperado.');
    }
    if (decoded['error'] == true) {
      throw AirQualityException(
        decoded['reason']?.toString() ?? 'El servicio no pudo procesar la consulta.',
      );
    }

    final hourly = decoded['hourly'];
    final values = hourly is Map<String, dynamic> ? hourly['pm2_5'] : null;
    if (values is! List) {
      throw const AirQualityException('No hay datos de PM2.5 para esa fecha y ciudad.');
    }

    final validReadings = values.whereType<num>().map((value) => value.toDouble()).toList();
    if (validReadings.isEmpty) {
      throw const AirQualityException('No hay lecturas de PM2.5 disponibles para ese día.');
    }

    final average = validReadings.reduce((sum, value) => sum + value) /
        validReadings.length;
    return DailyAirQuality(
      averagePm25: average,
      sampleCount: validReadings.length,
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void close() => _client.close();
}