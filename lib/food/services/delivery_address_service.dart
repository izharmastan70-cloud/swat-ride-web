// lib/food/services/delivery_address_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Delivery Address Firestore Service
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_address_model.dart';

class DeliveryAddressService {
  DeliveryAddressService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection('users').doc(userId).collection('delivery_addresses');

  Future<String> saveAddress(DeliveryAddressModel address) async {
    final doc = address.id.isEmpty ? _ref(address.userId).doc() : _ref(address.userId).doc(address.id);
    final data = address.toMap()..['id'] = doc.id;
    await doc.set(data, SetOptions(merge: true));
    return doc.id;
  }

  Stream<List<DeliveryAddressModel>> watchAddresses(String userId) {
    return _ref(userId).snapshots().map((s) => s.docs
        .map((d) => DeliveryAddressModel.fromMap({...d.data(), 'id': d.id}))
        .toList());
  }

  Future<void> deleteAddress(String userId, String addressId) async {
    await _ref(userId).doc(addressId).delete();
  }

  Future<void> setDefaultAddress(String userId, String addressId) async {
    final batch = _firestore.batch();
    final docs = await _ref(userId).get();
    for (final d in docs.docs) {
      batch.update(d.reference, {'isDefault': d.id == addressId});
    }
    await batch.commit();
  }
}
