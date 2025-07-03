import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LowStockScreen extends StatelessWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos con baja existencia'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lowStockProducts = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final stock = data['stock'];
            final minStock = data['minStock'];
            return stock is num && minStock is num && stock < minStock;
          }).toList();

          if (lowStockProducts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '✅ Todos los productos tienen suficiente stock.',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lowStockProducts.length,
            itemBuilder: (context, index) {
              final doc = lowStockProducts[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Sin nombre';
              final stock = data['stock'] ?? 0;
              final minStock = data['minStock'] ?? 0;
              final category = data['category'] ?? 'General';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Stock: $stock / Mínimo: $minStock\nCategoría: $category',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '¡Atención!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
