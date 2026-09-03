import 'package:cloud_firestore/cloud_firestore.dart';

class TourismPricingService {
  TourismPricingService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>>
      get _rulesCollection =>
          _firestore.collection('tourism_pricing_rules');

  // =========================================================
  // ACTIVE ADMIN PRICING RULES
  // =========================================================

  Future<List<Map<String, dynamic>>> getActivePricingRules({
    required String appliesTo,
    String? ruleType,
    String? targetName,
    String? targetId,
    DateTime? at,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _rulesCollection
            .where('isActive', isEqualTo: true)
            .get();

    final DateTime effectiveAt = at ?? DateTime.now();

    final List<Map<String, dynamic>> rules = snapshot.docs
        .map((doc) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(doc.data());

          return <String, dynamic>{
            ...data,
            'pricingRuleId':
                data['pricingRuleId']?.toString().trim().isNotEmpty ==
                        true
                    ? data['pricingRuleId'].toString().trim()
                    : doc.id,
          };
        })
        .where(
          (rule) => _ruleMatches(
            rule: rule,
            appliesTo: appliesTo,
            ruleType: ruleType,
            targetName: targetName,
            targetId: targetId,
            at: effectiveAt,
          ),
        )
        .toList();

    rules.sort(_compareRules);
    return rules;
  }

  Stream<List<Map<String, dynamic>>> activePricingRulesStream({
    required String appliesTo,
    String? ruleType,
    String? targetName,
    String? targetId,
    DateTime? at,
  }) {
    return _rulesCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final DateTime effectiveAt = at ?? DateTime.now();

      final List<Map<String, dynamic>> rules = snapshot.docs
          .map((doc) {
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(doc.data());

            return <String, dynamic>{
              ...data,
              'pricingRuleId':
                  data['pricingRuleId']
                              ?.toString()
                              .trim()
                              .isNotEmpty ==
                          true
                      ? data['pricingRuleId']
                          .toString()
                          .trim()
                      : doc.id,
            };
          })
          .where(
            (rule) => _ruleMatches(
              rule: rule,
              appliesTo: appliesTo,
              ruleType: ruleType,
              targetName: targetName,
              targetId: targetId,
              at: effectiveAt,
            ),
          )
          .toList();

      rules.sort(_compareRules);
      return rules;
    });
  }

  Future<Map<String, dynamic>?> getBestPricingRule({
    required String appliesTo,
    String? ruleType,
    String? targetName,
    String? targetId,
    DateTime? at,
  }) async {
    final List<Map<String, dynamic>> rules =
        await getActivePricingRules(
      appliesTo: appliesTo,
      ruleType: ruleType,
      targetName: targetName,
      targetId: targetId,
      at: at,
    );

    if (rules.isEmpty) {
      return null;
    }

    return rules.first;
  }

  Future<double?> getAdminAmount({
    required String appliesTo,
    String? ruleType,
    String? targetName,
    String? targetId,
    DateTime? at,
  }) async {
    final Map<String, dynamic>? rule =
        await getBestPricingRule(
      appliesTo: appliesTo,
      ruleType: ruleType,
      targetName: targetName,
      targetId: targetId,
      at: at,
    );

    if (rule == null) {
      return null;
    }

    final String valueType =
        rule['valueType']?.toString().trim().toLowerCase() ??
            'amount';

    if (valueType == 'percentage') {
      return null;
    }

    return _readDouble(rule['amount']);
  }

  Future<double?> getAdminPercentage({
    required String appliesTo,
    String? ruleType,
    String? targetName,
    String? targetId,
    DateTime? at,
  }) async {
    final Map<String, dynamic>? rule =
        await getBestPricingRule(
      appliesTo: appliesTo,
      ruleType: ruleType,
      targetName: targetName,
      targetId: targetId,
      at: at,
    );

    if (rule == null) {
      return null;
    }

    final String valueType =
        rule['valueType']?.toString().trim().toLowerCase() ??
            'amount';

    if (valueType != 'percentage') {
      return null;
    }

    return _readDouble(rule['percentage']);
  }

  bool _ruleMatches({
    required Map<String, dynamic> rule,
    required String appliesTo,
    required DateTime at,
    String? ruleType,
    String? targetName,
    String? targetId,
  }) {
    if (rule['isActive'] == false) {
      return false;
    }

    final String ruleAppliesTo =
        rule['appliesTo']?.toString().trim().toLowerCase() ??
            'all';

    final String requestedAppliesTo =
        appliesTo.trim().toLowerCase();

    if (ruleAppliesTo != 'all' &&
        ruleAppliesTo != requestedAppliesTo) {
      return false;
    }

    if (ruleType != null && ruleType.trim().isNotEmpty) {
      final String actualType =
          rule['ruleType']?.toString().trim().toLowerCase() ??
              '';

      if (actualType != ruleType.trim().toLowerCase()) {
        return false;
      }
    }

    if (targetId != null && targetId.trim().isNotEmpty) {
      final String actualTargetId =
          rule['targetId']?.toString().trim() ?? '';

      if (actualTargetId.isNotEmpty &&
          actualTargetId != targetId.trim()) {
        return false;
      }
    }

    if (targetName != null &&
        targetName.trim().isNotEmpty) {
      final String actualTargetName =
          rule['targetName']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (actualTargetName.isNotEmpty &&
          actualTargetName !=
              targetName.trim().toLowerCase()) {
        return false;
      }
    }

    final DateTime? startDate =
        _readNullableDateTime(rule['startDate']);

    final DateTime? endDate =
        _readNullableDateTime(rule['endDate']);

    if (startDate != null && at.isBefore(startDate)) {
      return false;
    }

    if (endDate != null && at.isAfter(endDate)) {
      return false;
    }

    return true;
  }

  int _compareRules(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final int aPriority = _readInt(a['priority']);
    final int bPriority = _readInt(b['priority']);

    final int priorityCompare =
        bPriority.compareTo(aPriority);

    if (priorityCompare != 0) {
      return priorityCompare;
    }

    final int aOrder =
        _readInt(a['calculationOrder']);
    final int bOrder =
        _readInt(b['calculationOrder']);

    return aOrder.compareTo(bOrder);
  }

  // =========================================================
  // PRIVATE TOUR QUOTATION
  // =========================================================

  Map<String, double> calculatePrivateTour({
    required double vehiclePerDay,
    required int numberOfDays,
    required double hotelPerNight,
    required int numberOfRooms,
    required int numberOfNights,
    double driverAllowancePerDay = 1200,
    double jeepCost = 0,
    double profitPercentage = 15,
  }) {
    final double vehicleCost =
        vehiclePerDay * numberOfDays;

    final double hotelCost =
        hotelPerNight *
            numberOfRooms *
            numberOfNights;

    final double driverCost =
        driverAllowancePerDay *
            numberOfDays;

    final double baseCost =
        vehicleCost +
            hotelCost +
            driverCost +
            jeepCost;

    final double companyProfit =
        baseCost *
            (profitPercentage / 100);

    final double finalPrice =
        baseCost +
            companyProfit;

    return <String, double>{
      'vehicleCost': vehicleCost,
      'hotelCost': hotelCost,
      'driverCost': driverCost,
      'jeepCost': jeepCost,
      'baseCost': baseCost,
      'companyProfit': companyProfit,
      'finalPrice': finalPrice,
    };
  }

  // =========================================================
  // GROUP TOUR QUOTATION
  // =========================================================

  Map<String, double> calculateGroupTour({
    required double pricePerPerson,
    required int numberOfGuests,
    double extraJeepCost = 0,
    double extraCharges = 0,
  }) {
    final double tourCost =
        pricePerPerson *
            numberOfGuests;

    final double baseCost =
        tourCost +
            extraJeepCost +
            extraCharges;

    return <String, double>{
      'tourCost': tourCost,
      'jeepCost': extraJeepCost,
      'extraCharges': extraCharges,
      'baseCost': baseCost,
      'finalPrice': baseCost,
    };
  }

  // =========================================================
  // HOTEL COST
  // =========================================================

  double calculateHotelCost({
    required double roomPricePerNight,
    required int numberOfRooms,
    required int numberOfNights,
  }) {
    return roomPricePerNight *
        numberOfRooms *
        numberOfNights;
  }

  // =========================================================
  // DRIVER ALLOWANCE
  // =========================================================

  double calculateDriverAllowance({
    required double dailyAllowance,
    required int numberOfDays,
  }) {
    return dailyAllowance *
        numberOfDays;
  }

  // =========================================================
  // COMPANY PROFIT
  // =========================================================

  double calculateProfit({
    required double baseCost,
    required double profitPercentage,
  }) {
    return baseCost *
        (profitPercentage / 100);
  }

  // =========================================================
  // FINAL QUOTATION
  // =========================================================

  double calculateFinalPrice({
    required double baseCost,
    required double profitPercentage,
  }) {
    final double profit =
        calculateProfit(
      baseCost: baseCost,
      profitPercentage:
          profitPercentage,
    );

    return baseCost +
        profit;
  }

  // =========================================================
  // ADVANCE PAYMENT
  // =========================================================

  double calculateAdvancePayment({
    required double finalPrice,
    double advancePercentage = 30,
  }) {
    return finalPrice *
        (advancePercentage / 100);
  }

  // =========================================================
  // REMAINING PAYMENT
  // =========================================================

  double calculateRemainingPayment({
    required double finalPrice,
    required double advancePaid,
  }) {
    final double remaining =
        finalPrice -
            advancePaid;

    if (remaining < 0) {
      return 0;
    }

    return remaining;
  }

  // =========================================================
  // COMPLETE PRIVATE TOUR QUOTATION
  // =========================================================

  Map<String, dynamic>
      createPrivateTourQuotation({
    required double vehiclePerDay,
    required int numberOfDays,
    required double hotelPerNight,
    required int numberOfRooms,
    required int numberOfNights,
    double driverAllowancePerDay = 1200,
    double jeepCost = 0,
    double profitPercentage = 15,
    double advancePercentage = 30,
  }) {
    final Map<String, double> quotation =
        calculatePrivateTour(
      vehiclePerDay:
          vehiclePerDay,
      numberOfDays:
          numberOfDays,
      hotelPerNight:
          hotelPerNight,
      numberOfRooms:
          numberOfRooms,
      numberOfNights:
          numberOfNights,
      driverAllowancePerDay:
          driverAllowancePerDay,
      jeepCost:
          jeepCost,
      profitPercentage:
          profitPercentage,
    );

    final double finalPrice =
        quotation['finalPrice'] ?? 0;

    final double advance =
        calculateAdvancePayment(
      finalPrice:
          finalPrice,
      advancePercentage:
          advancePercentage,
    );

    final double remaining =
        calculateRemainingPayment(
      finalPrice:
          finalPrice,
      advancePaid:
          advance,
    );

    return <String, dynamic>{
      ...quotation,
      'advancePercentage':
          advancePercentage,
      'advanceAmount':
          advance,
      'remainingAmount':
          remaining,
    };
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime? _readNullableDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
