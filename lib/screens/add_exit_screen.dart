import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddExitScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const AddExitScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<AddExitScreen> createState() => _AddExitScreenState();
}

class _AddExitScreenState extends State<AddExitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _submitExit() async {
    if (!_formKey.currentState!.validate()) return;

    final exitQuantity = int.parse(_quantityController.text.trim());
    setState(() => _isProcessing = true);

    final productRef =
        FirebaseFirestore.instance.collection('products').doc(widget.productId);

    try {
      final productSnapshot = await productRef.get();
      final currentStock = (productSnapshot.data()?['stock'] ?? 0);
      final stockInt = (currentStock is int) ? currentStock : (currentStock as num).toInt();

      if (exitQuantity > stockInt) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay suficiente stock disponible')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Obtener todas las entradas ordenadas por fecha (lógica PEPS)
      final entrySnapshots = await productRef
          .collection('entries')
          .orderBy('date')
          .get();

      int remaining = exitQuantity;
      final batch = FirebaseFirestore.instance.batch();

      for (final entry in entrySnapshots.docs) {
        final data = entry.data();
        final qty = (data['quantity'] ?? 0);
        final qtyInt = (qty is int) ? qty : (qty as num).toInt();

        if (qtyInt <= 0) continue;

        final ref = entry.reference;

        if (remaining >= qtyInt) {
          // Consumimos toda la entrada
          batch.update(ref, {'quantity': 0});
          remaining -= qtyInt;
        } else {
          // Parcialmente consume esta entrada
          batch.update(ref, {'quantity': qtyInt - remaining});
          remaining = 0;
          break;
        }
      }

      // Actualizar stock general
      batch.update(productRef, {
        'stock': FieldValue.increment(-exitQuantity),
      });

      // Registrar la salida (histórico opcional)
      final exitRef = productRef.collection('exits').doc();
      batch.set(exitRef, {
        'quantity': exitQuantity,
        'date': DateTime.now(),
      });

      await batch.commit();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salida registrada correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar salida: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Salida de ${widget.productName}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad a retirar'),
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
                onPressed: _isProcessing ? null : _submitExit,
                icon: const Icon(Icons.remove),
                label: const Text('Registrar salida'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
