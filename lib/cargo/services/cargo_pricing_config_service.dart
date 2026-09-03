import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cargo_pricing_model.dart';

class CargoPricingConfigService {
  CargoPricingConfigService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'cargo_settings';
  static const String pricingDocumentId = 'pricing';

  DocumentReference<Map<String, dynamic>> get _pricingReference =>
      _firestore.collection(collectionName).doc(pricingDocumentId);

  Future<CargoPricingModel> getPricing() async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _pricingReference.get();

    final Map<String, dynamic>? data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return CargoPricingModel.defaults();
    }

    return CargoPricingModel.fromMap(data);
  }

  Stream<CargoPricingModel> watchPricing() {
    return _pricingReference.snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return CargoPricingModel.defaults();
      }

      return CargoPricingModel.fromMap(data);
    });
  }

  Future<void> savePricing(CargoPricingModel pricing) async {
    await _pricingReference.set(<String, dynamic>{
      ...pricing.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateField(String field, Object? value) async {
    final String cleanField = field.trim();

    if (cleanField.isEmpty) {
      throw ArgumentError('Pricing field cannot be empty.');
    }

    await _pricingReference.set(<String, dynamic>{
      cleanField: value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setBuyForMeEnabled(bool enabled) {
    return updateField('buyForMeEnabled', enabled);
  }

  Future<void> setBuyForMeAdvancePercentage(double percentage) {
    final double safePercentage = percentage.clamp(0, 100).toDouble();

    return updateField('buyForMeAdvancePercentage', safePercentage);
  }

  Future<void> setBuyForMeMaxPurchaseAmount(double amount) {
    final double safeAmount = amount < 0 ? 0 : amount;

    return updateField('buyForMeMaxPurchaseAmount', safeAmount);
  }

  Future<void> setAdminCommissionPercentage(double percentage) {
    final double safePercentage = percentage.clamp(0, 100).toDouble();

    return updateField('adminCommissionPercentage', safePercentage);
  }

  Future<void> setPaymentMethodEnabled({
    required String method,
    required bool enabled,
  }) {
    switch (method.trim().toLowerCase()) {
      case 'cash':
        return updateField('cashEnabled', enabled);

      case 'wallet':
        return updateField('walletEnabled', enabled);

      case 'jazzcash':
        return updateField('jazzCashEnabled', enabled);

      case 'easypaisa':
        return updateField('easypaisaEnabled', enabled);

      case 'card':
      case 'bank_card':
        return updateField('cardEnabled', enabled);

      default:
        throw ArgumentError('Unsupported Cargo payment method: $method');
    }
  }
}
