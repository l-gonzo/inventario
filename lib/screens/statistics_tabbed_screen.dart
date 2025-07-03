import 'package:flutter/material.dart';
import 'stock_statistics_screen.dart';
import 'alerts_statistics_screen.dart';
import 'movements_statistics_screen.dart';
import 'value_statistics_screen.dart';

class StatisticsTabbedScreen extends StatelessWidget {
  const StatisticsTabbedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Estadísticas de Inventario'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.inventory), text: 'Existencias'),
              Tab(icon: Icon(Icons.warning), text: 'Alertas'),
              Tab(icon: Icon(Icons.compare_arrows), text: 'Movimientos'),
              Tab(icon: Icon(Icons.attach_money), text: 'Valor'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StockStatisticsScreen(),
            AlertsStatisticsScreen(),
            MovementsStatisticsScreen(),
            ValueStatisticsScreen(),
          ],
        ),
      ),
    );
  }
}
