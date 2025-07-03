import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _period = 'week';

  Future<List<Map<String, dynamic>>> _fetchMovements(String type) async {
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .get();
    final products = {for (var d in productsSnapshot.docs) d.id: d['name']};

    final now = DateTime.now();
    DateTime from;
    if (_period == 'week') {
      from = now.subtract(const Duration(days: 7));
    } else if (_period == 'month') {
      from = DateTime(now.year, now.month - 1, now.day);
    } else {
      from = DateTime(now.year - 1, now.month, now.day);
    }

    final allData = <Map<String, dynamic>>[];

    for (final entry in products.entries) {
      final productId = entry.key;
      final name = entry.value;

      final movementSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection(type == 'entry' ? 'entries' : 'exits')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .get();

      final total = movementSnapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc['quantity'] ?? 0) as int),
      );

      if (total > 0) {
        allData.add({'name': name, 'quantity': total});
      }
    }

    allData.sort(
      (a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int),
    );

    return allData.take(6).toList();
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, String title) {
    final maxY = data
        .map((e) => e['quantity'] as int)
        .fold(0, (a, b) => a > b ? a : b);
    final step = (maxY / 5).ceil().clamp(1, double.infinity).toDouble();

    return _buildCard(
      title: title,
      child: BarChart(
        BarChartData(
          maxY: maxY.toDouble() + step,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) => Text(value.toInt().toString()),
                interval: step,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    final label = data[index]['name'].toString();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          label.length > 8
                              ? '${label.substring(0, 8)}…'
                              : label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barGroups: List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (data[i]['quantity'] as int).toDouble(),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Inventario'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _period = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('Semana')),
              const PopupMenuItem(value: 'month', child: Text('Mes')),
              const PopupMenuItem(value: 'year', child: Text('Año')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([
          _fetchMovements('entry'),
          _fetchMovements('exit'),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final entryData = snapshot.data![0];
          final exitData = snapshot.data![1];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBarChart(entryData, 'Productos más entradas ($_period)'),
                _buildBarChart(exitData, 'Productos más salidas ($_period)'),
              ],
            ),
          );
        },
      ),
    );
  }
}
