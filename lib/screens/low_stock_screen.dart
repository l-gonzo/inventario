import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LowStockScreen extends StatelessWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos con baja existencia')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final lowStockProducts = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final stock = data['stock'];
            final minStock = data['minStock'];

            return stock is num && minStock is num && stock < minStock;
          }).toList();

          if (lowStockProducts.isEmpty) {
            return const Center(child: Text('Todos los productos tienen suficiente stock.'));
          }

          return ListView.builder(
            itemCount: lowStockProducts.length,
            itemBuilder: (context, index) {
              final doc = lowStockProducts[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Sin nombre';
              final stock = data['stock'] ?? 'N/A';
              final minStock = data['minStock'] ?? 'N/A';

              return ListTile(
                title: Text(name),
                subtitle: Text('Stock actual: $stock / Mínimo requerido: $minStock'),
              );
            },
          );
        },
      ),
    );
  }
}
