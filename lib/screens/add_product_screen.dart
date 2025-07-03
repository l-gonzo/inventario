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
        : 'General';

    final data = {
      'name': name,
      'price': price,
      'category': category,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputField(
                controller: _nameController,
                label: 'Nombre',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              _buildInputField(
                controller: _priceController,
                label: 'Precio',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = double.tryParse(value ?? '');
                  return v == null || v < 0 ? 'Precio inválido' : null;
                },
              ),
              _buildInputField(
                controller: _categoryController,
                label: 'Categoría',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              _buildInputField(
                controller: _stockController,
                label: 'Stock actual',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = int.tryParse(value ?? '');
                  return v == null || v < 0 ? 'Stock inválido' : null;
                },
              ),
              _buildInputField(
                controller: _minStockController,
                label: 'Stock mínimo',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final v = int.tryParse(value ?? '');
                  return v == null || v < 0 ? 'Mínimo inválido' : null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(isEdit ? Icons.save : Icons.add),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveProduct,
                  label: Text(
                    isEdit ? 'Guardar cambios' : 'Agregar producto',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
