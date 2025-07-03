import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MovementsStatisticsScreen extends StatefulWidget {
  const MovementsStatisticsScreen({super.key});

  @override
  State<MovementsStatisticsScreen> createState() => _MovementsStatisticsScreenState();
}

class _MovementsStatisticsScreenState extends State<MovementsStatisticsScreen> {
  String _period = 'month';

  Future<Map<String, dynamic>> _fetchMovements(String period) async {
    final now = DateTime.now();
    List<DateTime> periods;

    switch (period) {
      case 'week':
        periods = List.generate(6, (i) => now.subtract(Duration(days: i * 7)));
        break;
      case 'year':
        periods = List.generate(6, (i) => DateTime(now.year - i));
        break;
      default:
        periods = List.generate(6, (i) => DateTime(now.year, now.month - i));
    }

    final entries = List<int>.filled(6, 0);
    final exits = List<int>.filled(6, 0);

    final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();

    for (final productDoc in productsSnapshot.docs) {
      for (int i = 0; i < periods.length; i++) {
        late DateTime start;
        late DateTime end;

        if (period == 'week') {
          start = DateTime(periods[i].year, periods[i].month, periods[i].day);
          end = start.add(const Duration(days: 7));
        } else if (period == 'year') {
          start = DateTime(periods[i].year);
          end = DateTime(periods[i].year + 1);
        } else {
          start = DateTime(periods[i].year, periods[i].month);
          end = DateTime(periods[i].year, periods[i].month + 1);
        }

        final entriesSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(productDoc.id)
            .collection('entries')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end))
            .get();

        final exitsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(productDoc.id)
            .collection('exits')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end))
            .get();

        entries[i] += entriesSnapshot.docs.fold<int>(0, (sum, doc) => sum + ((doc['quantity'] ?? 0) as int));
        exits[i] += exitsSnapshot.docs.fold<int>(0, (sum, doc) => sum + ((doc['quantity'] ?? 0) as int));
      }
    }

    final labels = periods
        .map((d) => period == 'year'
            ? d.year.toString()
            : period == 'week'
                ? 'Sem ${DateFormat('w').format(d)}'
                : DateFormat('MMM').format(d))
        .toList()
        .reversed
        .toList();

    return {'entries': entries, 'exits': exits, 'labels': labels};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entradas y Salidas'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => _period = val),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'week', child: Text('Semanal')),
              PopupMenuItem(value: 'month', child: Text('Mensual')),
              PopupMenuItem(value: 'year', child: Text('Anual')),
            ],
            icon: const Icon(Icons.filter_list),
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchMovements(_period),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final entries = data['entries'] as List<int>;
          final exits = data['exits'] as List<int>;
          final labels = data['labels'] as List<String>;

          final maxY = (entries + exits).fold<int>(0, (prev, e) => e > prev ? e : prev);
          final yStep = ((maxY / 5).ceil()).toDouble().clamp(1.0, double.infinity);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text("Leyenda:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        const Text("Entradas"),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Row(
                      children: [
                        Container(width: 16, height: 16, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        const Text("Salidas"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: labels.length * 70,
                      child: BarChart(
                        BarChartData(
                          maxY: maxY.toDouble() + yStep,
                          barGroups: List.generate(
                            labels.length,
                            (i) => BarChartGroupData(
                              x: i,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: entries[i].toDouble(),
                                  width: 12,
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                BarChartRodData(
                                  toY: exits[i].toDouble(),
                                  width: 12,
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              axisNameWidget: const Text("Cantidad"),
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: yStep,
                                reservedSize: 40,
                                getTitlesWidget: (v, _) => Text(v.toInt().toString()),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              axisNameWidget: const Padding(
                                padding: EdgeInsets.only(top: 0.0),
                                child: Text("Período"),
                              ),
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final index = v.toInt();
                                  return RotatedBox(
                                    quarterTurns: 1,
                                    child: Text(
                                      index >= 0 && index < labels.length ? labels[index] : '',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: true, horizontalInterval: yStep),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(enabled: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
