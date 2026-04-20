import 'package:flutter/material.dart';

class DetectionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetectionDetailsPage({super.key, required this.data});

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status']?.toString() ?? 'Unknown';
    final severity = data['severity']?.toString() ?? 'Low';
    final reading = (data['sensor_reading'] ?? 0).toDouble();
    final leakProbability = data['leak_probability'] ?? 0;
    final confidence = data['confidence'] ?? 0;
    final anomalyScore = (data['anomaly_score'] ?? 0).toDouble();
    final dropPercentage = (data['drop_percentage'] ?? 0).toDouble();
    final responseTime = data['response_time_ms'] ?? 0;
    final abnormalSamples = data['consecutive_abnormal_samples'] ?? 0;
    final sensorId = data['sensor_id']?.toString() ?? '';
    final timestamp = data['timestamp']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF08111D),
      appBar: AppBar(
        title: const Text('Detection Details'),
        backgroundColor: const Color(0xFF08111D),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('Status', status),
          _tile('Sensor ID', sensorId),
          _tile('Timestamp', timestamp),
          _tile('Sensor Reading', '${reading.toStringAsFixed(3)} V'),
          _tile('Severity', severity, valueColor: _severityColor(severity)),
          _tile('Leak Probability', '$leakProbability%'),
          _tile('Confidence', '$confidence%'),
          _tile('Anomaly Score', anomalyScore.toStringAsFixed(2)),
          _tile('Drop Percentage', '${dropPercentage.toStringAsFixed(2)}%'),
          _tile('Response Time', '$responseTime ms'),
          _tile('Consecutive Abnormal Samples', '$abnormalSamples'),
        ],
      ),
    );
  }

  Widget _tile(String title, String value, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF102235),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}