import 'package:finns_mobile/models/dashboard_data_model.dart';
import 'package:finns_mobile/providers/auth_provider.dart';
import 'package:finns_mobile/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  Future<DashboardData>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _dashboardFuture = _apiService.getDashboardData(token);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: FutureBuilder<DashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No dashboard data available.'));
            }

            final dashboardData = snapshot.data!;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDateRangeCard(dashboardData.range),
                  const SizedBox(height: 16),
                  _buildProductionCard(
                    title: 'Egg Production',
                    icon: Icons.egg_alt,
                    iconColor: Colors.orangeAccent,
                    summary: dashboardData.eggProduction,
                    isEgg: true,
                  ),
                  const SizedBox(height: 16),
                  _buildProductionCard(
                    title: 'Meat Production',
                    icon: Icons.kebab_dining,
                    iconColor: Colors.brown,
                    summary: dashboardData.meatProduction,
                    isEgg: false,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // A widget to display the date range
  Widget _buildDateRangeCard(DateRange range) {
    // A simple helper to format dates for display
    String formatDate(String dateStr) {
      try {
        return DateFormat.yMMMd().format(DateTime.parse(dateStr));
      } catch (e) {
        return dateStr;
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              '${formatDate(range.from)} - ${formatDate(range.to)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // A reusable card for displaying a production summary
  Widget _buildProductionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required ProductionSummary summary,
    required bool isEgg,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Use a GridView to show the KPIs in a 2x3 grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                _buildMetricTile(
                  label: isEgg ? 'Total Eggs' : 'Total Chickens',
                  value: summary.totalCount,
                ),
                _buildMetricTile(
                  label: 'Total Weight',
                  value: '${summary.totalWeight} kg',
                ),
                _buildMetricTile(
                  label: 'FCR',
                  value: summary.fcr,
                  isPrimary: true,
                ),
                _buildMetricTile(
                  label: 'Total Feed',
                  value: '${summary.totalFeed} kg',
                ),
                _buildMetricTile(
                  label: 'Total Water',
                  value: '${summary.totalWater} L',
                ),
                _buildMetricTile(
                  label: 'Total Deaths',
                  value: summary.totalDeath,
                  valueColor: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // A reusable tile for a single metric
  Widget _buildMetricTile({
    required String label,
    required String value,
    bool isPrimary = false,
    Color valueColor = Colors.black87,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isPrimary
          ? BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isPrimary ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.green.shade800 : valueColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
