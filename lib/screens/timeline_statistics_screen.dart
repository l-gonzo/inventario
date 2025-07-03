import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TimelineStatisticsScreen extends StatefulWidget {
  const TimelineStatisticsScreen({super.key});

  @override
  State<TimelineStatisticsScreen> createState() => _TimelineStatisticsScreenState();
}

class _TimelineStatisticsScreenState extends State<TimelineStatisticsScreen> {
  late Future<List<FlSpot>> inventoryFuture;
  late Future<List<BarChartGroupData>> movementsFuture;

  @override
  void initState() {
    super.initState();
    inventoryFuture = _fetchInventoryData();
    movementsFuture = _fetchWeeklyMovements();
  }

  Future<List<FlSpot>> _fetchInventoryData() async {
    final products = await FirebaseFirestore.instance.collection('products').get();

    final Map<String, int> monthlyInventory = {};
    final formatter = DateFormat('yyyy-MM');

    for (final product in products.docs) {
      final entries = await product.reference.collection('entries').get();
      final exits = await product.reference.collection('exits').get();

      for (var doc in entries.docs) {
        final date = (doc['date'] as Timestamp).toDate();
        final key = formatter.format(date);
        final quantity = (doc['quantity'] as num?)?.toInt() ?? 0;
        monthlyInventory[key] = (monthlyInventory[key] ?? 0) + quantity;
      }

      for (var doc in exits.docs) {
        final date = (doc['date'] as Timestamp).toDate();
        final key = formatter.format(date);
        final quantity = (doc['quantity'] as num?)?.toInt() ?? 0;
        monthlyInventory[key] = (monthlyInventory[key] ?? 0) - quantity;
      }
    }

    final sortedKeys = monthlyInventory.keys.toList()..sort();
    int cumulative = 0;
    final List<FlSpot> points = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      cumulative += monthlyInventory[sortedKeys[i]]!;
      points.add(FlSpot(i.toDouble(), cumulative.toDouble()));
    }

    return points;
  }

  Future<List<BarChartGroupData>> _fetchWeeklyMovements() async {
    final products = await FirebaseFirestore.instance.collection('products').get();
    final Map<String, int> weeklyCounts = {};
    final weekFormat = DateFormat('yyyy-ww');

    for (final product in products.docs) {
      final entries = await product.reference.collection('entries').get();
      final exits = await product.reference.collection('exits').get();

      for (var doc in [...entries.docs, ...exits.docs]) {
        final date = (doc['date'] as Timestamp).toDate();
        final key = weekFormat.format(date);
        weeklyCounts[key] = (weeklyCounts[key] ?? 0) + 1;
      }
    }

    final keys = weeklyCounts.keys.toList()..sort();
    return List.generate(keys.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: weeklyCounts[keys[i]]!.toDouble(),
            width: 12,
            borderRadius: BorderRadius.circular(4),
            color: Colors.blue,
          )
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inventario total en el tiempo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FutureBuilder<List<FlSpot>>(
            future: inventoryFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Error al cargar datos del inventario.');
              }
              if (!snapshot.hasData) return const CircularProgressIndicator();

              return AspectRatio(
                aspectRatio: 1.7,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: snapshot.data!,
                        isCurved: true,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        color: Colors.deepPurple,
                      )
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text('Movimientos por semana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FutureBuilder<List<BarChartGroupData>>(
            future: movementsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Error al cargar frecuencia de movimientos.');
              }
              if (!snapshot.hasData) return const CircularProgressIndicator();

              return AspectRatio(
                aspectRatio: 1.5,
                child: BarChart(
                  BarChartData(
                    barGroups: snapshot.data!,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
