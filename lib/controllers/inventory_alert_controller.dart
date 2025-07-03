import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InventoryAlertController {
  static final InventoryAlertController _instance = InventoryAlertController._internal();

  factory InventoryAlertController() => _instance;

  InventoryAlertController._internal();

  final ValueNotifier<List<String>> lowStockProducts = ValueNotifier([]);

  void startMonitoring() {
    FirebaseFirestore.instance.collection('products').snapshots().listen((snapshot) {
      final lowStock = snapshot.docs.where((doc) {
        final data = doc.data();
        final stock = (data['stock'] ?? 0) as num;
        final minStock = (data['minStock'] ?? 0) as num;
        return stock < minStock;
      }).map((doc) => doc['name'].toString()).toList();

      lowStockProducts.value = lowStock;
    });
  }
}
