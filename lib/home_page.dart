import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'detection_details_page.dart';
import 'logs_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
    final query = FirebaseFirestore.instance
        .collection('detections')
        .orderBy('created_at', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFF08111D),
      appBar: AppBar(
        title: const Text('MethaneGuard'),
        backgroundColor: const Color(0xFF08111D),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No detections found',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final doc = snapshot.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          final status = data['status']?.toString() ?? 'Unknown';
          final severity = data['severity']?.toString() ?? 'Low';
          final reading = (data['sensor_reading'] ?? 0).toDouble();
          final leakProbability = data['leak_probability'] ?? 0;
          final confidence = data['confidence'] ?? 0;
          final responseTime = data['response_time_ms'] ?? 0;
          final dropPercentage = (data['drop_percentage'] ?? 0).toDouble();
          final alertActive = data['alert_active'] ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: alertActive
                      ? Colors.red.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: alertActive ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      alertActive
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      color:
                      alertActive ? Colors.redAccent : Colors.greenAccent,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card('Latest Sensor Reading', '${reading.toStringAsFixed(3)} V'),
              _card('Leak Probability', '$leakProbability%'),
              _card(
                'Severity',
                severity,
                valueColor: _severityColor(severity),
              ),
              _card('Confidence', '$confidence%'),
              _card('Response Time', '$responseTime ms'),
              _card('Drop Percentage', '${dropPercentage.toStringAsFixed(2)}%'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetectionDetailsPage(data: data),
                    ),
                  );
                },
                child: const Text('View Detection Details'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogsPage()),
                  );
                },
                child: const Text('View Full History'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(String title, String value, {Color? valueColor}) {
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
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}