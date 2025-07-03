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
      appBar: AppBar(
        title: Text('Historial de $productName'),
        centerTitle: true,
      ),
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
            return const Center(
              child: Text(
                'No hay movimientos registrados',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final data = movements[index];
              final isEntry = data['type'] == 'entry';
              final quantity = data['quantity'] ?? 0;
              final date = (data['date'] as Timestamp).toDate();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isEntry ? Colors.green : Colors.red,
                    child: Icon(
                      isEntry ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    '${isEntry ? 'Entrada' : 'Salida'} de $quantity unidades',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Fecha: ${_formatDate(date)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
