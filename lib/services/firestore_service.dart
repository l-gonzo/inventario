import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collection = 'products';

  Future<void> addProduct(Product product) async {
    await _db.collection(collection).add(product.toJson());
  }

  Future<List<Product>> getProducts() async {
    final snapshot = await _db.collection(collection).get();
    return snapshot.docs.map((doc) => 
      Product.fromDocument(doc.id, doc.data())
    ).toList();
  }

  Future<void> updateProduct(Product product) async {
    await _db.collection(collection).doc(product.id).update(product.toJson());
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  Stream<List<Product>> streamProducts() {
    return _db.collection(collection).snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Product.fromDocument(doc.id, doc.data())).toList()
    );
  }
}
