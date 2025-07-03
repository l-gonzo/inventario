import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class StockStatisticsScreen extends StatelessWidget {
  const StockStatisticsScreen({super.key});

  // Colores únicos generados por hash fijo
  Color _colorFromString(String input) {
    final hash = input.codeUnits.fold(0, (prev, c) => prev * 31 + c);
    final rng = Random(hash);
    return Color.fromARGB(255, rng.nextInt(200), rng.nextInt(200), rng.nextInt(200));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas de Existencias')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('products').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          final barGroups = <BarChartGroupData>[];
          final productColors = <String, Color>{};
          final legendItems = <Widget>[];
          final categoryCount = <String, int>{};
          final categoryColors = <String, Color>{};
          final categoryLegendItems = <Widget>[];

          double maxY = 0;

          for (int i = 0; i < products.length; i++) {
            final p = products[i];
            final name = (p['name'] ?? '').toString();
            final stock = (p['stock'] ?? 0).toDouble();
            final category = (p['category'] ?? 'Sin categoría').toString();

            productColors[name] = _colorFromString(name);
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;

            legendItems.add(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, color: productColors[name]!),
                const SizedBox(width: 8),
                Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
              ],
            ));

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: stock,
                    width: 12,
                    borderRadius: BorderRadius.circular(4),
                    color: productColors[name],
                  )
                ],
              ),
            );

            maxY = max(maxY, stock);
          }

          // Colores únicos para categorías
          categoryCount.keys.forEach((category) {
            categoryColors[category] = _colorFromString("cat_" + category);
          });

          categoryCount.forEach((category, count) {
            final color = categoryColors[category]!;
            categoryLegendItems.add(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, color: color),
                const SizedBox(width: 8),
                Flexible(child: Text(category, overflow: TextOverflow.ellipsis)),
              ],
            ));
          });

          final pieSections = categoryCount.entries.map((e) {
            final color = categoryColors[e.key]!;
            return PieChartSectionData(
              value: e.value.toDouble(),
              title: e.key,
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              color: color,
            );
          }).toList();

          final yStep = ((maxY / 5).ceil()).toDouble().clamp(1.0, double.infinity);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Leyenda de productos:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: legendItems,
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Stock actual por producto',
                  height: 400,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY + yStep,
                      barGroups: barGroups,
                      barTouchData: BarTouchData(enabled: true),
                      gridData: FlGridData(show: true, horizontalInterval: yStep),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text("Cantidad"),
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: yStep,
                            reservedSize: 32,
                            getTitlesWidget: (v, _) => Text(v.toInt().toString()),
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Padding(
                            padding: EdgeInsets.only(top: 0.0),
                            child: Text("Productos"),
                          ),
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Leyenda de categorías:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: categoryLegendItems,
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Distribución de productos por categoría',
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
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

  Widget _buildCard({required String title, required Widget child, required double height}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}