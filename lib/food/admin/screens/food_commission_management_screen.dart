// lib/food/admin/screens/food_commission_management_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Admin Food Commission Management Screen
//
// Connected with:
// - Cloud Firestore
// - RestaurantPartnerModel
// - RestaurantPartnerService
// - FoodDeliveryRiderModel
// - FoodDeliveryRiderService
//
// Real features:
// - Global Food commission settings
// - Restaurant-specific commission updates
// - Rider-specific commission updates
// - Rider outstanding cash commission summary
// - Rider total commission paid summary
// - Rider commission settlement
// - Search and live Firestore updates
//
// Real payment-gateway collection remains bypassed.
// Firestore commission rules and settlements remain enabled.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../restaurant_partner/models/restaurant_partner_model.dart';
import '../../restaurant_partner/services/restaurant_partner_service.dart';
import '../../rider/models/food_delivery_rider_model.dart';
import '../../rider/services/food_delivery_rider_service.dart';

enum _CommissionSection {
  overview,
  restaurants,
  riders,
}

class FoodCommissionManagementScreen extends StatefulWidget {
  const FoodCommissionManagementScreen({
    super.key,
  });

  @override
  State<FoodCommissionManagementScreen> createState() =>
      _FoodCommissionManagementScreenState();
}

class _FoodCommissionManagementScreenState
    extends State<FoodCommissionManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  static const String settingsCollection =
      'food_admin_settings';

  static const String commissionDocument =
      'commission_settings';

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final RestaurantPartnerService _partnerService =
      RestaurantPartnerService();

  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  final TextEditingController _searchController =
      TextEditingController();

  _CommissionSection _selectedSection =
      _CommissionSection.overview;

  String _searchText = '';
  bool _isUpdating = false;

  DocumentReference<Map<String, dynamic>>
      get _commissionSettingsRef => _firestore
          .collection(settingsCollection)
          .doc(commissionDocument);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Stream<_FoodCommissionSettings>
      _watchCommissionSettings() {
    return _commissionSettingsRef.snapshots().map(
      (
        DocumentSnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        return _FoodCommissionSettings.fromMap(
          snapshot.data() ??
              const <String, dynamic>{},
        );
      },
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await action();
      _showMessage(successMessage);
    } on RestaurantPartnerServiceException
        catch (error) {
      _showMessage(error.message);
    } on FoodDeliveryRiderServiceException
        catch (error) {
      _showMessage(error.message);
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to update commission settings.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update commission: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  List<RestaurantPartnerModel> _filterRestaurants(
    List<RestaurantPartnerModel> partners,
  ) {
    final String query =
        _searchText.trim().toLowerCase();

    final List<RestaurantPartnerModel> approved =
        partners.where(
      (RestaurantPartnerModel partner) =>
          partner.applicationStatus ==
              RestaurantPartnerApplicationStatus.approved &&
          partner.isApproved &&
          !partner.isBlocked,
    ).toList();

    if (query.isEmpty) {
      return approved;
    }

    return approved.where(
      (RestaurantPartnerModel partner) {
        final String searchable = <String>[
          partner.restaurantName,
          partner.ownerName,
          partner.phoneNumber,
          partner.city,
          partner.area,
          partner.commissionPercentage.toString(),
        ].join(' ').toLowerCase();

        return searchable.contains(query);
      },
    ).toList();
  }

  List<FoodDeliveryRiderModel> _filterRiders(
    List<FoodDeliveryRiderModel> riders,
  ) {
    final String query =
        _searchText.trim().toLowerCase();

    final List<FoodDeliveryRiderModel> approved =
        riders.where(
      (FoodDeliveryRiderModel rider) =>
          rider.status ==
              FoodDeliveryRiderStatus.approved &&
          rider.isApproved &&
          !rider.isSuspended,
    ).toList();

    if (query.isEmpty) {
      return approved;
    }

    return approved.where(
      (FoodDeliveryRiderModel rider) {
        final String searchable = <String>[
          rider.fullName,
          rider.phoneNumber,
          rider.city,
          rider.registrationNumber,
          rider.commissionPercentage.toString(),
          rider.outstandingCommission.toString(),
          rider.totalCommissionPaid.toString(),
        ].join(' ').toLowerCase();

        return searchable.contains(query);
      },
    ).toList();
  }

  double _restaurantAverage(
    List<RestaurantPartnerModel> partners,
  ) {
    if (partners.isEmpty) {
      return 0;
    }

    final double total = partners.fold<double>(
      0,
      (
        double sum,
        RestaurantPartnerModel partner,
      ) =>
          sum + partner.commissionPercentage,
    );

    return total / partners.length;
  }

  double _riderAverage(
    List<FoodDeliveryRiderModel> riders,
  ) {
    if (riders.isEmpty) {
      return 0;
    }

    final double total = riders.fold<double>(
      0,
      (
        double sum,
        FoodDeliveryRiderModel rider,
      ) =>
          sum + rider.commissionPercentage,
    );

    return total / riders.length;
  }

  double _totalOutstanding(
    List<FoodDeliveryRiderModel> riders,
  ) {
    return riders.fold<double>(
      0,
      (
        double total,
        FoodDeliveryRiderModel rider,
      ) =>
          total + rider.outstandingCommission,
    );
  }

  double _totalCommissionPaid(
    List<FoodDeliveryRiderModel> riders,
  ) {
    return riders.fold<double>(
      0,
      (
        double total,
        FoodDeliveryRiderModel rider,
      ) =>
          total + rider.totalCommissionPaid,
    );
  }

  Future<double?> _requestPercentage({
    required String title,
    required double currentValue,
  }) async {
    final TextEditingController controller =
        TextEditingController(
      text: currentValue.toStringAsFixed(0),
    );

    final double? value = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Commission percentage',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? parsed =
                    double.tryParse(
                  controller.text.trim(),
                );

                if (parsed == null ||
                    parsed < 0 ||
                    parsed > 100) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  parsed,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return value;
  }

  Future<void> _updateGlobalSettings(
    _FoodCommissionSettings settings,
  ) async {
    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>();

    final TextEditingController restaurantController =
        TextEditingController(
      text: settings
          .defaultRestaurantCommission
          .toStringAsFixed(0),
    );

    final TextEditingController riderController =
        TextEditingController(
      text: settings
          .defaultRiderCommission
          .toStringAsFixed(0),
    );

    final TextEditingController serviceFeeController =
        TextEditingController(
      text: settings.defaultServiceFee
          .toStringAsFixed(0),
    );

    final _FoodCommissionSettings? updated =
        await showDialog<_FoodCommissionSettings>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Global Food Commission Settings',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _numberField(
                    controller:
                        restaurantController,
                    label:
                        'Default restaurant commission',
                    suffix: '%',
                    maxValue: 100,
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: riderController,
                    label:
                        'Default rider commission',
                    suffix: '%',
                    maxValue: 100,
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller:
                        serviceFeeController,
                    label:
                        'Default customer service fee',
                    suffix: 'Rs.',
                    maxValue: 100000,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final bool valid =
                    formKey.currentState
                            ?.validate() ??
                        false;

                if (!valid) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  settings.copyWith(
                    defaultRestaurantCommission:
                        double.parse(
                      restaurantController.text
                          .trim(),
                    ),
                    defaultRiderCommission:
                        double.parse(
                      riderController.text.trim(),
                    ),
                    defaultServiceFee:
                        double.parse(
                      serviceFeeController.text
                          .trim(),
                    ),
                    updatedAt: DateTime.now(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Save Settings'),
            ),
          ],
        );
      },
    );

    restaurantController.dispose();
    riderController.dispose();
    serviceFeeController.dispose();

    if (updated == null) {
      return;
    }

    await _runAction(
      () => _commissionSettingsRef.set(
        updated.toMap(),
        SetOptions(merge: true),
      ),
      'Global Food commission settings updated.',
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required double maxValue,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (String? value) {
        final double? parsed =
            double.tryParse(value?.trim() ?? '');

        if (parsed == null) {
          return 'Enter a valid number';
        }

        if (parsed < 0 || parsed > maxValue) {
          return 'Enter value between 0 and $maxValue';
        }

        return null;
      },
    );
  }

  Future<void> _updateRestaurantCommission(
    RestaurantPartnerModel partner,
  ) async {
    final double? value =
        await _requestPercentage(
      title:
          'Update ${partner.restaurantName} Commission',
      currentValue:
          partner.commissionPercentage,
    );

    if (value == null) {
      return;
    }

    await _runAction(
      () => _partnerService.updateCommission(
        partnerId: partner.partnerId,
        commissionPercentage: value,
      ),
      'Restaurant commission updated.',
    );
  }

  Future<void> _updateRiderCommission(
    FoodDeliveryRiderModel rider,
  ) async {
    final double? value =
        await _requestPercentage(
      title:
          'Update ${rider.fullName} Commission',
      currentValue:
          rider.commissionPercentage,
    );

    if (value == null) {
      return;
    }

    await _runAction(
      () => _riderService.updateRiderFields(
        riderId: rider.riderId,
        fields: <String, dynamic>{
          'commissionPercentage': value,
        },
      ),
      'Rider commission updated.',
    );
  }

  Future<void> _settleRiderCommission(
    FoodDeliveryRiderModel rider,
  ) async {
    if (rider.outstandingCommission <= 0) {
      _showMessage(
        'This rider has no outstanding commission.',
      );
      return;
    }

    final TextEditingController controller =
        TextEditingController(
      text: rider.outstandingCommission
          .toStringAsFixed(0),
    );

    final double? amount =
        await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Settle Rider Commission',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Outstanding: Rs. ${rider.outstandingCommission.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Previously paid: Rs. ${rider.totalCommissionPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Settlement amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Payment-gateway collection is bypassed. This action records the settlement in Firestore.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? parsed =
                    double.tryParse(
                  controller.text.trim(),
                );

                if (parsed == null ||
                    parsed <= 0 ||
                    parsed >
                        rider
                            .outstandingCommission) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  parsed,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Settle'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (amount == null) {
      return;
    }

    await _runAction(
      () => _riderService
          .settleOutstandingCommission(
        riderId: rider.riderId,
        amount: amount,
      ),
      'Rider commission settlement recorded.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Commission Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child:
            StreamBuilder<_FoodCommissionSettings>(
          stream: _watchCommissionSettings(),
          builder: (
            BuildContext context,
            AsyncSnapshot<_FoodCommissionSettings>
                settingsSnapshot,
          ) {
            final _FoodCommissionSettings settings =
                settingsSnapshot.data ??
                    _FoodCommissionSettings.defaults();

            return StreamBuilder<
                List<RestaurantPartnerModel>>(
              stream: _partnerService
                  .watchAllApplications(),
              builder: (
                BuildContext context,
                AsyncSnapshot<
                        List<RestaurantPartnerModel>>
                    partnerSnapshot,
              ) {
                return StreamBuilder<
                    List<FoodDeliveryRiderModel>>(
                  stream: _riderService
                      .watchAllApplications(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<
                            List<FoodDeliveryRiderModel>>
                        riderSnapshot,
                  ) {
                    if ((settingsSnapshot
                                    .connectionState ==
                                ConnectionState.waiting ||
                            partnerSnapshot
                                    .connectionState ==
                                ConnectionState.waiting ||
                            riderSnapshot
                                    .connectionState ==
                                ConnectionState.waiting) &&
                        !settingsSnapshot.hasData &&
                        !partnerSnapshot.hasData &&
                        !riderSnapshot.hasData) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color: yellow,
                        ),
                      );
                    }

                    if (settingsSnapshot.hasError ||
                        partnerSnapshot.hasError ||
                        riderSnapshot.hasError) {
                      return _buildErrorState();
                    }

                    final List<
                            RestaurantPartnerModel>
                        allPartners =
                        partnerSnapshot.data ??
                            const <
                                RestaurantPartnerModel>[];

                    final List<
                            FoodDeliveryRiderModel>
                        allRiders =
                        riderSnapshot.data ??
                            const <
                                FoodDeliveryRiderModel>[];

                    final List<
                            RestaurantPartnerModel>
                        approvedPartners =
                        _filterRestaurants(
                      allPartners,
                    );

                    final List<
                            FoodDeliveryRiderModel>
                        approvedRiders =
                        _filterRiders(
                      allRiders,
                    );

                    return RefreshIndicator(
                      color: yellow,
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          30,
                        ),
                        children: <Widget>[
                          _buildHeader(
                            settings: settings,
                            partners: allPartners,
                            riders: allRiders,
                          ),
                          const SizedBox(height: 16),
                          _buildSectionSelector(),
                          const SizedBox(height: 16),
                          if (_selectedSection !=
                              _CommissionSection
                                  .overview)
                            _buildSearchField(),
                          if (_selectedSection !=
                              _CommissionSection
                                  .overview)
                            const SizedBox(height: 16),
                          if (_selectedSection ==
                              _CommissionSection
                                  .overview)
                            _buildOverview(
                              settings: settings,
                              partners: allPartners,
                              riders: allRiders,
                            )
                          else if (_selectedSection ==
                              _CommissionSection
                                  .restaurants)
                            _buildRestaurantList(
                              approvedPartners,
                            )
                          else
                            _buildRiderList(
                              approvedRiders,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required _FoodCommissionSettings settings,
    required List<RestaurantPartnerModel> partners,
    required List<FoodDeliveryRiderModel> riders,
  }) {
    final double outstanding =
        _totalOutstanding(riders);

    final double commissionPaid =
        _totalCommissionPaid(riders);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.percent,
              color: yellow,
              size: 34,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Food Commissions',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Restaurant ${settings.defaultRestaurantCommission.toStringAsFixed(0)}% • '
                  'Rider ${settings.defaultRiderCommission.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Outstanding: Rs. ${outstanding.toStringAsFixed(0)} • '
                  'Paid: Rs. ${commissionPaid.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Global settings',
            onPressed: _isUpdating
                ? null
                : () => _updateGlobalSettings(
                      settings,
                    ),
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector() {
    final List<_CommissionSectionItem> items =
        <_CommissionSectionItem>[
      const _CommissionSectionItem(
        section: _CommissionSection.overview,
        label: 'Overview',
      ),
      const _CommissionSectionItem(
        section:
            _CommissionSection.restaurants,
        label: 'Restaurants',
      ),
      const _CommissionSectionItem(
        section: _CommissionSection.riders,
        label: 'Riders',
      ),
    ];

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final _CommissionSectionItem item =
              items[index];

          final bool selected =
              _selectedSection == item.section;

          return ChoiceChip(
            label: Text(item.label),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedSection = item.section;
                _searchController.clear();
                _searchText = '';
              });
            },
            selectedColor: yellow,
            backgroundColor: cardColor,
            checkmarkColor: Colors.black,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (String value) {
        setState(() {
          _searchText = value;
        });
      },
      decoration: InputDecoration(
        hintText: _selectedSection ==
                _CommissionSection.restaurants
            ? 'Search restaurant or owner'
            : 'Search rider, phone or vehicle',
        prefixIcon: const Icon(
          Icons.search,
          color: yellow,
        ),
        suffixIcon: _searchText.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _searchText = '';
                  });
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildOverview({
    required _FoodCommissionSettings settings,
    required List<RestaurantPartnerModel> partners,
    required List<FoodDeliveryRiderModel> riders,
  }) {
    final List<RestaurantPartnerModel>
        approvedPartners =
        partners.where(
      (RestaurantPartnerModel partner) =>
          partner.applicationStatus ==
              RestaurantPartnerApplicationStatus
                  .approved &&
          partner.isApproved &&
          !partner.isBlocked,
    ).toList();

    final List<FoodDeliveryRiderModel>
        approvedRiders =
        riders.where(
      (FoodDeliveryRiderModel rider) =>
          rider.status ==
              FoodDeliveryRiderStatus.approved &&
          rider.isApproved &&
          !rider.isSuspended,
    ).toList();

    final double outstanding =
        _totalOutstanding(approvedRiders);

    final double commissionPaid =
        _totalCommissionPaid(approvedRiders);

    final List<_CommissionStat> stats =
        <_CommissionStat>[
      _CommissionStat(
        title: 'Default Restaurant',
        value:
            '${settings.defaultRestaurantCommission.toStringAsFixed(0)}%',
        icon: Icons.storefront_outlined,
      ),
      _CommissionStat(
        title: 'Default Rider',
        value:
            '${settings.defaultRiderCommission.toStringAsFixed(0)}%',
        icon: Icons.delivery_dining,
      ),
      _CommissionStat(
        title: 'Restaurant Average',
        value:
            '${_restaurantAverage(approvedPartners).toStringAsFixed(1)}%',
        icon: Icons.analytics_outlined,
      ),
      _CommissionStat(
        title: 'Rider Average',
        value:
            '${_riderAverage(approvedRiders).toStringAsFixed(1)}%',
        icon: Icons.trending_up,
      ),
      _CommissionStat(
        title: 'Service Fee',
        value:
            'Rs. ${settings.defaultServiceFee.toStringAsFixed(0)}',
        icon: Icons.receipt_long_outlined,
      ),
      _CommissionStat(
        title: 'Outstanding',
        value:
            'Rs. ${outstanding.toStringAsFixed(0)}',
        icon: Icons.warning_amber_outlined,
      ),
      _CommissionStat(
        title: 'Commission Paid',
        value:
            'Rs. ${commissionPaid.toStringAsFixed(0)}',
        icon: Icons.verified_outlined,
      ),
    ];

    return Column(
      children: <Widget>[
        GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            final _CommissionStat stat =
                stats[index];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    BorderRadius.circular(19),
                border: Border.all(
                  color: Colors.white10,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Icon(
                    stat.icon,
                    color: yellow,
                    size: 27,
                  ),
                  Text(
                    stat.value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat.title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: outstanding > 0
                  ? Colors.orangeAccent
                      .withValues(alpha: 0.55)
                  : Colors.greenAccent
                      .withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor:
                    (outstanding > 0
                            ? Colors.orangeAccent
                            : Colors.greenAccent)
                        .withValues(alpha: 0.14),
                child: Icon(
                  outstanding > 0
                      ? Icons
                          .warning_amber_outlined
                      : Icons
                          .check_circle_outline,
                  color: outstanding > 0
                      ? Colors.orangeAccent
                      : Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      outstanding > 0
                          ? 'Cash commission pending'
                          : 'All rider commissions clear',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      outstanding > 0
                          ? 'Rs. ${outstanding.toStringAsFixed(0)} remains outstanding from cash food deliveries. '
                              'Total commission paid: Rs. ${commissionPaid.toStringAsFixed(0)}.'
                          : 'No outstanding rider commission is recorded. '
                              'Total commission paid: Rs. ${commissionPaid.toStringAsFixed(0)}.',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantList(
    List<RestaurantPartnerModel> partners,
  ) {
    if (partners.isEmpty) {
      return _buildEmptyState(
        icon: Icons.storefront_outlined,
        title: 'No approved restaurants found',
        message:
            'Approved restaurant partners will appear here.',
      );
    }

    return Column(
      children: partners.map(
        (RestaurantPartnerModel partner) {
          return Padding(
            padding:
                const EdgeInsets.only(bottom: 12),
            child: _CommissionEntityCard(
              title: partner.restaurantName,
              subtitle:
                  '${partner.ownerName} • ${partner.city}',
              commission:
                  partner.commissionPercentage,
              icon: Icons.storefront_outlined,
              trailingText:
                  '${partner.totalOrders} orders',
              onEdit: _isUpdating
                  ? null
                  : () =>
                      _updateRestaurantCommission(
                        partner,
                      ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildRiderList(
    List<FoodDeliveryRiderModel> riders,
  ) {
    if (riders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.delivery_dining,
        title: 'No approved riders found',
        message:
            'Approved Food Delivery Riders will appear here.',
      );
    }

    return Column(
      children: riders.map(
        (FoodDeliveryRiderModel rider) {
          return Padding(
            padding:
                const EdgeInsets.only(bottom: 12),
            child: _CommissionEntityCard(
              title: rider.fullName,
              subtitle:
                  '${rider.vehicleType.displayName} • ${rider.city}',
              commission:
                  rider.commissionPercentage,
              icon: Icons.delivery_dining,
              trailingText:
                  'Due Rs. ${rider.outstandingCommission.toStringAsFixed(0)} • '
                  'Paid Rs. ${rider.totalCommissionPaid.toStringAsFixed(0)}',
              warning:
                  rider.outstandingCommission > 0,
              onEdit: _isUpdating
                  ? null
                  : () =>
                      _updateRiderCommission(rider),
              onSettle:
                  rider.outstandingCommission > 0 &&
                          !_isUpdating
                      ? () =>
                          _settleRiderCommission(
                            rider,
                          )
                      : null,
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color: yellow,
            size: 64,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.cloud_off,
              color: Colors.redAccent,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load commission data',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check Firestore connection, rules and indexes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionEntityCard extends StatelessWidget {
  const _CommissionEntityCard({
    required this.title,
    required this.subtitle,
    required this.commission,
    required this.icon,
    required this.trailingText,
    required this.onEdit,
    this.onSettle,
    this.warning = false,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final String title;
  final String subtitle;
  final double commission;
  final IconData icon;
  final String trailingText;
  final VoidCallback? onEdit;
  final VoidCallback? onSettle;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: warning
              ? Colors.orangeAccent
                  .withValues(alpha: 0.55)
              : Colors.white10,
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor:
                    yellow.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: yellow,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      yellow.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  '${commission.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  trailingText,
                  style: TextStyle(
                    color: warning
                        ? Colors.orangeAccent
                        : Colors.grey,
                    fontSize: 11,
                    fontWeight: warning
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (onSettle != null)
                TextButton(
                  onPressed: onSettle,
                  child: const Text(
                    'Settle',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: yellow,
                  size: 18,
                ),
                label: const Text(
                  'Edit',
                  style: TextStyle(
                    color: yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodCommissionSettings {
  const _FoodCommissionSettings({
    required this.defaultRestaurantCommission,
    required this.defaultRiderCommission,
    required this.defaultServiceFee,
    required this.updatedAt,
  });

  final double defaultRestaurantCommission;
  final double defaultRiderCommission;
  final double defaultServiceFee;
  final DateTime updatedAt;

  factory _FoodCommissionSettings.defaults() {
    return _FoodCommissionSettings(
      defaultRestaurantCommission: 15,
      defaultRiderCommission: 10,
      defaultServiceFee: 20,
      updatedAt: DateTime.now(),
    );
  }

  factory _FoodCommissionSettings.fromMap(
    Map<String, dynamic> map,
  ) {
    return _FoodCommissionSettings(
      defaultRestaurantCommission:
          _doubleValue(
        map['defaultRestaurantCommission'],
        fallback: 15,
      ),
      defaultRiderCommission:
          _doubleValue(
        map['defaultRiderCommission'],
        fallback: 10,
      ),
      defaultServiceFee: _doubleValue(
        map['defaultServiceFee'],
        fallback: 20,
      ),
      updatedAt: _dateTimeValue(
            map['updatedAt'],
          ) ??
          DateTime.now(),
    );
  }

  _FoodCommissionSettings copyWith({
    double? defaultRestaurantCommission,
    double? defaultRiderCommission,
    double? defaultServiceFee,
    DateTime? updatedAt,
  }) {
    return _FoodCommissionSettings(
      defaultRestaurantCommission:
          defaultRestaurantCommission ??
              this.defaultRestaurantCommission,
      defaultRiderCommission:
          defaultRiderCommission ??
              this.defaultRiderCommission,
      defaultServiceFee:
          defaultServiceFee ??
              this.defaultServiceFee,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'defaultRestaurantCommission':
          defaultRestaurantCommission,
      'defaultRiderCommission':
          defaultRiderCommission,
      'defaultServiceFee':
          defaultServiceFee,
      'updatedAt':
          updatedAt.toIso8601String(),
    };
  }

  static double _doubleValue(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static DateTime? _dateTimeValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final dynamic converted =
          value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Firestore Timestamp support.
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}

class _CommissionSectionItem {
  const _CommissionSectionItem({
    required this.section,
    required this.label,
  });

  final _CommissionSection section;
  final String label;
}

class _CommissionStat {
  const _CommissionStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}
