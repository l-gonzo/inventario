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
      appBar: AppBar(
        title: Text('Producto: $productName'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.inventory_2_rounded,
              size: 60,
              color: Colors.blueAccent.shade700,
            ),
            const SizedBox(height: 20),
            Text(
              productName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '¿Qué deseas hacer con este producto?',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildActionButton(
              context,
              icon: Icons.add_circle_outline,
              label: 'Registrar entrada',
              color: Colors.green,
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
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              icon: Icons.remove_circle_outline,
              label: 'Registrar salida',
              color: Colors.orange,
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
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              icon: Icons.history_edu,
              label: 'Ver historial de movimientos',
              color: Colors.blueGrey,
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

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
