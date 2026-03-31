import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final TextEditingController _searchController = TextEditingController();

  DateTime selectedFrom = DateTime(2026, 2, 2);
  DateTime selectedTo = DateTime(2026, 2, 2);
  String selectedSeverity = 'All Severities';

  final List<LogEvent> allEvents = [
    LogEvent(
      timestamp: '2026-02-02 14:23:15',
      status: 'No Leak',
      severity: 'Low',
      confidence: 92,
      notes: 'Sensor calibration drift detected',
    ),
    LogEvent(
      timestamp: '2026-02-02 12:45:30',
      status: 'No Leak',
      severity: 'Medium',
      confidence: 78,
      notes: 'CH₄ concentration spike (resolved)',
    ),
    LogEvent(
      timestamp: '2026-02-02 09:12:08',
      status: 'No Leak',
      severity: 'Low',
      confidence: 88,
      notes: 'Minor signal attenuation anomaly',
    ),
    LogEvent(
      timestamp: '2026-02-01 18:34:22',
      status: 'No Leak',
      severity: 'Low',
      confidence: 95,
      notes: 'Routine monitoring checkpoint',
    ),
    LogEvent(
      timestamp: '2026-02-01 14:15:44',
      status: 'No Leak',
      severity: 'Low',
      confidence: 91,
      notes: 'Background fluctuation within tolerance',
    ),
    LogEvent(
      timestamp: '2026-02-01 09:42:17',
      status: 'No Leak',
      severity: 'Low',
      confidence: 89,
      notes: 'System self-test completed',
    ),
    LogEvent(
      timestamp: '2026-01-31 22:18:55',
      status: 'No Leak',
      severity: 'Low',
      confidence: 94,
      notes: 'Normal operation confirmed',
    ),
    LogEvent(
      timestamp: '2026-01-31 16:05:33',
      status: 'No Leak',
      severity: 'Medium',
      confidence: 82,
      notes: 'Environmental temperature variation',
    ),
  ];

  List<LogEvent> get filteredEvents {
    return allEvents.where((event) {
      final matchesSeverity = selectedSeverity == 'All Severities' ||
          event.severity == selectedSeverity;

      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          event.notes.toLowerCase().contains(query) ||
          event.timestamp.toLowerCase().contains(query) ||
          event.status.toLowerCase().contains(query) ||
          event.severity.toLowerCase().contains(query);

      return matchesSeverity && matchesSearch;
    }).toList();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initialDate = isFrom ? selectedFrom : selectedTo;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF16D0BC),
              surface: Color(0xFF101D31),
            ),
            dialogBackgroundColor: const Color(0xFF101D31),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          selectedFrom = picked;
        } else {
          selectedTo = picked;
        }
      });
    }
  }

  Future<void> _downloadCsv() async {
    try {
      final rows = <List<String>>[
        ['Timestamp', 'Status', 'Severity', 'Confidence', 'Notes'],
        ...filteredEvents.map(
              (e) => [
            e.timestamp,
            e.status,
            e.severity,
            '${e.confidence}%',
            e.notes,
          ],
        ),
      ];

      final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/methaneguard_logs.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'MethaneGuard logs CSV',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV export failed: $e')),
      );
    }
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 950;

    return Scaffold(
      backgroundColor: const Color(0xFF08111D),
      body: Stack(
        children: [
          const Positioned.fill(child: LogsGridBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isMobile
                      ? const LogsHeaderMobile()
                      : const LogsHeaderDesktop(),
                  const SizedBox(height: 24),
                  LogsFilterBar(
                    selectedFrom: selectedFrom,
                    selectedTo: selectedTo,
                    selectedSeverity: selectedSeverity,
                    searchController: _searchController,
                    onFromTap: () => _pickDate(isFrom: true),
                    onToTap: () => _pickDate(isFrom: false),
                    onSeverityChanged: (value) {
                      setState(() {
                        selectedSeverity = value!;
                      });
                    },
                    onSearchChanged: (_) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  isMobile
                      ? Column(
                    children: [
                      TrendAnalysisCard(events: filteredEvents),
                      const SizedBox(height: 20),
                      SummaryCard(onDownloadCsv: _downloadCsv),
                    ],
                  )
                      : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TrendAnalysisCard(events: filteredEvents),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SummaryCard(onDownloadCsv: _downloadCsv),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  EventLogCard(events: filteredEvents),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LogEvent {
  final String timestamp;
  final String status;
  final String severity;
  final int confidence;
  final String notes;

  const LogEvent({
    required this.timestamp,
    required this.status,
    required this.severity,
    required this.confidence,
    required this.notes,
  });
}

class LogsGridBackground extends StatelessWidget {
  const LogsGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF08111D),
      child: CustomPaint(
        painter: LogsGridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class LogsGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF143149).withOpacity(0.28)
      ..strokeWidth = 1;

    const spacing = 32.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LogsHeaderDesktop extends StatelessWidget {
  const LogsHeaderDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Overview'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF2A4258)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logs & Visualization',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Historical data and event tracking',
              style: TextStyle(
                color: Color(0xFF8AA6BF),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class LogsHeaderMobile extends StatelessWidget {
  const LogsHeaderMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Overview'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF2A4258)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Logs & Visualization',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Historical data and event tracking',
          style: TextStyle(
            color: Color(0xFF8AA6BF),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class LogsFilterBar extends StatelessWidget {
  final DateTime selectedFrom;
  final DateTime selectedTo;
  final String selectedSeverity;
  final TextEditingController searchController;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final ValueChanged<String?> onSeverityChanged;
  final ValueChanged<String> onSearchChanged;

  const LogsFilterBar({
    super.key,
    required this.selectedFrom,
    required this.selectedTo,
    required this.selectedSeverity,
    required this.searchController,
    required this.onFromTap,
    required this.onToTap,
    required this.onSeverityChanged,
    required this.onSearchChanged,
  });

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 950;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: isMobile
          ? Column(
        children: [
          _DateField(
            label: formatDate(selectedFrom),
            onTap: onFromTap,
          ),
          const SizedBox(height: 12),
          _DateField(
            label: formatDate(selectedTo),
            onTap: onToTap,
          ),
          const SizedBox(height: 12),
          _SeverityDropdown(
            value: selectedSeverity,
            onChanged: onSeverityChanged,
          ),
          const SizedBox(height: 12),
          _SearchField(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _DateField(
              label: formatDate(selectedFrom),
              onTap: onFromTap,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'to',
            style: TextStyle(
              color: Color(0xFF8AA6BF),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DateField(
              label: formatDate(selectedTo),
              onTap: onToTap,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 170,
            child: _SeverityDropdown(
              value: selectedSeverity,
              onChanged: onSeverityChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF08111D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A3550)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _SeverityDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF08111D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF101D31),
          value: value,
          isExpanded: true,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: const [
            DropdownMenuItem(
              value: 'All Severities',
              child: Text('All Severities'),
            ),
            DropdownMenuItem(
              value: 'Low',
              child: Text('Low'),
            ),
            DropdownMenuItem(
              value: 'Medium',
              child: Text('Medium'),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search events...',
        hintStyle: const TextStyle(color: Color(0xFF7D93A8)),
        filled: true,
        fillColor: const Color(0xFF08111D),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A3550)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1A3550)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF16D0BC)),
        ),
      ),
    );
  }
}

class TrendAnalysisCard extends StatelessWidget {
  final List<LogEvent> events;

  const TrendAnalysisCard({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101D31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signal Trend Analysis',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '24-hour monitoring period with event markers',
                      style: TextStyle(
                        color: Color(0xFF8AA6BF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A4258)),
                ),
                child: const Text(
                  'Real-time',
                  style: TextStyle(
                    color: Color(0xFFD6DFE8),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 340,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF08111D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: CustomPaint(
              painter: LogsChartPainter(),
              child: Container(),
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _LegendItem(
                color: Color(0xFF16D0BC),
                text: 'Normal Reading',
              ),
              _LegendItem(
                color: Color(0xFFFFB020),
                text: 'Low Severity Event',
              ),
              _LegendItem(
                color: Color(0xFFFF9800),
                text: 'Medium Severity Event',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9CB3C7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class LogsChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 48.0;
    const bottomPadding = 32.0;
    const topPadding = 14.0;
    const rightPadding = 16.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final axisPaint = Paint()
      ..color = const Color(0xFF53657A)
      ..strokeWidth = 1.2;

    final gridPaint = Paint()
      ..color = const Color(0xFF1A3550)
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = const Color(0xFF16D0BC)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = const Color(0xFF16D0BC)
      ..style = PaintingStyle.fill;

    final lowEventPaint = Paint()
      ..color = const Color(0xFFFFB020)
      ..style = PaintingStyle.fill;

    final mediumEventPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..style = PaintingStyle.fill;

    final thresholdPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 1.5;

    const axisTextStyle = TextStyle(
      color: Color(0xFF8FA7BD),
      fontSize: 11,
    );

    final xLabels = [
      '00:00',
      '04:00',
      '08:00',
      '10:00',
      '12:45',
      '14:23',
      '18:00',
      '22:00'
    ];

    final yLabels = [0, 2, 4, 6];

    final points = [
      const Offset(0, 2.1),
      const Offset(1, 2.2),
      const Offset(2, 2.4),
      const Offset(3, 2.3),
      const Offset(4, 2.5),
      const Offset(5, 3.8),
      const Offset(6, 2.4),
      const Offset(7, 2.3),
      const Offset(8, 4.2),
      const Offset(9, 2.6),
      const Offset(10, 3.1),
      const Offset(11, 2.4),
      const Offset(12, 2.5),
      const Offset(13, 2.3),
      const Offset(14, 2.4),
    ];

    double mapX(double x) => leftPadding + (x / 14.0) * chartWidth;
    double mapY(double y) => topPadding + chartHeight - (y / 6.0) * chartHeight;

    for (final y in yLabels) {
      final py = mapY(y.toDouble());
      canvas.drawLine(
        Offset(leftPadding, py),
        Offset(leftPadding + chartWidth, py),
        gridPaint,
      );
      final tp = TextPainter(
        text: TextSpan(text: y.toString(), style: axisTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 8, py - tp.height / 2));
    }

    for (int i = 0; i < xLabels.length; i++) {
      final px = leftPadding + (i / (xLabels.length - 1)) * chartWidth;
      canvas.drawLine(
        Offset(px, topPadding),
        Offset(px, topPadding + chartHeight),
        gridPaint,
      );
      final tp = TextPainter(
        text: TextSpan(text: xLabels[i], style: axisTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, topPadding + chartHeight + 6));
    }

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(leftPadding + chartWidth, topPadding + chartHeight),
      axisPaint,
    );

    final thresholdY = mapY(5.0);
    canvas.drawLine(
      Offset(leftPadding, thresholdY),
      Offset(leftPadding + chartWidth, thresholdY),
      thresholdPaint,
    );

    final thresholdText = TextPainter(
      text: const TextSpan(
        text: 'Threshold',
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    thresholdText.paint(
      canvas,
      Offset(leftPadding + chartWidth / 2 - 20, thresholdY - 14),
    );

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = Offset(mapX(points[i].dx), mapY(points[i].dy));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final point = Offset(mapX(points[i].dx), mapY(points[i].dy));

      if (i == 5 || i == 10) {
        canvas.drawCircle(point, 4.5, lowEventPaint);
      } else if (i == 8) {
        canvas.drawCircle(point, 4.8, mediumEventPaint);
      } else {
        canvas.drawCircle(point, 2.5, pointPaint);
      }
    }

    final yAxisLabel = TextPainter(
      text: const TextSpan(
        text: 'CH₄ Concentration (ppm)',
        style: TextStyle(color: Color(0xFF8FA7BD), fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(10, topPadding + chartHeight / 2 + yAxisLabel.width / 2);
    canvas.rotate(-1.5708);
    yAxisLabel.paint(canvas, Offset.zero);
    canvas.restore();

    final xAxisLabel = TextPainter(
      text: const TextSpan(
        text: 'Time (24h)',
        style: TextStyle(color: Color(0xFF8FA7BD), fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    xAxisLabel.paint(
      canvas,
      Offset(
        leftPadding + chartWidth / 2 - xAxisLabel.width / 2,
        size.height - xAxisLabel.height,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SummaryCard extends StatelessWidget {
  final VoidCallback onDownloadCsv;

  const SummaryCard({
    super.key,
    required this.onDownloadCsv,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101D31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          const SummaryMiniCard(
            icon: Icons.show_chart_rounded,
            title: 'Total Events',
            value: '12',
            subtitle: 'Today',
          ),
          const SizedBox(height: 14),
          const AverageConfidenceCard(),
          const SizedBox(height: 14),
          const SummaryMiniCard(
            icon: Icons.warning_amber_rounded,
            title: 'False Alarm Rate',
            value: '0.8%',
            subtitle: 'Excellent',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDownloadCsv,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF2A4258)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryMiniCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const SummaryMiniCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF08111D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF16D0BC), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF9CB3C7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF0AAE8F),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AverageConfidenceCard extends StatelessWidget {
  const AverageConfidenceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF08111D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  color: Color(0xFF16D0BC), size: 18),
              SizedBox(width: 10),
              Text(
                'Avg Confidence',
                style: TextStyle(
                  color: Color(0xFF9CB3C7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '89.3%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: LinearProgressIndicator(
              value: 0.893,
              minHeight: 6,
              backgroundColor: Color(0xFF24384E),
              valueColor: AlwaysStoppedAnimation(Color(0xFF16D0BC)),
            ),
          ),
        ],
      ),
    );
  }
}

class EventLogCard extends StatelessWidget {
  final List<LogEvent> events;

  const EventLogCard({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF101D31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Log',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Complete detection history and system events',
                  style: TextStyle(
                    color: Color(0xFF8AA6BF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: Color(0xFF1A3550),
            height: 1,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF08111D),
              ),
              dataRowColor: MaterialStateProperty.all(
                const Color(0xFF101D31),
              ),
              columnSpacing: 36,
              headingTextStyle: const TextStyle(
                color: Color(0xFF9CB3C7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              dataTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              columns: const [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Severity')),
                DataColumn(label: Text('Confidence')),
                DataColumn(label: Text('Notes')),
              ],
              rows: events.map((event) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        event.timestamp,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(_StatusChip(text: event.status)),
                    DataCell(_SeverityChip(text: event.severity)),
                    DataCell(
                      Row(
                        children: [
                          Text('${event.confidence}%'),
                          const SizedBox(width: 8),
                          Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF24384E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 50 * (event.confidence / 100),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16D0BC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: Text(event.notes),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;

  const _StatusChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0AAE8F).withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0AAE8F),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String text;

  const _SeverityChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final isMedium = text == 'Medium';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isMedium
            ? const Color(0xFFFF9800).withOpacity(0.18)
            : const Color(0xFF0AAE8F).withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isMedium ? const Color(0xFFFF9800) : const Color(0xFF0AAE8F),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}