import 'dart:convert';
import 'package:http/http.dart' as http;

class SensorReading {
  final double sensorValue;
  final String prediction;
  final double anomalyScore;
  final bool alertActive;
  final int consecutiveAbnormalSamples;

  SensorReading({
    required this.sensorValue,
    required this.prediction,
    required this.anomalyScore,
    required this.alertActive,
    required this.consecutiveAbnormalSamples,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      sensorValue: (json['sensor_value'] ?? 0).toDouble(),
      prediction: json['prediction'] ?? 'No Leak',
      anomalyScore: (json['anomaly_score'] ?? 0).toDouble(),
      alertActive: json['alert_active'] ?? false,
      consecutiveAbnormalSamples: json['consecutive_abnormal_samples'] ?? 0,
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<SensorReading> getLatestReading() async {
    final response = await http.get(Uri.parse('$baseUrl/latest-reading'));

    if (response.statusCode == 200) {
      return SensorReading.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load latest reading');
    }
  }
}