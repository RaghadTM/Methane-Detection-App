import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'logs_page.dart';

class DetectionDetailsPage extends StatefulWidget {
  const DetectionDetailsPage({super.key});

  @override
  State<DetectionDetailsPage> createState() => _DetectionDetailsPageState();
}

class _DetectionDetailsPageState extends State<DetectionDetailsPage> {
  final GlobalKey _snapshotKey = GlobalKey();

  Future<void> _exportReport() async {
    try {
      final boundary =
      _snapshotKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Snapshot not ready yet')),
        );
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture snapshot')),
        );
        return;
      }

      final Uint8List imageBytes = byteData.buffer.asUint8List();

      final pdf = pw.Document();
      final snapshotImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text(
              'MethaneGuard Detection Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'AI-powered methane leak analysis',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'No Leak Detected',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'All measurements within normal operating parameters.',
                      ),
                    ],
                  ),
                  pw.Text(
                    'NORMAL',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'AI Classification Result',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Bullet(text: 'Classification: No Leak'),
            pw.Bullet(text: 'Severity Level: Low'),
            pw.Bullet(text: 'Confidence Score: 86%'),
            pw.SizedBox(height: 14),
            pw.Text(
              'Analysis Summary',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'IR absorption measurements show normal atmospheric composition. '
                  'No significant attenuation patterns detected. Signal variance remains '
                  'within expected parameters for baseline conditions.',
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Signal Snapshot',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Image(snapshotImage, fit: pw.BoxFit.contain),
          ],
        ),
      );

      final bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'methaneguard_detection_report.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _openFullHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LogsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08111D),
      body: Stack(
        children: [
          const Positioned.fill(child: DetectionGridBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 900;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isMobile
                          ? const DetectionHeaderMobile()
                          : const DetectionHeaderDesktop(),
                      const SizedBox(height: 24),
                      const DetectionStatusBanner(),
                      const SizedBox(height: 24),
                      isMobile
                          ? Column(
                        children: [
                          const AIClassificationCard(),
                          const SizedBox(height: 20),
                          ActionsCard(
                            onExportPressed: _exportReport,
                            onViewHistoryPressed: _openFullHistory,
                          ),
                        ],
                      )
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 2,
                            child: AIClassificationCard(),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ActionsCard(
                              onExportPressed: _exportReport,
                              onViewHistoryPressed: _openFullHistory,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SignalSnapshotCard(
                        repaintKey: _snapshotKey,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetectionGridBackground extends StatelessWidget {
  const DetectionGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF08111D),
      child: CustomPaint(
        painter: DetectionGridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class DetectionGridPainter extends CustomPainter {
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

class DetectionHeaderDesktop extends StatelessWidget {
  const DetectionHeaderDesktop({super.key});

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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detection Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'AI-powered methane leak analysis',
                style: TextStyle(
                  color: Color(0xFF8AA6BF),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF101D31),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1A3550)),
          ),
          child: const Text(
            'Last Updated: 9:31:45 PM',
            style: TextStyle(
              color: Color(0xFFD6DFE8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class DetectionHeaderMobile extends StatelessWidget {
  const DetectionHeaderMobile({super.key});

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
          'Detection Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'AI-powered methane leak analysis',
          style: TextStyle(
            color: Color(0xFF8AA6BF),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF101D31),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1A3550)),
          ),
          child: const Text(
            'Last Updated: 9:31:45 PM',
            style: TextStyle(
              color: Color(0xFFD6DFE8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class DetectionStatusBanner extends StatelessWidget {
  const DetectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A6C50),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF13D5A2), width: 2),
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF13D5A2),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Leak Detected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'All measurements within normal operating parameters.',
                  style: TextStyle(
                    color: Color(0xFFD4EFE7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0C8A63),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'NORMAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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

class AIClassificationCard extends StatelessWidget {
  const AIClassificationCard({super.key});

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
          const Row(
            children: [
              Icon(
                Icons.psychology_alt_outlined,
                color: Color(0xFF16D0BC),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'AI Classification Result',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 700;

              if (isSmall) {
                return const Column(
                  children: [
                    ResultMiniCard(
                      title: 'Classification',
                      value: 'No Leak',
                      tag: 'Confirmed',
                    ),
                    SizedBox(height: 12),
                    ResultMiniCard(
                      title: 'Severity Level',
                      value: 'Low',
                      tag: 'Low',
                    ),
                    SizedBox(height: 12),
                    ConfidenceCard(),
                  ],
                );
              }

              return const Row(
                children: [
                  Expanded(
                    child: ResultMiniCard(
                      title: 'Classification',
                      value: 'No Leak',
                      tag: 'Confirmed',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ResultMiniCard(
                      title: 'Severity Level',
                      value: 'Low',
                      tag: 'Low',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: ConfidenceCard()),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF08111D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A3550)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Summary',
                  style: TextStyle(
                    color: Color(0xFF9CB3C7),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'IR absorption measurements show normal atmospheric composition. No significant attenuation patterns detected. Signal variance remains within expected parameters for baseline conditions.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
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

class ResultMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final String tag;

  const ResultMiniCard({
    super.key,
    required this.title,
    required this.value,
    required this.tag,
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
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0AAE8F).withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: Color(0xFF0AAE8F),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfidenceCard extends StatelessWidget {
  const ConfidenceCard({super.key});

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
          Text(
            'Confidence Score',
            style: TextStyle(
              color: Color(0xFF9CB3C7),
              fontSize: 12,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '86%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: LinearProgressIndicator(
              value: 0.86,
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

class ActionsCard extends StatelessWidget {
  final VoidCallback onExportPressed;
  final VoidCallback onViewHistoryPressed;

  const ActionsCard({
    super.key,
    required this.onExportPressed,
    required this.onViewHistoryPressed,
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
            'Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onExportPressed,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Export Report'),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewHistoryPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF2A4258)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('View Full History'),
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: const Color(0xFF22394E)),
          const SizedBox(height: 20),
          const Text(
            'Detection Method',
            style: TextStyle(
              color: Color(0xFF9CB3C7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          const DetectionMethodItem(text: 'Infrared Spectroscopy'),
          const SizedBox(height: 8),
          const DetectionMethodItem(text: 'Neural Network Analysis'),
          const SizedBox(height: 8),
          const DetectionMethodItem(text: 'Real-time Processing'),
        ],
      ),
    );
  }
}

class DetectionMethodItem extends StatelessWidget {
  final String text;

  const DetectionMethodItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 7, color: Color(0xFF16D0BC)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class SignalSnapshotCard extends StatefulWidget {
  final GlobalKey repaintKey;

  const SignalSnapshotCard({
    super.key,
    required this.repaintKey,
  });

  @override
  State<SignalSnapshotCard> createState() => _SignalSnapshotCardState();
}

class _SignalSnapshotCardState extends State<SignalSnapshotCard> {
  final List<Offset> points = const [
    Offset(0, 2.05),
    Offset(5, 2.25),
    Offset(10, 2.15),
    Offset(15, 2.38),
    Offset(20, 2.48),
    Offset(25, 2.25),
    Offset(30, 2.38),
    Offset(35, 2.58),
    Offset(40, 2.38),
    Offset(45, 2.25),
    Offset(50, 2.48),
    Offset(55, 2.15),
    Offset(60, 2.38),
  ];

  int? selectedIndex;

  void _handleTouch(Offset localPosition, Size size) {
    const leftPadding = 48.0;
    const rightPadding = 12.0;
    final chartWidth = size.width - leftPadding - rightPadding;

    if (localPosition.dx < leftPadding ||
        localPosition.dx > leftPadding + chartWidth) {
      setState(() {
        selectedIndex = null;
      });
      return;
    }

    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < points.length; i++) {
      final pointX = leftPadding + (points[i].dx / 60.0) * chartWidth;
      final distance = (localPosition.dx - pointX).abs();

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    setState(() {
      selectedIndex = nearestIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.repaintKey,
      child: Container(
        width: double.infinity,
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
                        'Signal Snapshot',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'IR absorption intensity over time (last 60 seconds)',
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
                    'CH₄ @ 7.66 µm',
                    style: TextStyle(
                      color: Color(0xFFD6DFE8),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartSize = Size(constraints.maxWidth - 32, 360);

                return Container(
                  height: 360,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF08111D),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      _handleTouch(details.localPosition, chartSize);
                    },
                    onHorizontalDragUpdate: (details) {
                      _handleTouch(details.localPosition, chartSize);
                    },
                    onLongPressStart: (details) {
                      _handleTouch(details.localPosition, chartSize);
                    },
                    child: CustomPaint(
                      size: chartSize,
                      painter: SignalChartPainter(
                        points: points,
                        selectedIndex: selectedIndex,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.circle, size: 10, color: Color(0xFF16D0BC)),
                SizedBox(width: 8),
                Text(
                  'Signal Intensity',
                  style: TextStyle(color: Color(0xFF9CB3C7), fontSize: 12),
                ),
                SizedBox(width: 20),
                SizedBox(
                  width: 24,
                  child: Divider(color: Colors.red, thickness: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Safety Threshold (5.0 ppm)',
                  style: TextStyle(color: Color(0xFF9CB3C7), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SignalChartPainter extends CustomPainter {
  final List<Offset> points;
  final int? selectedIndex;

  SignalChartPainter({
    required this.points,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 48.0;
    const bottomPadding = 32.0;
    const topPadding = 14.0;
    const rightPadding = 12.0;

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

    final thresholdPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 1.5;

    const axisTextStyle = TextStyle(
      color: Color(0xFF8FA7BD),
      fontSize: 11,
    );

    final yLabels = [0.0, 0.65, 1.3, 1.95, 2.6];
    final xLabels = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60];

    double mapX(double x) => leftPadding + (x / 60.0) * chartWidth;
    double mapY(double y) =>
        topPadding + chartHeight - (y / 2.7) * chartHeight;

    for (final y in yLabels) {
      final py = mapY(y);
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

    for (final x in xLabels) {
      final px = mapX(x.toDouble());
      canvas.drawLine(
        Offset(px, topPadding),
        Offset(px, topPadding + chartHeight),
        gridPaint,
      );
      final tp = TextPainter(
        text: TextSpan(text: x.toString(), style: axisTextStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(px - tp.width / 2, topPadding + chartHeight + 6),
      );
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

    final thresholdY = mapY(2.55);
    canvas.drawLine(
      Offset(leftPadding, thresholdY),
      Offset(leftPadding + chartWidth, thresholdY),
      thresholdPaint,
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

    for (final p in points) {
      final point = Offset(mapX(p.dx), mapY(p.dy));
      canvas.drawCircle(point, 3.5, pointPaint);
    }

    if (selectedIndex != null) {
      final selected = points[selectedIndex!];
      final selectedPoint = Offset(mapX(selected.dx), mapY(selected.dy));

      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.75)
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(selectedPoint.dx, topPadding),
        Offset(selectedPoint.dx, topPadding + chartHeight),
        highlightPaint,
      );

      canvas.drawCircle(
        selectedPoint,
        4.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(selectedPoint, 3.2, pointPaint);

      double tooltipX = selectedPoint.dx + 8;
      double tooltipY = selectedPoint.dy + 18;

      if (tooltipX + 76 > size.width) {
        tooltipX = selectedPoint.dx - 84;
      }

      if (tooltipY + 62 > size.height) {
        tooltipY = selectedPoint.dy - 70;
      }

      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, 76, 62),
        const Radius.circular(10),
      );

      canvas.drawRRect(
        tooltipRect,
        Paint()..color = const Color(0xFF1A2B44),
      );

      final tp1 = TextPainter(
        text: TextSpan(
          text: selected.dx.toInt().toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final tp2 = TextPainter(
        text: TextSpan(
          text: 'signal : ${selected.dy.toStringAsFixed(1)}',
          style: const TextStyle(color: Color(0xFF16D0BC), fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp1.paint(canvas, Offset(tooltipX + 10, tooltipY + 14));
      tp2.paint(canvas, Offset(tooltipX + 10, tooltipY + 32));
    }

    final yAxisLabel = TextPainter(
      text: const TextSpan(
        text: 'Signal Intensity (pt)',
        style: TextStyle(color: Color(0xFF8FA7BD), fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(12, topPadding + chartHeight / 2 + yAxisLabel.width / 2);
    canvas.rotate(-1.5708);
    yAxisLabel.paint(canvas, Offset.zero);
    canvas.restore();

    final xAxisLabel = TextPainter(
      text: const TextSpan(
        text: 'Time (seconds)',
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
  bool shouldRepaint(covariant SignalChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.points != points;
  }
}