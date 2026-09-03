// lib/food/admin/screens/food_rider_management_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Admin Food Delivery Rider Management Screen
//
// Connected with:
// - FoodDeliveryRiderModel
// - FoodDeliveryRiderService
//
// Real features:
// - Live Firestore rider applications
// - Search and status filters
// - Approve rider
// - Reject rider with reason
// - Suspend approved rider
// - Restore suspended rider
// - Set commission percentage
// - Rider profile/details preview
//
// Firebase Storage remains bypassed.
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../rider/models/food_delivery_rider_model.dart';
import '../../rider/services/food_delivery_rider_service.dart';

enum _FoodRiderAdminFilter {
  all,
  pending,
  approved,
  rejected,
  suspended,
}

class FoodRiderManagementScreen extends StatefulWidget {
  const FoodRiderManagementScreen({
    super.key,
  });

  @override
  State<FoodRiderManagementScreen> createState() =>
      _FoodRiderManagementScreenState();
}

class _FoodRiderManagementScreenState
    extends State<FoodRiderManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  final TextEditingController _searchController =
      TextEditingController();

  _FoodRiderAdminFilter _selectedFilter =
      _FoodRiderAdminFilter.all;

  String _searchText = '';
  bool _isUpdating = false;

  String get _currentAdminId =>
      FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

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
        SnackBar(
          content: Text(message),
        ),
      );
  }

  List<FoodDeliveryRiderModel> _filterRiders(
    List<FoodDeliveryRiderModel> riders,
  ) {
    final String query =
        _searchText.trim().toLowerCase();

    return riders.where(
      (FoodDeliveryRiderModel rider) {
        final bool statusMatches;

        switch (_selectedFilter) {
          case _FoodRiderAdminFilter.all:
            statusMatches = true;
            break;
          case _FoodRiderAdminFilter.pending:
            statusMatches =
                rider.status ==
                    FoodDeliveryRiderStatus.pending ||
                rider.status ==
                    FoodDeliveryRiderStatus.underReview;
            break;
          case _FoodRiderAdminFilter.approved:
            statusMatches =
                rider.status ==
                    FoodDeliveryRiderStatus.approved &&
                !rider.isSuspended;
            break;
          case _FoodRiderAdminFilter.rejected:
            statusMatches =
                rider.status ==
                    FoodDeliveryRiderStatus.rejected;
            break;
          case _FoodRiderAdminFilter.suspended:
            statusMatches =
                rider.status ==
                    FoodDeliveryRiderStatus.suspended ||
                rider.isSuspended;
            break;
        }

        if (!statusMatches) {
          return false;
        }

        if (query.isEmpty) {
          return true;
        }

        final String searchable = <String>[
          rider.fullName,
          rider.phoneNumber,
          rider.email,
          rider.cnicNumber,
          rider.city,
          rider.area,
          rider.registrationNumber,
          rider.vehicleMake,
          rider.vehicleModel,
          rider.status.value,
        ].join(' ').toLowerCase();

        return searchable.contains(query);
      },
    ).toList();
  }

  int _countForFilter(
    List<FoodDeliveryRiderModel> riders,
    _FoodRiderAdminFilter filter,
  ) {
    switch (filter) {
      case _FoodRiderAdminFilter.all:
        return riders.length;

      case _FoodRiderAdminFilter.pending:
        return riders.where(
          (FoodDeliveryRiderModel rider) =>
              rider.status ==
                  FoodDeliveryRiderStatus.pending ||
              rider.status ==
                  FoodDeliveryRiderStatus.underReview,
        ).length;

      case _FoodRiderAdminFilter.approved:
        return riders.where(
          (FoodDeliveryRiderModel rider) =>
              rider.status ==
                  FoodDeliveryRiderStatus.approved &&
              !rider.isSuspended,
        ).length;

      case _FoodRiderAdminFilter.rejected:
        return riders.where(
          (FoodDeliveryRiderModel rider) =>
              rider.status ==
              FoodDeliveryRiderStatus.rejected,
        ).length;

      case _FoodRiderAdminFilter.suspended:
        return riders.where(
          (FoodDeliveryRiderModel rider) =>
              rider.status ==
                  FoodDeliveryRiderStatus.suspended ||
              rider.isSuspended,
        ).length;
    }
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
    } on FoodDeliveryRiderServiceException
        catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(
        'Unable to update rider: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _approveRider(
    FoodDeliveryRiderModel rider,
  ) async {
    final TextEditingController controller =
        TextEditingController(
      text: rider.commissionPercentage > 0
          ? rider.commissionPercentage
              .toStringAsFixed(0)
          : '10',
    );

    final double? commission =
        await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Approve Food Rider',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                rider.fullName,
                style: const TextStyle(
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
                decoration: InputDecoration(
                  labelText:
                      'Admin commission percentage',
                  hintText: '10',
                  suffixText: '%',
                  filled: true,
                  fillColor: const Color(0xFF252525),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
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
                final double? value =
                    double.tryParse(
                  controller.text.trim(),
                );

                if (value == null ||
                    value < 0 ||
                    value > 100) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (commission == null) {
      return;
    }

    await _runAction(
      () => _riderService.approveRider(
        riderId: rider.riderId,
        commissionPercentage: commission,
        reviewedBy: _currentAdminId,
      ),
      'Food delivery rider approved.',
    );
  }

  Future<void> _rejectRider(
    FoodDeliveryRiderModel rider,
  ) async {
    final String? reason =
        await _requestReason(
      title: 'Reject Rider',
      hint:
          'Enter the reason for rejecting this application',
      actionLabel: 'Reject',
    );

    if (reason == null) {
      return;
    }

    await _runAction(
      () => _riderService.rejectRider(
        riderId: rider.riderId,
        reason: reason,
        reviewedBy: _currentAdminId,
      ),
      'Food rider application rejected.',
    );
  }

  Future<void> _requestRiderCorrection(
    FoodDeliveryRiderModel rider,
  ) async {
    final String? note = await _requestReason(
      title: 'Request Rider Correction',
      hint:
          'Explain which Rider details or documents must be corrected',
      actionLabel: 'Request Correction',
    );

    if (note == null) return;

    await _runAction(
      () => _riderService.requestRiderApplicationCorrection(
        riderId: rider.riderId,
        correctionNote: note,
        reviewedBy: _currentAdminId,
      ),
      'Correction requested from Food Rider.',
    );
  }

  Future<void> _resetRiderApplicationForReview(
    FoodDeliveryRiderModel rider,
  ) async {
    await _runAction(
      () => _riderService.resetRiderApplicationForReview(
        riderId: rider.riderId,
        reviewedBy: _currentAdminId,
      ),
      'Rider application reset to pending review.',
    );
  }
  Future<void> _suspendRider(
    FoodDeliveryRiderModel rider,
  ) async {
    if (rider.isOnDelivery) {
      _showMessage(
        'Rider cannot be suspended during an active delivery.',
      );
      return;
    }

    final String? reason =
        await _requestReason(
      title: 'Suspend Rider',
      hint:
          'Enter the reason for suspending this rider',
      actionLabel: 'Suspend',
    );

    if (reason == null) {
      return;
    }

    await _runAction(
      () => _riderService.suspendRider(
        riderId: rider.riderId,
        reason: reason,
        reviewedBy: _currentAdminId,
      ),
      'Food delivery rider suspended.',
    );
  }

  Future<String?> _requestReason({
    required String title,
    required String hint,
    required String actionLabel,
  }) async {
    final TextEditingController controller =
        TextEditingController();

    final String? reason =
        await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(title),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Reason',
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFF252525),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
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
                final String value =
                    controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return reason;
  }

  void _showRiderDetails(
    FoodDeliveryRiderModel rider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (
              BuildContext context,
              ScrollController scrollController,
            ) {
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      const CircleAvatar(
                        radius: 31,
                        backgroundColor:
                            Color(0xFF252525),
                        child: Icon(
                          Icons.delivery_dining,
                          color: yellow,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              rider.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rider.status.displayName,
                              style: TextStyle(
                                color: _statusColor(
                                  rider.status,
                                ),
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailsCard(
                    title: 'Personal Details',
                    children: <Widget>[
                      _InfoRow(
                        label: 'Phone',
                        value: rider.phoneNumber,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Email',
                        value: rider.email,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'CNIC',
                        value: rider.cnicNumber,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Date of Birth',
                        value: _dateText(
                          rider.dateOfBirth,
                        ),
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Age',
                        value: _ageText(
                          rider.dateOfBirth,
                        ),
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Address',
                        value:
                            '${rider.completeAddress}, ${rider.area}, ${rider.city}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailsCard(
                    title: 'Vehicle Details',
                    children: <Widget>[
                      _InfoRow(
                        label: 'Type',
                        value:
                            rider.vehicleType.displayName,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Vehicle',
                        value:
                            '${rider.vehicleMake} ${rider.vehicleModel}',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Color',
                        value: rider.vehicleColor,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Registration',
                        value:
                            rider.registrationNumber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailsCard(
                    title: 'Live Rider Status',
                    children: <Widget>[
                      _InfoRow(
                        label: 'Online',
                        value: rider.isOnline
                            ? 'Yes'
                            : 'No',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Availability',
                        value: rider.isOnDelivery
                            ? 'On Delivery'
                            : rider.isAvailable
                                ? 'Available'
                                : 'Busy / Offline',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Current Order',
                        value: rider.currentOrderId
                                .trim()
                                .isEmpty
                            ? 'No active order'
                            : rider.currentOrderId,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Location',
                        value: rider.hasLiveLocation
                            ? '${rider.currentLatitude.toStringAsFixed(6)}, '
                                '${rider.currentLongitude.toStringAsFixed(6)}'
                            : 'Not available',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailsCard(
                    title: 'Performance',
                    children: <Widget>[
                      _InfoRow(
                        label: 'Rating',
                        value:
                            rider.rating.toStringAsFixed(1),
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Completed',
                        value:
                            '${rider.completedDeliveries}',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Cancelled',
                        value:
                            '${rider.cancelledDeliveries}',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Commission',
                        value:
                            '${rider.commissionPercentage.toStringAsFixed(0)}%',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Total Earnings',
                        value:
                            'Rs. ${rider.totalEarnings.toStringAsFixed(0)}',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Wallet Balance',
                        value:
                            'Rs. ${rider.walletBalance.toStringAsFixed(0)}',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Outstanding Commission',
                        value:
                            'Rs. ${rider.outstandingCommission.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailsCard(
                    title: 'Documents',
                    children: <Widget>[
                      _documentLine(
                        'Profile Image',
                        rider.profileLocalImagePath,
                      ),
                      _documentLine(
                        'CNIC Front',
                        rider.cnicFrontLocalPath,
                      ),
                      _documentLine(
                        'CNIC Back',
                        rider.cnicBackLocalPath,
                      ),
                      _documentLine(
                        'Driving License Front',
                        rider
                            .drivingLicenseFrontLocalPath,
                      ),
                      _documentLine(
                        'Driving License Back',
                        rider
                            .drivingLicenseBackLocalPath,
                      ),
                      _documentLine(
                        'Vehicle Registration',
                        rider
                            .vehicleRegistrationLocalPath,
                      ),
                      _documentLine(
                        'Vehicle Photo',
                        rider.vehiclePhotoLocalPath,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Document images are currently stored as local paths. '
                    'Admin image preview will work across devices after '
                    'Firebase Storage billing is enabled.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildDetailActions(rider),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailActions(
    FoodDeliveryRiderModel rider,
  ) {
    if (rider.status ==
            FoodDeliveryRiderStatus.pending ||
        rider.status ==
            FoodDeliveryRiderStatus.underReview) {
      return Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () {
                      Navigator.pop(context);
                      _requestRiderCorrection(rider);
                    },
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Request Correction'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
                side: const BorderSide(
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          Navigator.pop(context);
                          _rejectRider(rider);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(
                      color: Colors.redAccent,
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          Navigator.pop(context);
                          _approveRider(rider);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (rider.status ==
        FoodDeliveryRiderStatus.rejected) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () {
                  Navigator.pop(context);
                  _resetRiderApplicationForReview(rider);
                },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset for Review'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }
    if (rider.status ==
            FoodDeliveryRiderStatus.suspended ||
        rider.isSuspended) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isUpdating
              ? null
              : () {
                  Navigator.pop(context);
                  _runAction(
                    () => _riderService.restoreRider(
                      rider.riderId,
                      reviewedBy: _currentAdminId,
                    ),
                    'Food delivery rider restored.',
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
          ),
          child: const Text('Restore Rider'),
        ),
      );
    }

    if (rider.status ==
        FoodDeliveryRiderStatus.approved) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isUpdating
              ? null
              : () {
                  Navigator.pop(context);
                  _suspendRider(rider);
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(
              color: Colors.redAccent,
            ),
          ),
          child: const Text('Suspend Rider'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Rider Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            List<FoodDeliveryRiderModel>>(
          stream:
              _riderService.watchAllApplications(),
          builder: (
            BuildContext context,
            AsyncSnapshot<
                    List<FoodDeliveryRiderModel>>
                snapshot,
          ) {
            if (snapshot.connectionState ==
                    ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final List<FoodDeliveryRiderModel>
                allRiders =
                snapshot.data ??
                    const <
                        FoodDeliveryRiderModel>[];

            final List<FoodDeliveryRiderModel>
                visibleRiders =
                _filterRiders(allRiders);

            return Column(
              children: <Widget>[
                _buildSummary(allRiders),
                _buildSearchField(),
                _buildFilters(allRiders),
                Expanded(
                  child: visibleRiders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: yellow,
                          onRefresh: () async {
                            setState(() {});
                          },
                          child: ListView.separated(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              10,
                              16,
                              30,
                            ),
                            itemCount:
                                visibleRiders.length,
                            separatorBuilder: (
                              BuildContext context,
                              int index,
                            ) =>
                                const SizedBox(
                              height: 12,
                            ),
                            itemBuilder: (
                              BuildContext context,
                              int index,
                            ) {
                              final FoodDeliveryRiderModel
                                  rider =
                                  visibleRiders[index];

                              return _FoodRiderAdminCard(
                                rider: rider,
                                isUpdating:
                                    _isUpdating,
                                onTap: () =>
                                    _showRiderDetails(
                                  rider,
                                ),
                                onApprove:
                                    rider.status ==
                                                FoodDeliveryRiderStatus
                                                    .pending ||
                                            rider.status ==
                                                FoodDeliveryRiderStatus
                                                    .underReview
                                        ? () =>
                                            _approveRider(
                                              rider,
                                            )
                                        : null,
                                onReject:
                                    rider.status ==
                                                FoodDeliveryRiderStatus
                                                    .pending ||
                                            rider.status ==
                                                FoodDeliveryRiderStatus
                                                    .underReview
                                        ? () =>
                                            _rejectRider(
                                              rider,
                                            )
                                        : null,
                                onSuspend:
                                    rider.status ==
                                            FoodDeliveryRiderStatus
                                                .approved
                                        ? () =>
                                            _suspendRider(
                                              rider,
                                            )
                                        : null,
                                onRestore:
                                    rider.status ==
                                                FoodDeliveryRiderStatus
                                                    .suspended ||
                                            rider.isSuspended
                                        ? () =>
                                            _runAction(
                                              () =>
                                                  _riderService
                                                      .restoreRider(
                                                rider.riderId,
                                                reviewedBy:
                                                    _currentAdminId,
                                              ),
                                              'Food delivery rider restored.',
                                            )
                                        : null,
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(
    List<FoodDeliveryRiderModel> riders,
  ) {
    final int pending = _countForFilter(
      riders,
      _FoodRiderAdminFilter.pending,
    );

    final int approved = _countForFilter(
      riders,
      _FoodRiderAdminFilter.approved,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        10,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 29,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.delivery_dining,
              color: yellow,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Food Delivery Riders',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pending pending Ã¢â‚¬Â¢ $approved approved',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${riders.length}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (String value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText:
              'Search rider, phone, CNIC or vehicle',
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
      ),
    );
  }

  Widget _buildFilters(
    List<FoodDeliveryRiderModel> riders,
  ) {
    final List<_AdminFilterItem> filters =
        <_AdminFilterItem>[
      const _AdminFilterItem(
        filter: _FoodRiderAdminFilter.all,
        label: 'All',
      ),
      const _AdminFilterItem(
        filter: _FoodRiderAdminFilter.pending,
        label: 'Pending',
      ),
      const _AdminFilterItem(
        filter: _FoodRiderAdminFilter.approved,
        label: 'Approved',
      ),
      const _AdminFilterItem(
        filter: _FoodRiderAdminFilter.rejected,
        label: 'Rejected',
      ),
      const _AdminFilterItem(
        filter: _FoodRiderAdminFilter.suspended,
        label: 'Suspended',
      ),
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final _AdminFilterItem item =
              filters[index];

          final bool selected =
              _selectedFilter == item.filter;

          final int count = _countForFilter(
            riders,
            item.filter,
          );

          return ChoiceChip(
            label: Text(
              '${item.label} ($count)',
            ),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = item.filter;
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

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.delivery_dining,
              color: yellow,
              size: 76,
            ),
            SizedBox(height: 16),
            Text(
              'No food riders found',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Food rider applications matching this filter will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
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
              'Unable to load food riders',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check Firestore connection, security rules and indexes.',
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

  Widget _detailsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: yellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }

  Widget _documentLine(
    String title,
    String path,
  ) {
    final bool available =
        path.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            available
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: available
                ? Colors.greenAccent
                : Colors.orangeAccent,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(title),
          ),
          Text(
            available ? 'Available' : 'Missing',
            style: TextStyle(
              color: available
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static String _dateText(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Ã¢â‚¬â€';
    }

    final String day =
        date.day.toString().padLeft(2, '0');
    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _ageText(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Ã¢â‚¬â€';
    }

    final DateTime today = DateTime.now();
    int age = today.year - date.year;

    final bool birthdayPassed =
        today.month > date.month ||
            (today.month == date.month &&
                today.day >= date.day);

    if (!birthdayPassed) {
      age--;
    }

    return age < 0 ? 'Ã¢â‚¬â€' : '$age years';
  }

  static Color _statusColor(
    FoodDeliveryRiderStatus status,
  ) {
    switch (status) {
      case FoodDeliveryRiderStatus.draft:
        return Colors.grey;
      case FoodDeliveryRiderStatus.pending:
      case FoodDeliveryRiderStatus.underReview:
        return Colors.orangeAccent;
      case FoodDeliveryRiderStatus.approved:
        return Colors.greenAccent;
      case FoodDeliveryRiderStatus.rejected:
        return Colors.redAccent;
      case FoodDeliveryRiderStatus.suspended:
        return Colors.deepOrangeAccent;
    }
  }
}

class _FoodRiderAdminCard extends StatelessWidget {
  const _FoodRiderAdminCard({
    required this.rider,
    required this.isUpdating,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onRestore,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodDeliveryRiderModel rider;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onSuspend;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        _FoodDeliveryRiderManagementCardStatus
            .color(rider.status);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor:
                        statusColor.withValues(
                      alpha: 0.14,
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
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
                          rider.fullName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${rider.vehicleType.displayName} Ã¢â‚¬Â¢ ${rider.city}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          statusColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      rider.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                rider.phoneNumber,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${rider.vehicleMake} ${rider.vehicleModel} Ã¢â‚¬Â¢ ${rider.registrationNumber}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 7,
                children: <Widget>[
                  _tag(
                    Icons.star_outline,
                    rider.rating.toStringAsFixed(1),
                  ),
                  _tag(
                    Icons.task_alt,
                    '${rider.completedDeliveries} completed',
                  ),
                  _tag(
                    Icons.percent,
                    '${rider.commissionPercentage.toStringAsFixed(0)}% commission',
                  ),
                  if (rider.isOnDelivery)
                    _tag(
                      Icons.route,
                      'On delivery',
                      warning: true,
                    ),
                ],
              ),
              if (onApprove != null ||
                  onReject != null ||
                  onSuspend != null ||
                  onRestore != null) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isUpdating
                                  ? null
                                  : onReject,
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                Colors.redAccent,
                            side: const BorderSide(
                              color:
                                  Colors.redAccent,
                            ),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    if (onReject != null &&
                        onApprove != null)
                      const SizedBox(width: 10),
                    if (onApprove != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isUpdating
                                  ? null
                                  : onApprove,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor:
                                Colors.black,
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    if (onSuspend != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isUpdating
                                  ? null
                                  : onSuspend,
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                Colors.redAccent,
                            side: const BorderSide(
                              color:
                                  Colors.redAccent,
                            ),
                          ),
                          child: const Text('Suspend'),
                        ),
                      ),
                    if (onRestore != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isUpdating
                                  ? null
                                  : onRestore,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.greenAccent,
                            foregroundColor:
                                Colors.black,
                          ),
                          child: const Text('Restore'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _tag(
    IconData icon,
    String text, {
    bool warning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: warning
            ? Colors.orange.withValues(alpha: 0.12)
            : const Color(0xFF272727),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            color: warning
                ? Colors.orangeAccent
                : yellow,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: warning
                  ? Colors.orangeAccent
                  : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodDeliveryRiderManagementCardStatus {
  const _FoodDeliveryRiderManagementCardStatus._();

  static Color color(
    FoodDeliveryRiderStatus status,
  ) {
    switch (status) {
      case FoodDeliveryRiderStatus.draft:
        return Colors.grey;
      case FoodDeliveryRiderStatus.pending:
      case FoodDeliveryRiderStatus.underReview:
        return Colors.orangeAccent;
      case FoodDeliveryRiderStatus.approved:
        return Colors.greenAccent;
      case FoodDeliveryRiderStatus.rejected:
        return Colors.redAccent;
      case FoodDeliveryRiderStatus.suspended:
        return Colors.deepOrangeAccent;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value.trim().isEmpty ? 'Ã¢â‚¬â€' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminFilterItem {
  const _AdminFilterItem({
    required this.filter,
    required this.label,
  });

  final _FoodRiderAdminFilter filter;
  final String label;
}
