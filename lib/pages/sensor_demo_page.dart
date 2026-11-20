import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorDemoPage extends StatefulWidget {
  const SensorDemoPage({super.key});

  @override
  State<SensorDemoPage> createState() => _SensorDemoPageState();
}

class _SensorDemoPageState extends State<SensorDemoPage> {
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  Timer? _startupTimer;
  UserAccelerometerEvent? _reading;
  Object? _sensorError;

  @override
  void initState() {
    super.initState();
    _listenToSensor();
  }

  void _listenToSensor() {
    try {
      _startupTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted || _reading != null || _sensorError != null) return;
        setState(() {
          _sensorError = StateError(
            'Tidak ada pembacaan accelerometer. Pastikan perangkat memiliki sensor.',
          );
        });
      });
      _subscription =
          userAccelerometerEventStream(
            samplingPeriod: SensorInterval.normalInterval,
          ).listen(
            (event) {
              if (!mounted) return;
              _startupTimer?.cancel();
              setState(() {
                _reading = event;
                _sensorError = null;
              });
            },
            onError: (Object error) {
              if (!mounted) return;
              setState(() => _sensorError = error);
            },
            onDone: () {
              if (!mounted || _sensorError != null) return;
              setState(() {
                _sensorError = StateError('Stream sensor telah berhenti.');
              });
            },
            cancelOnError: false,
          );
    } on Object catch (error) {
      _sensorError = error;
    }
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Accelerometer')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gerak Perangkat',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Data user accelerometer diperbarui langsung.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_sensorError != null)
            _SensorUnavailable(error: _sensorError!)
          else ...[
            _AxisReading(
              axis: 'X',
              description: 'Kiri ↔ Kanan',
              value: _reading?.x,
              icon: Icons.swap_horiz_rounded,
            ),
            const SizedBox(height: 12),
            _AxisReading(
              axis: 'Y',
              description: 'Atas ↔ Bawah',
              value: _reading?.y,
              icon: Icons.swap_vert_rounded,
            ),
            const SizedBox(height: 12),
            _AxisReading(
              axis: 'Z',
              description: 'Depan ↔ Belakang',
              value: _reading?.z,
              icon: Icons.screen_rotation_alt_rounded,
            ),
            if (_reading == null) ...[
              const SizedBox(height: 20),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Menunggu pembacaan sensor...'),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nilai diukur dalam m/s². Coba gerakkan perangkat untuk melihat perubahan pada setiap sumbu.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisReading extends StatelessWidget {
  const _AxisReading({
    required this.axis,
    required this.description,
    required this.value,
    required this.icon,
  });

  final String axis;
  final String description;
  final double? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1D4ED8)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sumbu $axis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Text(
              value?.toStringAsFixed(2) ?? '--',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF1D4ED8),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'm/s²',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorUnavailable extends StatelessWidget {
  const _SensorUnavailable({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.sensors_off_rounded,
              size: 44,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            Text(
              'Sensor tidak tersedia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Perangkat atau emulator ini tidak dapat memberikan data accelerometer.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
