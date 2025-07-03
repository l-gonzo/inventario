import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class AlertsStatisticsScreen extends StatelessWidget {
  const AlertsStatisticsScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchLowStockProducts() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    final List<Map<String, dynamic>> products = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final stock = data['stock'] ?? 0;
      final minStock = data['minStock'] ?? 0;

      if (stock < minStock) {
        products.add({
          'name': data['name'] ?? 'Sin nombre',
          'stock': stock,
          'minStock': minStock,
        });
      }
    }

    return products;
  }

  Color _colorFromName(String name) {
    final hash = name.codeUnits.fold(0, (prev, c) => prev + c);
    final rng = Random(hash);
    return Color.fromARGB(255, rng.nextInt(200), rng.nextInt(200), rng.nextInt(200));
  }

  Widget _buildLowStockBarChart(List<Map<String, dynamic>> data, Map<String, Color> productColors) {
    final maxY = data.map((e) => e['minStock'] as int).fold(0, (a, b) => a > b ? a : b).toDouble();
    final step = (maxY / 5).ceil().clamp(1, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + step,
        barTouchData: BarTouchData(enabled: true),
        gridData: FlGridData(show: true, horizontalInterval: step.toDouble()),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: const Text("Cantidad"),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: step.toDouble(),
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text('${value.toInt()}', style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Padding(
              padding: EdgeInsets.only(top: 0.0),
              child: Text("Productos"),
            ),
            sideTitles: SideTitles(
              showTitles: false,
              reservedSize: 60,
              interval: 1,
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          final product = data[i];
          final name = product['name'];
          final stock = (product['stock'] as int).toDouble();
          final minStock = (product['minStock'] as int).toDouble();

          return BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: minStock,
                color: Colors.grey.shade300,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: stock,
                color: productColors[name] ?? Colors.redAccent,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 320, child: child),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas de Inventario')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLowStockProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(child: Text('No hay productos con bajo stock.'));
          }

          final productColors = <String, Color>{};
          final legendItems = <Widget>[];

          for (final p in data) {
            final name = p['name'];
            productColors[name] = _colorFromName(name);
            legendItems.add(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 16, height: 16, color: productColors[name]!),
                const SizedBox(width: 8),
                Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
              ],
            ));
          }

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
                  title: 'Productos por debajo del stock mínimo',
                  child: _buildLowStockBarChart(data, productColors),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}