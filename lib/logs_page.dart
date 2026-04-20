import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final TextEditingController _searchController = TextEditingController();

  DateTime selectedFrom = DateTime.now().subtract(const Duration(days: 7));
  DateTime selectedTo = DateTime.now();
  String selectedSeverity = 'All Severities';

  bool isLoading = true;
  String? errorMessage;

  final String baseUrl = 'http://10.0.2.2:8000';

  List<LogEvent> allEvents = [];

  @override
  void initState() {
    super.initState();
    fetchLogs();
  }

  Future<void> fetchLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/logs'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        setState(() {
          allEvents = data.map((e) => LogEvent.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load logs';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection error: $e';
        isLoading = false;
      });
    }
  }

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

      final eventDate = DateTime.tryParse(event.timestamp);
      final matchesDate = eventDate == null ||
          (!eventDate.isBefore(DateTime(
            selectedFrom.year,
            selectedFrom.month,
            selectedFrom.day,
          )) &&
              !eventDate.isAfter(DateTime(
                selectedTo.year,
                selectedTo.month,
                selectedTo.day,
                23,
                59,
                59,
              )));

      return matchesSeverity && matchesSearch && matchesDate;
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

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF08111D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF16D0BC)),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF08111D),
        body: Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

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
                      SummaryCard(
                        events: filteredEvents,
                        onDownloadCsv: _downloadCsv,
                      ),
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
                        child: SummaryCard(
                          events: filteredEvents,
                          onDownloadCsv: _downloadCsv,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LogsTableCard(events: filteredEvents),
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

  LogEvent({
    required this.timestamp,
    required this.status,
    required this.severity,
    required this.confidence,
    required this.notes,
  });

  factory LogEvent.fromJson(Map<String, dynamic> json) {
    return LogEvent(
      timestamp: json['timestamp'] ?? '',
      status: json['status'] ?? '',
      severity: json['severity'] ?? '',
      confidence: json['confidence'] ?? 0,
      notes: json['notes'] ?? '',
    );
  }
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
          label: const Text('Back'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF2A4258)),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detection Logs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Historical methane detection records',
                style: TextStyle(
                  color: Color(0xFF8FA7BD),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LogsHeaderMobile extends StatelessWidget {
  const LogsHeaderMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detection Logs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Historical methane detection records',
          style: TextStyle(
            color: Color(0xFF8FA7BD),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    final content = [
      _dateButton('From', selectedFrom, onFromTap),
      _dateButton('To', selectedTo, onToTap),
      _severityDropdown(),
      _searchField(),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101D31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: isMobile
          ? Column(
        children: content
            .map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: e,
        ))
            .toList(),
      )
          : Row(
        children: [
          Expanded(child: content[0]),
          const SizedBox(width: 12),
          Expanded(child: content[1]),
          const SizedBox(width: 12),
          Expanded(child: content[2]),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: content[3]),
        ],
      ),
    );
  }

  Widget _dateButton(String label, DateTime value, VoidCallback onTap) {
    final text =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF2A4258)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text('$label: $text')),
        ],
      ),
    );
  }

  Widget _severityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2A4258)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF101D31),
          value: selectedSeverity,
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
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
            DropdownMenuItem(
              value: 'High',
              child: Text('High'),
            ),
          ],
          onChanged: onSeverityChanged,
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search logs',
        hintStyle: const TextStyle(color: Color(0xFF8FA7BD)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF8FA7BD)),
        filled: true,
        fillColor: const Color(0xFF08111D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A4258)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A4258)),
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
    final total = events.length;
    final leakCount = events.where((e) => e.status.toLowerCase().contains('leak')).length;
    final safeCount = total - leakCount;

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
            'Trend Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _miniBox('Total Events', total.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniBox('Leak Events', leakCount.toString()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniBox('Safe Events', safeCount.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF08111D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8FA7BD),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final List<LogEvent> events;
  final VoidCallback onDownloadCsv;

  const SummaryCard({
    super.key,
    required this.events,
    required this.onDownloadCsv,
  });

  @override
  Widget build(BuildContext context) {
    final totalEvents = events.length;
    final avgConfidence = totalEvents == 0
        ? 0
        : (events.map((e) => e.confidence).reduce((a, b) => a + b) / totalEvents)
        .round();

    final leakEvents =
        events.where((e) => e.status.toLowerCase().contains('leak')).length;

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
          SummaryMiniCard(
            icon: Icons.show_chart_rounded,
            title: 'Total Events',
            value: '$totalEvents',
            subtitle: 'Filtered results',
          ),
          const SizedBox(height: 14),
          SummaryMiniCard(
            icon: Icons.analytics_outlined,
            title: 'Avg. Confidence',
            value: '$avgConfidence%',
            subtitle: 'Model output',
          ),
          const SizedBox(height: 14),
          SummaryMiniCard(
            icon: Icons.warning_amber_rounded,
            title: 'Leak Events',
            value: '$leakEvents',
            subtitle: 'Detected',
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8FA7BD),
                    fontSize: 11,
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

class LogsTableCard extends StatelessWidget {
  final List<LogEvent> events;

  const LogsTableCard({super.key, required this.events});

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
            'Event Table',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFF22394E)),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF08111D),
              ),
              dataRowColor: WidgetStateProperty.all(
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
    final isLeak = text.toLowerCase().contains('leak');
    final color = isLeak ? Colors.orangeAccent : const Color(0xFF0AAE8F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
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
    Color color;
    if (text == 'High') {
      color = Colors.redAccent;
    } else if (text == 'Medium') {
      color = Colors.orangeAccent;
    } else {
      color = const Color(0xFF16D0BC);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}