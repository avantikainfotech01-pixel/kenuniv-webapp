import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenuniv/providers/qr_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Riverpod providers (mocked)
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final response = await http.get(
    Uri.parse("http://api.kenuniv.com/api/wallet/admin/dashboard-stats"),
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    return body['data'];
  } else {
    print("Failed to load dashboard stats: ${response.statusCode}");
    return {
      "remainingStock": 0,
      "totalUsers": 0,
      "walletAmount": 0,
      "redemptionAmount": 0,
    };
  }
});

final locationDataProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final response = await http.get(
    Uri.parse("http://api.kenuniv.com/api/location-stats"),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data']);
  } else {
    return [];
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final qrStats = ref.watch(qrStatsProvider);
    final locationDataAsync = ref.watch(locationDataProvider);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Header
                    Row(
                      children: [
                        Text(
                          "Overview",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Overview cards
                    statsAsync.when(
                      data: (stats) => Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          _DashboardCard(
                            color: Colors.blue,
                            icon: Icons.inventory_2,
                            title: 'Remaining Stock',
                            value: stats["remainingStock"].toString(),
                          ),
                          _DashboardCard(
                            color: Colors.orange,
                            icon: Icons.people_alt,
                            title: 'No. of Contractor',
                            value: stats["totalUsers"].toString(),
                          ),
                          _DashboardCard(
                            color: Colors.green,
                            icon: Icons.account_balance_wallet,
                            title: 'Wallet Amount',
                            value: stats["walletAmount"].toString(),
                          ),
                          _DashboardCard(
                            color: Colors.purple,
                            icon: Icons.redeem,
                            title: 'Redemption Amount',
                            value: stats["redemptionAmount"].toString(),
                          ),
                        ],
                      ),
                      loading: () => CircularProgressIndicator(),
                      error: (e, st) => Text("Failed to load stats"),
                    ),
                    const SizedBox(height: 40),
                    // Bar chart and Donut chart
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bar Chart (Location-wise contractor)
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location-wise Contractor',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.end,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 240,
                                  child: Center(
                                    child: locationDataAsync.when(
                                      data: (data) =>
                                          _LocationBarChart(data: data),
                                      loading: () => Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      error: (e, st) =>
                                          Text("Failed to load location stats"),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Donut Chart (QR Stats)
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: qrStats.when(
                              data: (qrStatsData) => Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'QR Stats',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: _QRDonutChart(qrStats: qrStatsData),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _DonutLegend(
                                        color: Colors.green,
                                        label: 'Activated QR',
                                        value: qrStatsData['active'].toString(),
                                      ),
                                      const SizedBox(width: 16),
                                      _DonutLegend(
                                        color: Colors.red,
                                        label: 'Inactivated QR',
                                        value: qrStatsData['inactive']
                                            .toString(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, st) => Center(
                                child: Text('Failed to load QR stats'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dashboard overview card widget
class _DashboardCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String value;

  const _DashboardCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

// Simple bar chart for location-wise contractor data
class _LocationBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _LocationBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // find max value for scaling
    final maxCount = data
        .map((e) => e['count'] as int)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.map((entry) {
        final count = entry['count'] as int;
        final location = entry['location'] as String;
        final barHeight = (count / (maxCount == 0 ? 1 : maxCount)) * 160.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 30,
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: count > 0
                      ? Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(location, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Simple Donut Chart for QR stats
class _QRDonutChart extends StatelessWidget {
  final Map<String, int> qrStats;
  const _QRDonutChart({required this.qrStats});

  @override
  Widget build(BuildContext context) {
    final activated = qrStats['active'] ?? 0;
    final inactivated = qrStats['inactive'] ?? 0;
    final total = (activated + inactivated).toDouble();
    final activatedPercent = total == 0 ? 0.0 : activated / total;
    final inactivatedPercent = total == 0 ? 0.0 : inactivated / total;

    return CustomPaint(
      painter: _DonutChartPainter(
        activatedPercent: activatedPercent,
        inactivatedPercent: inactivatedPercent,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$activated',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Activated',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double activatedPercent;
  final double inactivatedPercent;
  _DonutChartPainter({
    required this.activatedPercent,
    required this.inactivatedPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = 28.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw activated arc
    paint.color = Colors.green;
    final activatedSweep = activatedPercent * 3.14159 * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      activatedSweep,
      false,
      paint,
    );

    // Draw inactivated arc
    paint.color = Colors.red;
    final inactivatedSweep = inactivatedPercent * 3.14159 * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2 + activatedSweep,
      inactivatedSweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _DonutLegend({
    required this.color,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
