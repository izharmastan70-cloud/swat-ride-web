import 'package:cloud_firestore/cloud_firestore.dart';

enum RidePaymentMethod {
  cash,
  wallet,
  jazzCash,
  easypaisa,
  bankCard,
}

enum RidePaymentStatus {
  pending,
  processing,
  paid,
  failed,
  cancelled,
  refunded,
}

class RidePaymentMethodConfig {
  const RidePaymentMethodConfig({
    required this.method,
    required this.title,
    required this.isEnabled,
    this.isTestingBypassEnabled = false,
    this.minimumAmount = 0,
    this.maximumAmount,
  });

  final RidePaymentMethod method;
  final String title;
  final bool isEnabled;

  /// Development only. A paid provider is not contacted when this is true.
  final bool isTestingBypassEnabled;
  final double minimumAmount;
  final double? maximumAmount;

  bool supportsAmount(double amount) {
    if (!isEnabled || amount < minimumAmount) return false;
    return maximumAmount == null || amount <= maximumAmount!;
  }

  RidePaymentMethodConfig copyWith({
    RidePaymentMethod? method,
    String? title,
    bool? isEnabled,
    bool? isTestingBypassEnabled,
    double? minimumAmount,
    double? maximumAmount,
    bool removeMaximumAmount = false,
  }) {
    return RidePaymentMethodConfig(
      method: method ?? this.method,
      title: title ?? this.title,
      isEnabled: isEnabled ?? this.isEnabled,
      isTestingBypassEnabled:
          isTestingBypassEnabled ?? this.isTestingBypassEnabled,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumAmount:
          removeMaximumAmount ? null : maximumAmount ?? this.maximumAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'method': method.firestoreValue,
      'title': title,
      'isEnabled': isEnabled,
      'isTestingBypassEnabled': isTestingBypassEnabled,
      'minimumAmount': minimumAmount,
      'maximumAmount': maximumAmount,
    };
  }

  factory RidePaymentMethodConfig.fromMap(Map<String, dynamic> map) {
    final RidePaymentMethod method = RidePaymentMethodX.fromFirestore(
      map['method']?.toString(),
    );

    return RidePaymentMethodConfig(
      method: method,
      title: map['title']?.toString().trim().isNotEmpty == true
          ? map['title'].toString().trim()
          : method.title,
      isEnabled: map['isEnabled'] as bool? ?? method == RidePaymentMethod.cash,
      isTestingBypassEnabled:
          map['isTestingBypassEnabled'] as bool? ?? false,
      minimumAmount: (map['minimumAmount'] as num?)?.toDouble() ?? 0,
      maximumAmount: (map['maximumAmount'] as num?)?.toDouble(),
    );
  }
}

class RidePaymentModel {
  const RidePaymentModel({
    required this.paymentId,
    required this.rideId,
    required this.userId,
    this.driverId,
    required this.method,
    required this.status,
    required this.amount,
    this.providerTransactionId,
    this.failureReason,
    this.isTestingPayment = false,
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
  });

  final String paymentId;
  final String rideId;
  final String userId;
  final String? driverId;
  final RidePaymentMethod method;
  final RidePaymentStatus status;
  final double amount;
  final String? providerTransactionId;
  final String? failureReason;

  /// Always false for a real provider payment.
  final bool isTestingPayment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;

  bool get isSuccessful => status == RidePaymentStatus.paid;
  bool get requiresOnlineProvider => method == RidePaymentMethod.jazzCash ||
      method == RidePaymentMethod.easypaisa ||
      method == RidePaymentMethod.bankCard;

  RidePaymentModel copyWith({
    String? paymentId,
    String? rideId,
    String? userId,
    String? driverId,
    RidePaymentMethod? method,
    RidePaymentStatus? status,
    double? amount,
    String? providerTransactionId,
    String? failureReason,
    bool? isTestingPayment,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
  }) {
    return RidePaymentModel(
      paymentId: paymentId ?? this.paymentId,
      rideId: rideId ?? this.rideId,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      method: method ?? this.method,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      providerTransactionId:
          providerTransactionId ?? this.providerTransactionId,
      failureReason: failureReason ?? this.failureReason,
      isTestingPayment: isTestingPayment ?? this.isTestingPayment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'paymentId': paymentId,
      'rideId': rideId,
      'userId': userId,
      'driverId': driverId,
      'method': method.firestoreValue,
      'status': status.firestoreValue,
      'amount': amount,
      'providerTransactionId': providerTransactionId,
      'failureReason': failureReason,
      'isTestingPayment': isTestingPayment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'paidAt': paidAt == null ? null : Timestamp.fromDate(paidAt!),
    };
  }

  factory RidePaymentModel.fromMap(Map<String, dynamic> map) {
    return RidePaymentModel(
      paymentId: map['paymentId']?.toString() ?? '',
      rideId: map['rideId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      driverId: map['driverId']?.toString(),
      method: RidePaymentMethodX.fromFirestore(map['method']?.toString()),
      status: RidePaymentStatusX.fromFirestore(map['status']?.toString()),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      providerTransactionId: map['providerTransactionId']?.toString(),
      failureReason: map['failureReason']?.toString(),
      isTestingPayment: map['isTestingPayment'] as bool? ?? false,
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']),
      paidAt: _date(map['paidAt']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

extension RidePaymentMethodX on RidePaymentMethod {
  String get firestoreValue {
    switch (this) {
      case RidePaymentMethod.cash:
        return 'cash';
      case RidePaymentMethod.wallet:
        return 'wallet';
      case RidePaymentMethod.jazzCash:
        return 'jazzcash';
      case RidePaymentMethod.easypaisa:
        return 'easypaisa';
      case RidePaymentMethod.bankCard:
        return 'bank_card';
    }
  }

  String get title {
    switch (this) {
      case RidePaymentMethod.cash:
        return 'Cash';
      case RidePaymentMethod.wallet:
        return 'Wallet';
      case RidePaymentMethod.jazzCash:
        return 'JazzCash';
      case RidePaymentMethod.easypaisa:
        return 'Easypaisa';
      case RidePaymentMethod.bankCard:
        return 'Bank Card';
    }
  }

  static RidePaymentMethod fromFirestore(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'wallet':
        return RidePaymentMethod.wallet;
      case 'jazzcash':
      case 'jazz_cash':
        return RidePaymentMethod.jazzCash;
      case 'easypaisa':
      case 'easy_paisa':
        return RidePaymentMethod.easypaisa;
      case 'bank_card':
      case 'bankcard':
      case 'card':
      case 'credit_card':
      case 'debit_card':
        return RidePaymentMethod.bankCard;
      default:
        return RidePaymentMethod.cash;
    }
  }
}

extension RidePaymentStatusX on RidePaymentStatus {
  String get firestoreValue => name;

  static RidePaymentStatus fromFirestore(String? value) {
    return RidePaymentStatus.values.firstWhere(
      (RidePaymentStatus status) => status.name == value?.toLowerCase(),
      orElse: () => RidePaymentStatus.pending,
    );
  }
}
