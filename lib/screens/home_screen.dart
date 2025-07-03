// 🎨 HomeScreen con diseño moderno y amigable
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:inventario_app/controllers/inventory_alert_controller.dart';
import 'package:inventario_app/screens/add_product_screen.dart';
import 'package:inventario_app/screens/low_stock_screen.dart';
import 'package:inventario_app/screens/product_detail_screen.dart';
import 'package:inventario_app/screens/statistics_tabbed_screen.dart';

enum OrderByOption { nameAsc, stockDesc, dateDesc }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  OrderByOption _selectedOrder = OrderByOption.nameAsc;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchTerm = _searchController.text.toLowerCase().trim());
    });
  }

  List<QueryDocumentSnapshot> _applySorting(List<QueryDocumentSnapshot> docs) {
    final products = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'doc': doc,
        'name': data['name'] ?? '',
        'stock': data['stock'] ?? 0,
        'date': data['date'] ?? Timestamp.now(),
      };
    }).toList();

    switch (_selectedOrder) {
      case OrderByOption.nameAsc:
        products.sort(
          (a, b) => a['name'].toString().compareTo(b['name'].toString()),
        );
        break;
      case OrderByOption.stockDesc:
        products.sort(
          (a, b) => (b['stock'] as int).compareTo(a['stock'] as int),
        );
        break;
      case OrderByOption.dateDesc:
        products.sort(
          (a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp),
        );
        break;
    }

    return products.map((e) => e['doc'] as QueryDocumentSnapshot).toList();
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sesión cerrada exitosamente')),
                );
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _editProduct(BuildContext context, DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(productToEdit: doc)),
    );
  }

  void _deleteProduct(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text('¿Estás seguro de eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(docId)
                  .delete();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventario',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout),
          ValueListenableBuilder<List<String>>(
            valueListenable: InventoryAlertController().lowStockProducts,
            builder: (context, lowStock, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orangeAccent,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LowStockScreen()),
                    ),
                  ),
                  if (lowStock.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${lowStock.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsTabbedScreen()),
            ),
          ),
          PopupMenuButton<OrderByOption>(
            onSelected: (option) => setState(() => _selectedOrder = option),
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: OrderByOption.nameAsc,
                child: Text('Nombre (A-Z)'),
              ),
              const PopupMenuItem(
                value: OrderByOption.stockDesc,
                child: Text('Stock (mayor a menor)'),
              ),
              const PopupMenuItem(
                value: OrderByOption.dateDesc,
                child: Text('Más reciente'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                /* fillColor: Colors.grey[200], */
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final filtered = snapshot.data!.docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchTerm);
                }).toList();

                final products = _applySorting(filtered);

                if (products.isEmpty) {
                  return const Center(
                    child: Text('No hay productos que coincidan.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: 85,
                  ), 
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final stock = data['stock'] ?? 0;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          data['name'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Precio: \$${data['price']} - Stock: $stock',
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              productId: doc.id,
                              productName: data['name'] ?? 'Sin nombre',
                            ),
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, /* color: Colors.teal */),
                              onPressed: () => _editProduct(context, doc),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteProduct(context, doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        /* backgroundColor: Colors.teal, */
      ),
    );
  }
}
