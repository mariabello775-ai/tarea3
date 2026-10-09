import 'package:flutter/material.dart';

import 'air_quality_service.dart';

class AirQualityPage extends StatefulWidget {
  const AirQualityPage({super.key, required this.service});

  final AirQualityService service;

  @override
  State<AirQualityPage> createState() => _AirQualityPageState();
}

class _AirQualityPageState extends State<AirQualityPage> {
  CityLocation _city = colombianCities.first;
  DateTime _date = DateTime.now();
  double _exposureHours = 2;
  DailyAirQuality? _reading;
  Object? _error;
  bool _isLoading = false;

  DateTime get _firstDate => DateTime.now().subtract(const Duration(days: 92));
  DateTime get _lastDate => DateTime.now().add(const Duration(days: 4));

  Future<void> _loadReading() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _reading = null;
    });

    try {
      final reading = await widget.service.getDailyAverage(_city, _date);
      if (!mounted) return;
      setState(() => _reading = reading);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _firstDate,
      lastDate: _lastDate,
      helpText: 'Selecciona el día de consulta',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _reading = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${_date.day.toString().padLeft(2, '0')}/'
        '${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.air_rounded, size: 22),
            SizedBox(width: 9),
            Text('Aire local', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                'COLOMBIA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF65746D),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Text(
                  'Lugar y fecha',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF173B34),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CityLocation>(
                  key: const ValueKey('city-selector'),
                  initialValue: _city,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: colombianCities
                      .map(
                        (city) => DropdownMenuItem(
                          value: city,
                          child: Text('${city.name} · ${city.department}'),
                        ),
                      )
                      .toList(),
                  onChanged: (city) {
                    if (city == null) return;
                    setState(() {
                      _city = city;
                      _reading = null;
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(dateLabel),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    foregroundColor: const Color(0xFF173B34),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD9DED6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildExposureControl(),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey('query-air-quality'),
                  onPressed: _isLoading ? null : _loadReading,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.travel_explore_rounded),
                  label: Text(
                    _isLoading ? 'Consultando...' : 'Consultar calidad del aire',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: const Color(0xFF145447),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _buildError(),
                ],
                if (_reading != null) ...[
                  const SizedBox(height: 24),
                  _buildResult(_reading!),
                ],
                const SizedBox(height: 28),
                const Divider(color: Color(0xFFD9DED6)),
                const SizedBox(height: 10),
                const Text(
                  'Datos de calidad del aire: Open-Meteo · CAMS. El índice es una estimación educativa y no reemplaza recomendaciones de salud.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF65746D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF173B34),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: Color(0xFFB7D9A8), size: 19),
              SizedBox(width: 8),
              Text(
                'PM2.5  /  EXPOSICIÓN DIARIA',
                style: TextStyle(
                  color: Color(0xFFB7D9A8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            '¿Cómo está el aire\ndonde vives?',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'serif',
              fontSize: 31,
              height: 1.08,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 11),
          Text(
            'Consulta el promedio de partículas finas y estima tu exposición al aire libre.',
            style: TextStyle(color: Color(0xFFD6E2DB), fontSize: 14, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildExposureControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tiempo al aire libre',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF173B34),
              ),
            ),
            Text(
              '${_exposureHours.toStringAsFixed(_exposureHours % 1 == 0 ? 0 : 1)} h',
              key: const ValueKey('exposure-hours'),
              style: const TextStyle(
                color: Color(0xFF145447),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          key: const ValueKey('exposure-slider'),
          value: _exposureHours,
          min: 0,
          max: 24,
          divisions: 48,
          label: '${_exposureHours.toStringAsFixed(1)} horas',
          onChanged: (value) => setState(() => _exposureHours = value),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 h', style: TextStyle(fontSize: 11, color: Color(0xFF65746D))),
              Text('24 h', style: TextStyle(fontSize: 11, color: Color(0xFF65746D))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    final message = _error is AirQualityException
        ? (_error as AirQualityException).message
        : 'No fue posible consultar los datos. Revisa tu conexión e inténtalo de nuevo.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF9B3826)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF742D20), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(DailyAirQuality reading) {
    final index = calculateExposureIndex(reading.averagePm25, _exposureHours);
    final risk = classifyExposure(index);
    final riskColor = switch (risk) {
      ExposureRisk.low => const Color(0xFF24704E),
      ExposureRisk.moderate => const Color(0xFF9B5A16),
      ExposureRisk.high => const Color(0xFFAA3E2D),
    };
    final riskBackground = switch (risk) {
      ExposureRisk.low => const Color(0xFFE4F1E6),
      ExposureRisk.moderate => const Color(0xFFFFEED6),
      ExposureRisk.high => const Color(0xFFFFE5DE),
    };
    final riskLabel = switch (risk) {
      ExposureRisk.low => 'Bajo',
      ExposureRisk.moderate => 'Moderado',
      ExposureRisk.high => 'Alto',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD9DED6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ÍNDICE DE EXPOSICIÓN',
                      style: TextStyle(
                        color: Color(0xFF65746D),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      index.toStringAsFixed(1),
                      key: const ValueKey('exposure-index'),
                      style: const TextStyle(
                        color: Color(0xFF173B34),
                        fontFamily: 'serif',
                        fontSize: 42,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: riskBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Riesgo $riskLabel',
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE6E9E3)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultMetric(
                  label: 'PROMEDIO PM2.5',
                  value: '${reading.averagePm25.toStringAsFixed(1)} μg/m³',
                ),
              ),
              Expanded(
                child: _ResultMetric(
                  label: 'LECTURAS HORARIAS',
                  value: '${reading.sampleCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Cálculo: ${reading.averagePm25.toStringAsFixed(1)} μg/m³ × ${_exposureHours.toStringAsFixed(1)} h',
            style: const TextStyle(color: Color(0xFF65746D), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF65746D),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF173B34),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}