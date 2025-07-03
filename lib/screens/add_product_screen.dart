import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  final DocumentSnapshot? productToEdit;

  const AddProductScreen({super.key, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      final data = widget.productToEdit!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _stockController.text = data['stock']?.toString() ?? '';
      _minStockController.text = data['minStock']?.toString() ?? '';
      _categoryController.text = data['category'] ?? '';
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final minStock = int.tryParse(_minStockController.text) ?? 0;
    final category = _categoryController.text.trim().isNotEmpty
        ? _categoryController.text.trim()
        : 'General'; // Default category if not provided

    final data = {
      'name': name,
      'price': price,
      'category': category, // Default category, can be changed later
      'stock': stock,
      'minStock': minStock,
      'date': Timestamp.now(),
    };

    if (widget.productToEdit != null) {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productToEdit!.id)
          .update(data);
    } else {
      await FirebaseFirestore.instance.collection('products').add(data);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productToEdit != null ? 'Editar producto' : 'Nuevo producto',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = double.tryParse(value ?? '');
                  return v == null || v < 0 ? 'Precio inválido' : null;
                },
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Categoría'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock actual'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = int.tryParse(value ?? '');
                  return v == null || v < 0 ? 'Stock inválido' : null;
                },
              ),
              TextFormField(
                controller: _minStockController,
                decoration: const InputDecoration(labelText: 'Stock mínimo'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = int.tryParse(value ?? '');
                  return v == null || v < 0 ? 'Mínimo inválido' : null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(
                  widget.productToEdit != null
                      ? 'Guardar cambios'
                      : 'Agregar producto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
