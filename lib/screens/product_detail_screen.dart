import 'package:flutter/material.dart';
import 'package:inventario_app/screens/add_entry_screen.dart';
import 'package:inventario_app/screens/add_exit_screen.dart';
import 'package:inventario_app/screens/product_history_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;
  final String productName;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalle: $productName')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Qué deseas hacer con este producto?',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Registrar entrada'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEntryScreen(
                      productId: productId,
                      productName: productName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.remove),
              label: const Text('Registrar salida'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExitScreen(
                      productId: productId,
                      productName: productName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Ver historial de movimientos'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductHistoryScreen(
                      productId: productId,
                      productName: productName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
