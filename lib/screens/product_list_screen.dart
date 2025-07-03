import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('productos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('Error al cargar los productos');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No hay productos aún.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final producto = docs[index];
              final nombre = producto['nombre'] ?? 'Sin nombre';
              final cantidad = producto['cantidad'] ?? 0;
              final maximo = producto['cantidadMaxima'] ?? 1; // Evitar división por 0
              final fechaCompra = producto['fechaCompra'] ?? '';
              final porcentaje = (cantidad / maximo);

              return ListTile(
                title: Text(nombre),
                subtitle: Text('Cantidad: $cantidad\nFecha de compra: $fechaCompra'),
                tileColor: porcentaje < 0.3 ? Colors.red.shade100 : null,
                trailing: porcentaje < 0.3
                    ? const Icon(Icons.warning, color: Colors.red)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
