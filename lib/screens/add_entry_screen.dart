import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEntryScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const AddEntryScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantityController.text.trim());

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final productRef =
        FirebaseFirestore.instance.collection('products').doc(widget.productId);
    final entryRef = productRef.collection('entries').doc();

    try {
      // Guardar la entrada como documento en la subcolección 'entries'
      await entryRef.set({
        'quantity': quantity,
        'date': now,
      });

      // Incrementar el stock total del producto
      await productRef.update({
        'stock': FieldValue.increment(quantity),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada registrada exitosamente')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar entrada')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una cantidad';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Cantidad inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitEntry,
                icon: const Icon(Icons.save),
                label: const Text('Registrar entrada'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
