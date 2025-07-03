import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductHistoryScreen extends StatelessWidget {
  final String productId;
  final String productName;

  const ProductHistoryScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  Stream<List<Map<String, dynamic>>> getCombinedMovements(String productId) async* {
    final entriesStream = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('entries')
        .snapshots();

    final exitsStream = FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('exits')
        .snapshots();

    await for (final entries in entriesStream) {
      final exits = await exitsStream.first;

      final all = [
        ...entries.docs.map((e) => {
              'type': 'entry',
              'quantity': e['quantity'],
              'date': e['date'],
            }),
        ...exits.docs.map((e) => {
              'type': 'exit',
              'quantity': e['quantity'],
              'date': e['date'],
            }),
      ];

      all.sort((a, b) {
        final dateA = (a['date'] as Timestamp).toDate();
        final dateB = (b['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA);
      });

      yield all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial de $productName')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getCombinedMovements(productId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar historial'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final movements = snapshot.data!;
          if (movements.isEmpty) {
            return const Center(child: Text('No hay movimientos registrados'));
          }

          return ListView.builder(
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final data = movements[index];
              final isEntry = data['type'] == 'entry';
              final quantity = data['quantity'] ?? 0;
              final date = (data['date'] as Timestamp).toDate();

              return ListTile(
                leading: Icon(
                  isEntry ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isEntry ? Colors.green : Colors.red,
                ),
                title: Text('${isEntry ? 'Entrada' : 'Salida'} de $quantity unidades'),
                subtitle: Text(
                  'Fecha: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
