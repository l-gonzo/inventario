/* // widgets/charts/inventory_summary_chart.dart
class InventorySummaryChart extends StatelessWidget {
  final List<ProductEntry> entries;
  final List<ProductExit> exits;

  const InventorySummaryChart({required this.entries, required this.exits});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        titlesData: ..., // Semana 1, 2, etc.
        barGroups: ...,  // Agrupar entradas y salidas por semana
        gridData: ...,   // Líneas guías
        borderData: ..., // Borde limpio
        barTouchData: ..., // Tooltip con detalles
      ),
    );
  }
}
 */