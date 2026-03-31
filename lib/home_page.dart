import 'package:flutter/material.dart';
import 'detection_details_page.dart';
import 'logs_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08111D),
      body: Stack(
        children: [
          const Positioned.fill(child: GridBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                if (width < 700) {
                  return const MobileHomeLayout();
                } else if (width < 1100) {
                  return const TabletHomeLayout();
                } else {
                  return const DesktopHomeLayout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MobileHomeLayout extends StatelessWidget {
  const MobileHomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TopHeader(isMobile: true),
          SizedBox(height: 16),
          StatusBanner(isMobile: true),
          SizedBox(height: 16),
          ResponsiveInfoCards(columns: 1),
          SizedBox(height: 16),
          RecentAlertsCard(),
          SizedBox(height: 16),
          QuickActionsCard(),
        ],
      ),
    );
  }
}

class TabletHomeLayout extends StatelessWidget {
  const TabletHomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          TopHeader(),
          SizedBox(height: 20),
          StatusBanner(),
          SizedBox(height: 20),
          ResponsiveInfoCards(columns: 2),
          SizedBox(height: 20),
          RecentAlertsCard(),
          SizedBox(height: 20),
          QuickActionsCard(),
        ],
      ),
    );
  }
}

class DesktopHomeLayout extends StatelessWidget {
  const DesktopHomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const TopHeader(),
          const SizedBox(height: 22),
          const StatusBanner(),
          const SizedBox(height: 24),
          const ResponsiveInfoCards(columns: 4),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(flex: 2, child: RecentAlertsCard()),
              SizedBox(width: 20),
              Expanded(child: QuickActionsCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class ResponsiveInfoCards extends StatelessWidget {
  final int columns;

  const ResponsiveInfoCards({super.key, required this.columns});

  @override
  Widget build(BuildContext context) {
    final cards = const [
      InfoCard(
        icon: Icons.show_chart_rounded,
        title: 'Latest Sensor Reading',
        value: '2.34 ppm',
        subtitle: 'IR Absorption Line',
      ),
      InfoCard(
        icon: Icons.trending_up_rounded,
        title: 'Leak Probability',
        value: '2.8%',
        subtitle: 'Below Threshold',
      ),
      InfoCard(
        icon: Icons.warning_amber_rounded,
        title: 'Severity Level',
        value: 'Low',
        subtitle: 'Current Assessment',
      ),
      InfoCard(
        icon: Icons.access_time_rounded,
        title: 'Response Time',
        value: '0.42s',
        subtitle: 'Optimal',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const spacing = 16.0;
        final itemWidth = (totalWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
              width: itemWidth,
              child: card,
            ),
          )
              .toList(),
        );
      },
    );
  }
}

class GridBackground extends StatelessWidget {
  const GridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF08111D),
      child: CustomPaint(
        painter: GridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
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

class TopHeader extends StatelessWidget {
  final bool isMobile;

  const TopHeader({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF14C8B0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MethaneGuard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Industrial Leak Detection System',
                      style: TextStyle(
                        color: Color(0xFF8AA6BF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Mar 31, 2026, 07:51:45 PM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0AAE8F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF14C8B0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.show_chart_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MethaneGuard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Industrial Leak Detection System',
              style: TextStyle(
                color: Color(0xFF8AA6BF),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        const Text(
          'Mar 31, 2026, 07:51:45 PM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0AAE8F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Online',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatusBanner extends StatelessWidget {
  final bool isMobile;

  const StatusBanner({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 24,
        vertical: isMobile ? 18 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF101D31),
            Color(0xFF0B1627),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1B3651)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Status',
                  style: TextStyle(
                    color: Color(0xFF9CB3C7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: Color(0xFF10D8A4),
                      size: 13,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Normal Operation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'All sensors reporting within nominal ranges',
                  style: TextStyle(
                    color: Color(0xFF8DA7BE),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A8B60),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'SAFE',
                    style: TextStyle(
                      color: Color(0xFF38F8AF),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Status',
                        style: TextStyle(
                          color: Color(0xFF9CB3C7),
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: Color(0xFF10D8A4),
                            size: 13,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Normal Operation',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All sensors reporting within nominal ranges',
                        style: TextStyle(
                          color: Color(0xFF8DA7BE),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A8B60),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'SAFE',
                    style: TextStyle(
                      color: Color(0xFF38F8AF),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF15D3BB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101D31),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0D394A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF16D0BC),
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF91A9BF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF11D7A8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class RecentAlertsCard extends StatelessWidget {
  const RecentAlertsCard({super.key});

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
                child: Text(
                  'Recent Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A4258)),
                ),
                child: const Text(
                  'Last 24 Hours',
                  style: TextStyle(
                    color: Color(0xFF91A9BF),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AlertTile(
            time: '14:23:15',
            level: 'Low',
            levelColor: Color(0xFF0AAE8F),
            message: 'Sensor calibration drift detected',
          ),
          const SizedBox(height: 12),
          const AlertTile(
            time: '12:45:30',
            level: 'Medium',
            levelColor: Color(0xFFE69521),
            message: 'CH₄ concentration spike (resolved)',
          ),
          const SizedBox(height: 12),
          const AlertTile(
            time: '09:12:08',
            level: 'Low',
            levelColor: Color(0xFF0AAE8F),
            message: 'Minor signal attenuation anomaly',
          ),
        ],
      ),
    );
  }
}

class AlertTile extends StatelessWidget {
  final String time;
  final String level;
  final Color levelColor;
  final String message;

  const AlertTile({
    super.key,
    required this.time,
    required this.level,
    required this.levelColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 500;

    if (isSmall) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF08111D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A3550)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: const TextStyle(
                color: Color(0xFF8FA7BD),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                level,
                style: TextStyle(
                  color: levelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF08111D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A3550)),
      ),
      child: Row(
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF8FA7BD),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level,
              style: TextStyle(
                color: levelColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

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
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetectionDetailsPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16CDBD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'View Detection Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogsPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2A4258)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'View Logs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            height: 1,
            color: const Color(0xFF22394E),
          ),
          const SizedBox(height: 16),
          const Text(
            'Monitoring IR absorption at 7.66 µm',
            style: TextStyle(
              color: Color(0xFFA8C0D2),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'CH₄ detection via spectral analysis',
            style: TextStyle(
              color: Color(0xFF718AA0),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}