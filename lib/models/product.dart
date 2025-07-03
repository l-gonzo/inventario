class Product {
  final String id;
  final String name;
  final int quantity;
  final List<DateTime> purchaseDates;

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.purchaseDates,
  });

  // Para guardar en Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'purchaseDates': purchaseDates.map((date) => date.toIso8601String()).toList(),
    };
  }

  // Para leer desde Firestore
  factory Product.fromDocument(String id, Map<String, dynamic> json) {
    return Product(
      id: id,
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      purchaseDates: (json['purchaseDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
    );
  }
}
