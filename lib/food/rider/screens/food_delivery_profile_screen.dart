// lib/food/rider/screens/food_delivery_profile_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Profile Screen
//
// Connected with:
// - FirebaseAuth
// - FoodDeliveryRiderModel
// - FoodDeliveryRiderService
//
// Real features:
// - Live rider profile
// - Personal information
// - Vehicle information
// - Document status
// - Delivery statistics
// - Rating and wallet summary
// - Editable contact/address/vehicle details
// - Online/offline safety handling
// - Logout
//
// Firebase Storage upload remains temporarily bypassed.
// Local profile/document paths remain supported.
// =============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/food_delivery_rider_model.dart';
import '../services/food_delivery_rider_service.dart';

class FoodDeliveryProfileScreen extends StatefulWidget {
  const FoodDeliveryProfileScreen({required this.rider, super.key});

  final FoodDeliveryRiderModel rider;

  @override
  State<FoodDeliveryProfileScreen> createState() =>
      _FoodDeliveryProfileScreenState();
}

class _FoodDeliveryProfileScreenState extends State<FoodDeliveryProfileScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodDeliveryRiderService _riderService = FoodDeliveryRiderService();

  bool _isUpdating = false;

  FoodDeliveryRiderModel get initialRider => widget.rider;

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editProfile(FoodDeliveryRiderModel rider) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController nameController = TextEditingController(
      text: rider.fullName,
    );

    final TextEditingController phoneController = TextEditingController(
      text: rider.phoneNumber,
    );

    final TextEditingController emailController = TextEditingController(
      text: rider.email,
    );

    final TextEditingController areaController = TextEditingController(
      text: rider.area,
    );

    final TextEditingController addressController = TextEditingController(
      text: rider.completeAddress,
    );

    final TextEditingController vehicleMakeController = TextEditingController(
      text: rider.vehicleMake,
    );

    final TextEditingController vehicleModelController = TextEditingController(
      text: rider.vehicleModel,
    );

    final TextEditingController vehicleColorController = TextEditingController(
      text: rider.vehicleColor,
    );

    final TextEditingController registrationController = TextEditingController(
      text: rider.registrationNumber,
    );

    FoodDeliveryVehicleType selectedVehicleType = rider.vehicleType;

    final FoodDeliveryRiderModel?
    updatedRider = await showModalBottomSheet<FoodDeliveryRiderModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setSheetState,
              ) {
                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 18,
                      right: 18,
                      top: 18,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                    ),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Edit Rider Profile',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _editField(
                              controller: nameController,
                              label: 'Full name',
                              icon: Icons.person_outline,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            _editField(
                              controller: phoneController,
                              label: 'Phone number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            _editField(
                              controller: emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 12),
                            _editField(
                              controller: areaController,
                              label: 'Area',
                              icon: Icons.place_outlined,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            _editField(
                              controller: addressController,
                              label: 'Complete address',
                              icon: Icons.home_outlined,
                              minLines: 2,
                              maxLines: 4,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<FoodDeliveryVehicleType>(
                              initialValue: selectedVehicleType,
                              dropdownColor: const Color(0xFF252525),
                              decoration: _inputDecoration(
                                label: 'Vehicle type',
                                icon: Icons.delivery_dining,
                              ),
                              items: FoodDeliveryVehicleType.values
                                  .map(
                                    (FoodDeliveryVehicleType type) =>
                                        DropdownMenuItem<
                                          FoodDeliveryVehicleType
                                        >(
                                          value: type,
                                          child: Text(type.displayName),
                                        ),
                                  )
                                  .toList(),
                              onChanged: (FoodDeliveryVehicleType? value) {
                                if (value == null) {
                                  return;
                                }

                                setSheetState(() {
                                  selectedVehicleType = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _editField(
                              controller: vehicleMakeController,
                              label: 'Vehicle company',
                              icon: Icons.factory_outlined,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            _editField(
                              controller: vehicleModelController,
                              label: 'Vehicle model',
                              icon: Icons.model_training,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            _editField(
                              controller: vehicleColorController,
                              label: 'Vehicle color',
                              icon: Icons.palette_outlined,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            _editField(
                              controller: registrationController,
                              label: 'Registration number',
                              icon: Icons.confirmation_number_outlined,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () {
                                  final bool valid =
                                      formKey.currentState?.validate() ?? false;

                                  if (!valid) {
                                    return;
                                  }

                                  Navigator.pop(
                                    sheetContext,
                                    rider.copyWith(
                                      fullName: nameController.text.trim(),
                                      phoneNumber: phoneController.text.trim(),
                                      email: emailController.text.trim(),
                                      area: areaController.text.trim(),
                                      completeAddress: addressController.text
                                          .trim(),
                                      vehicleType: selectedVehicleType,
                                      vehicleMake: vehicleMakeController.text
                                          .trim(),
                                      vehicleModel: vehicleModelController.text
                                          .trim(),
                                      vehicleColor: vehicleColorController.text
                                          .trim(),
                                      registrationNumber: registrationController
                                          .text
                                          .trim(),
                                      updatedAt: DateTime.now(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: yellow,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    areaController.dispose();
    addressController.dispose();
    vehicleMakeController.dispose();
    vehicleModelController.dispose();
    vehicleColorController.dispose();
    registrationController.dispose();

    if (updatedRider == null) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _riderService.updateApplication(updatedRider);

      _showMessage('Rider profile updated successfully.');
    } on FoodDeliveryRiderServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to update profile: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _logout(FoodDeliveryRiderModel rider) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Logout?'),
          content: const Text(
            'You will be marked offline before logging out.',
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (rider.isOnDelivery) {
      _showMessage(
        'Complete or cancel the active delivery before logging out.',
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      if (rider.isOnline) {
        await _riderService.setOnlineStatus(
          riderId: rider.riderId,
          isOnline: false,
        );
      }

      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }

      Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
    } catch (error) {
      _showMessage('Unable to logout: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Rider Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit profile',
            onPressed: _isUpdating ? null : () => _editProfile(initialRider),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: StreamBuilder<FoodDeliveryRiderModel?>(
        stream: _riderService.watchRiderById(initialRider.riderId),
        initialData: initialRider,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<FoodDeliveryRiderModel?> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: yellow),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState();
              }

              final FoodDeliveryRiderModel rider =
                  snapshot.data ?? initialRider;

              return RefreshIndicator(
                color: yellow,
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  children: <Widget>[
                    _buildProfileHeader(rider),
                    const SizedBox(height: 16),
                    _buildStatusCard(rider),
                    const SizedBox(height: 16),
                    _buildStatistics(rider),
                    const SizedBox(height: 16),
                    _buildPersonalCard(rider),
                    const SizedBox(height: 16),
                    _buildVehicleCard(rider),
                    const SizedBox(height: 16),
                    _buildDocumentsCard(rider),
                    const SizedBox(height: 16),
                    _buildFinancialCard(rider),
                    const SizedBox(height: 16),
                    _buildAccountActions(rider),
                  ],
                ),
              );
            },
      ),
    );
  }

  Widget _buildProfileHeader(FoodDeliveryRiderModel rider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.black,
            child: rider.profileLocalImagePath.trim().isEmpty
                ? const Icon(Icons.person, color: yellow, size: 38)
                : const Icon(Icons.check, color: Colors.greenAccent, size: 34),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  rider.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rider.phoneNumber,
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rider.vehicleType.displayName} â€¢ ${rider.city}',
                  style: const TextStyle(color: Colors.black87, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: _isUpdating ? null : () => _editProfile(rider),
            icon: const Icon(Icons.edit, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(FoodDeliveryRiderModel rider) {
    final Color statusColor = _statusColor(rider.status);

    return _sectionCard(
      title: 'Account Status',
      icon: Icons.verified_user_outlined,
      children: <Widget>[
        Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.14),
              child: Icon(_statusIcon(rider.status), color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    rider.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rider.availabilityText,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (rider.rejectionReason.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _warningBox(
            'Rejection reason: ${rider.rejectionReason}',
            Colors.redAccent,
          ),
        ],
        if (rider.suspensionReason.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _warningBox(
            'Suspension reason: ${rider.suspensionReason}',
            Colors.orangeAccent,
          ),
        ],
      ],
    );
  }

  Widget _buildStatistics(FoodDeliveryRiderModel rider) {
    final List<_ProfileStat> stats = <_ProfileStat>[
      _ProfileStat(
        title: 'Rating',
        value: rider.rating.toStringAsFixed(1),
        icon: Icons.star_outline,
      ),
      _ProfileStat(
        title: 'Completed',
        value: '${rider.completedDeliveries}',
        icon: Icons.task_alt,
      ),
      _ProfileStat(
        title: 'Completion',
        value: '${rider.completionRate}%',
        icon: Icons.percent,
      ),
      _ProfileStat(
        title: 'Cancelled',
        value: '${rider.cancelledDeliveries}',
        icon: Icons.cancel_outlined,
      ),
    ];

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.38,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _ProfileStat stat = stats[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(stat.icon, color: yellow, size: 27),
              Text(
                stat.value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stat.title,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalCard(FoodDeliveryRiderModel rider) {
    return _sectionCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: <Widget>[
        _InfoRow(label: 'Full name', value: rider.fullName),
        const Divider(color: Colors.white12),
        _InfoRow(label: 'Phone', value: rider.phoneNumber),
        const Divider(color: Colors.white12),
        _InfoRow(label: 'Email', value: rider.email),
        const Divider(color: Colors.white12),
        _InfoRow(label: 'CNIC', value: rider.cnicNumber),
        const Divider(color: Colors.white12),
        _InfoRow(label: 'Area', value: '${rider.area}, ${rider.city}'),
        const Divider(color: Colors.white12),
        _InfoRow(label: 'Address', value: rider.completeAddress),
      ],
    );
  }

  Widget _buildVehicleCard(FoodDeliveryRiderModel rider) {
    return _sectionCard(
      title: 'Vehicle Information',
      icon: Icons.two_wheeler,
      children: <Widget>[
        _InfoRow(label: 'Vehicle type', value: rider.vehicleType.displayName),
        const Divider(color: Colors.white12),
        _InfoRow(label: 'Company', value: rider.vehicleMake),
        const Divider(color: Colors.white12),
        _InfoRow(label: 'Model', value: rider.vehicleModel),
        const Divider(color: Colors.white12),
        _InfoRow(label: 'Color', value: rider.vehicleColor),
        const Divider(color: Colors.white12),
        _InfoRow(label: 'Registration', value: rider.registrationNumber),
      ],
    );
  }

  Widget _buildDocumentsCard(FoodDeliveryRiderModel rider) {
    return _sectionCard(
      title: 'Documents',
      icon: Icons.folder_copy_outlined,
      children: <Widget>[
        _documentStatus(
          title: 'Profile Image',
          path: rider.profileLocalImagePath,
        ),
        const SizedBox(height: 9),
        _documentStatus(title: 'CNIC Front', path: rider.cnicFrontLocalPath),
        const SizedBox(height: 9),
        _documentStatus(title: 'CNIC Back', path: rider.cnicBackLocalPath),
        const SizedBox(height: 9),
        _documentStatus(
          title: 'Driving License Front',
          path: rider.drivingLicenseFrontLocalPath,
        ),
        const SizedBox(height: 9),
        _documentStatus(
          title: 'Driving License Back',
          path: rider.drivingLicenseBackLocalPath,
        ),
        const SizedBox(height: 9),
        _documentStatus(
          title: 'Vehicle Registration',
          path: rider.vehicleRegistrationLocalPath,
        ),
        const SizedBox(height: 12),
        const Text(
          'Firebase Storage is temporarily bypassed. Local document paths remain stored.',
          style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildFinancialCard(FoodDeliveryRiderModel rider) {
    return _sectionCard(
      title: 'Wallet & Commission',
      icon: Icons.account_balance_wallet_outlined,
      children: <Widget>[
        _InfoRow(
          label: 'Wallet balance',
          value: 'Rs. ${rider.walletBalance.toStringAsFixed(0)}',
          highlight: true,
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Lifetime earnings',
          value: 'Rs. ${rider.totalEarnings.toStringAsFixed(0)}',
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Commission rate',
          value: '${rider.commissionPercentage.toStringAsFixed(0)}%',
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Outstanding commission',
          value: 'Rs. ${rider.outstandingCommission.toStringAsFixed(0)}',
        ),
      ],
    );
  }

  Widget _buildAccountActions(FoodDeliveryRiderModel rider) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isUpdating ? null : () => _editProfile(rider),
            icon: const Icon(Icons.edit_outlined),
            label: const Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _isUpdating ? null : () => _logout(rider),
            icon: _isUpdating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.redAccent,
                    ),
                  )
                : const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _documentStatus({required String title, required String path}) {
    final bool available = path.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            available ? Icons.check_circle_outline : Icons.error_outline,
            color: available ? Colors.greenAccent : Colors.orangeAccent,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  available ? _fileName(path) : 'Not available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBox(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, height: 1.4),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: yellow),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Unable to load rider profile',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check Firestore connection and security rules.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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

  static String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  static String? _emailValidator(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    if (!text.contains('@') || !text.contains('.')) {
      return 'Enter a valid email';
    }

    return null;
  }

  static Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  static InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: yellow),
      filled: true,
      fillColor: const Color(0xFF252525),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: yellow),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Color _statusColor(FoodDeliveryRiderStatus status) {
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

  IconData _statusIcon(FoodDeliveryRiderStatus status) {
    switch (status) {
      case FoodDeliveryRiderStatus.draft:
        return Icons.edit_note;
      case FoodDeliveryRiderStatus.pending:
        return Icons.hourglass_top;
      case FoodDeliveryRiderStatus.underReview:
        return Icons.manage_search;
      case FoodDeliveryRiderStatus.approved:
        return Icons.verified;
      case FoodDeliveryRiderStatus.rejected:
        return Icons.cancel_outlined;
      case FoodDeliveryRiderStatus.suspended:
        return Icons.block;
    }
  }

  String _fileName(String path) {
    final String normalized = path.replaceAll('\\', '/');

    return normalized.split('/').last;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value.trim().isEmpty ? 'â€”' : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: highlight ? yellow : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStat {
  const _ProfileStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}
