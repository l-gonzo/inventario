import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class ValueStatisticsScreen extends StatelessWidget {
  const ValueStatisticsScreen({super.key});

  Color _colorFromName(String name) {
    final hash = name.codeUnits.fold(0, (prev, c) => prev + c);
    final rng = Random(hash);
    return Color.fromARGB(255, rng.nextInt(200), rng.nextInt(200), rng.nextInt(200));
  }

  Future<Map<String, double>> _getCategoryValues() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    final Map<String, double> categoryTotals = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Sin categoría';
      final price = (data['price'] ?? 0).toDouble();
      final stock = (data['stock'] ?? 0).toDouble();
      final value = price * stock;

      categoryTotals[category] = (categoryTotals[category] ?? 0) + value;
    }

    return categoryTotals;
  }

  Future<List<Map<String, dynamic>>> _getTopValuedProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();

    final List<Map<String, dynamic>> productValues = [];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Sin nombre';
      final price = (data['price'] ?? 0).toDouble();
      final stock = (data['stock'] ?? 0).toDouble();
      final value = price * stock;

      productValues.add({'name': name, 'value': value});
    }

    productValues.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));
    return productValues.take(6).toList();
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data, Map<String, Color> colorMap) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    return data.entries.map((e) {
      final percentage = ((e.value / total) * 100).toStringAsFixed(1);
      return PieChartSectionData(
        value: e.value,
        color: colorMap[e.key],
        title: '',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, Map<String, Color> colorMap) {
    final maxY = data.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b);
    final step = (maxY / 5).ceil().clamp(1, double.infinity).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY + step,
        gridData: FlGridData(show: true, horizontalInterval: step),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: const Text("Valor acumulado"),
            sideTitles: SideTitles(
              showTitles: true,
              interval: step,
              getTitlesWidget: (value, _) => Text(value.toInt().toString()),
              reservedSize: 36,
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Padding(
              padding: EdgeInsets.only(top: 0.0),
              child: Text("Productos"),
            ),
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: (data[i]['value'] as double),
              width: 14,
              borderRadius: BorderRadius.circular(4),
              color: colorMap[data[i]['name']],
            )
          ]);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Valor del Inventario')),
      body: FutureBuilder(
        future: Future.wait([
          _getCategoryValues(),
          _getTopValuedProducts(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categoryData = snapshot.data![0] as Map<String, double>;
          final productData = snapshot.data![1] as List<Map<String, dynamic>>;

          final colorMap = <String, Color>{};
          for (var item in productData) {
            colorMap[item['name']] = _colorFromName(item['name']);
          }
          for (var cat in categoryData.keys) {
            colorMap[cat] = _colorFromName(cat);
          }

          final totalValue = categoryData.values.fold(0.0, (a, b) => a + b);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Leyenda de categorías:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: categoryData.entries.map((entry) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 16, height: 16, color: colorMap[entry.key]),
                      const SizedBox(width: 8),
                      Text("${entry.key} (${((entry.value / totalValue) * 100).toStringAsFixed(1)}%)", overflow: TextOverflow.ellipsis),
                    ],
                  )).toList(),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Valor del inventario por categoría',
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(categoryData, colorMap),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const Text("Leyenda de productos:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: productData.map((e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 16, height: 16, color: colorMap[e['name']]),
                      const SizedBox(width: 8),
                      Text(e['name'], overflow: TextOverflow.ellipsis),
                    ],
                  )).toList(),
                ),
                const SizedBox(height: 16),
                _buildCard(
                  title: 'Productos con mayor valor acumulado',
                  child: _buildBarChart(productData, colorMap),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
