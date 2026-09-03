enum StudentRideInvoiceStatus {
  draft,
  issued,
  paymentPending,
  paid,
  partiallyPaid,
  overdue,
  cancelled,
  refunded,
}

enum StudentRideInvoicePaymentMethod {
  cash,
  wallet,
  easypaisa,
  jazzCash,
  card,
  bank,
  none,
}

class StudentRideInvoiceModel {
  final String invoiceId;
  final String subscriptionId;
  final String packageId;
  final String studentId;
  final String studentName;
  final String parentId;
  final String driverId;
  final String routeId;

  // Billing period
  final int billingMonth;
  final int billingYear;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dueDate;

  // Price breakdown
  final double baseAmount;
  final double distanceCharge;
  final double doorToDoorCharge;
  final double registrationFee;
  final double siblingDiscount;
  final double promoDiscount;
  final double adjustmentAmount;
  final double totalAmount;
  final String currencyCode;

  // Payment and commission
  final StudentRideInvoiceStatus status;
  final StudentRideInvoicePaymentMethod paymentMethod;
  final double amountPaid;
  final String paymentTransactionId;
  final bool commissionProcessed;
  final String commissionSettlementId;
  final double commissionAmount;
  final double driverNetEarning;
  final double commissionOutstanding;
  final String settlementStatus;

  // Admin audit
  final String issuedBy;
  final String paymentConfirmedBy;
  final String adminNote;
  final DateTime? issuedAt;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentRideInvoiceModel({
    required this.invoiceId,
    required this.subscriptionId,
    required this.packageId,
    required this.studentId,
    required this.studentName,
    required this.parentId,
    required this.driverId,
    required this.routeId,
    required this.billingMonth,
    required this.billingYear,
    required this.periodStart,
    required this.periodEnd,
    required this.dueDate,
    required this.baseAmount,
    required this.distanceCharge,
    required this.doorToDoorCharge,
    required this.registrationFee,
    required this.siblingDiscount,
    required this.promoDiscount,
    required this.adjustmentAmount,
    required this.totalAmount,
    required this.currencyCode,
    required this.status,
    required this.paymentMethod,
    required this.amountPaid,
    required this.paymentTransactionId,
    required this.commissionProcessed,
    required this.commissionSettlementId,
    required this.commissionAmount,
    required this.driverNetEarning,
    required this.commissionOutstanding,
    required this.settlementStatus,
    required this.issuedBy,
    required this.paymentConfirmedBy,
    required this.adminNote,
    required this.issuedAt,
    required this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid {
    return status == StudentRideInvoiceStatus.paid;
  }

  bool get isOverdue {
    return !isPaid &&
        status != StudentRideInvoiceStatus.cancelled &&
        status != StudentRideInvoiceStatus.refunded &&
        DateTime.now().isAfter(dueDate);
  }

  double get remainingAmount {
    final double value = totalAmount - amountPaid;
    return value > 0 ? value : 0;
  }

  String get billingPeriodLabel {
    return '$billingMonth/$billingYear';
  }

  factory StudentRideInvoiceModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    final DateTime now = DateTime.now();

    return StudentRideInvoiceModel(
      invoiceId: documentId.isNotEmpty
          ? documentId
          : map['invoiceId']?.toString() ?? '',
      subscriptionId:
          map['subscriptionId']?.toString() ?? '',
      packageId: map['packageId']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      parentId: map['parentId']?.toString() ?? '',
      driverId: map['driverId']?.toString() ?? '',
      routeId: map['routeId']?.toString() ?? '',
      billingMonth: _readInt(
        map['billingMonth'],
        fallback: now.month,
      ),
      billingYear: _readInt(
        map['billingYear'],
        fallback: now.year,
      ),
      periodStart: _readDateTime(map['periodStart']) ?? now,
      periodEnd: _readDateTime(map['periodEnd']) ?? now,
      dueDate: _readDateTime(map['dueDate']) ?? now,
      baseAmount: _readDouble(map['baseAmount']),
      distanceCharge: _readDouble(map['distanceCharge']),
      doorToDoorCharge:
          _readDouble(map['doorToDoorCharge']),
      registrationFee: _readDouble(map['registrationFee']),
      siblingDiscount:
          _readDouble(map['siblingDiscount']),
      promoDiscount: _readDouble(map['promoDiscount']),
      adjustmentAmount:
          _readDouble(map['adjustmentAmount']),
      totalAmount: _readDouble(map['totalAmount']),
      currencyCode: map['currencyCode']?.toString() ?? 'PKR',
      status: _statusFromString(map['status']?.toString()),
      paymentMethod: _paymentMethodFromString(
        map['paymentMethod']?.toString(),
      ),
      amountPaid: _readDouble(map['amountPaid']),
      paymentTransactionId:
          map['paymentTransactionId']?.toString() ?? '',
      commissionProcessed:
          map['commissionProcessed'] == true,
      commissionSettlementId:
          map['commissionSettlementId']?.toString() ?? '',
      commissionAmount:
          _readDouble(map['commissionAmount']),
      driverNetEarning:
          _readDouble(map['driverNetEarning']),
      commissionOutstanding:
          _readDouble(map['commissionOutstanding']),
      settlementStatus:
          map['settlementStatus']?.toString() ?? 'pending',
      issuedBy: map['issuedBy']?.toString() ?? '',
      paymentConfirmedBy:
          map['paymentConfirmedBy']?.toString() ?? '',
      adminNote: map['adminNote']?.toString() ?? '',
      issuedAt: _readDateTime(map['issuedAt']),
      paidAt: _readDateTime(map['paidAt']),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'subscriptionId': subscriptionId,
      'packageId': packageId,
      'studentId': studentId,
      'studentName': studentName,
      'parentId': parentId,
      'driverId': driverId,
      'routeId': routeId,
      'billingMonth': billingMonth,
      'billingYear': billingYear,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'baseAmount': baseAmount,
      'distanceCharge': distanceCharge,
      'doorToDoorCharge': doorToDoorCharge,
      'registrationFee': registrationFee,
      'siblingDiscount': siblingDiscount,
      'promoDiscount': promoDiscount,
      'adjustmentAmount': adjustmentAmount,
      'totalAmount': totalAmount,
      'currencyCode': currencyCode,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'amountPaid': amountPaid,
      'paymentTransactionId': paymentTransactionId,
      'commissionProcessed': commissionProcessed,
      'commissionSettlementId': commissionSettlementId,
      'commissionAmount': commissionAmount,
      'driverNetEarning': driverNetEarning,
      'commissionOutstanding': commissionOutstanding,
      'settlementStatus': settlementStatus,
      'issuedBy': issuedBy,
      'paymentConfirmedBy': paymentConfirmedBy,
      'adminNote': adminNote,
      'issuedAt': issuedAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static StudentRideInvoiceStatus _statusFromString(
    String? value,
  ) {
    return StudentRideInvoiceStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRideInvoiceStatus.draft,
    );
  }

  static StudentRideInvoicePaymentMethod _paymentMethodFromString(
    String? value,
  ) {
    return StudentRideInvoicePaymentMethod.values.firstWhere(
      (item) => item.name.toLowerCase() == value?.toLowerCase(),
      orElse: () => StudentRideInvoicePaymentMethod.none,
    );
  }

  static double _readDouble(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  static int _readInt(dynamic value, {required int fallback}) {
    return value is num ? value.toInt() : fallback;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      final dynamic converted = value.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Supports Firestore Timestamp without importing cloud_firestore.
    }

    return DateTime.tryParse(value.toString());
  }
}
