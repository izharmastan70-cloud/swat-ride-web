import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_service_control_model.dart';

class FoodServiceControlService {
  FoodServiceControlService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>>
      get _settingsReference => _firestore
          .collection(
            FoodServiceControlModel.settingsCollection,
          )
          .doc(
            FoodServiceControlModel.settingsDocument,
          );

  Stream<FoodServiceControlModel> watchControl() {
    return _settingsReference.snapshots().map(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        final Map<String, dynamic>? data =
            snapshot.data();

        if (!snapshot.exists || data == null) {
          return FoodServiceControlModel.defaults();
        }

        return FoodServiceControlModel.fromMap(data);
      },
    );
  }

  Future<FoodServiceControlModel> getControl() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await _settingsReference.get();

      final Map<String, dynamic>? data =
          snapshot.data();

      if (!snapshot.exists || data == null) {
        return FoodServiceControlModel.defaults();
      }

      return FoodServiceControlModel.fromMap(data);
    } on FirebaseException catch (error) {
      throw FoodServiceControlException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw FoodServiceControlException(
        message:
            'Unable to load Food service control: $error',
      );
    }
  }

  Future<void> saveControl({
    required FoodServiceControlModel control,
    required String updatedBy,
    required String updatedByRole,
  }) async {
    final String adminId = updatedBy.trim();
    final String adminRole =
        updatedByRole.trim().toLowerCase();

    if (adminId.isEmpty) {
      throw const FoodServiceControlException(
        message: 'Admin ID is required.',
      );
    }

    if (adminRole.isEmpty) {
      throw const FoodServiceControlException(
        message: 'Admin role is required.',
      );
    }

    if ((!control.foodServiceEnabled ||
            control.maintenanceMode ||
            !control.acceptNewOrders) &&
        control.maintenanceReason.trim().isEmpty) {
      throw const FoodServiceControlException(
        message:
            'A customer-facing reason is required when Food service or new orders are unavailable.',
      );
    }

    try {
      await _firestore.runTransaction(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>>
              currentSnapshot =
              await transaction.get(_settingsReference);

          final FoodServiceControlModel currentControl =
              currentSnapshot.exists &&
                      currentSnapshot.data() != null
                  ? FoodServiceControlModel.fromMap(
                      currentSnapshot.data()!,
                    )
                  : FoodServiceControlModel.defaults();

          String overrideMode =
              control.superAdminOverrideMode;

          if (adminRole != 'super_admin') {
            // A normal Food Admin cannot create, change or
            // remove an existing Super Admin override.
            overrideMode =
                currentControl.superAdminOverrideMode;
          }

          final FoodServiceControlModel safeControl =
              control.copyWith(
            superAdminOverrideMode: overrideMode,
            updatedBy: adminId,
            updatedByRole: adminRole,
            updatedAt: DateTime.now(),
          );

          transaction.set(
            _settingsReference,
            <String, dynamic>{
              ...safeControl.toMap(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        },
      );
    } on FirebaseException catch (error) {
      throw FoodServiceControlException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } on FoodServiceControlException {
      rethrow;
    } catch (error) {
      throw FoodServiceControlException(
        message:
            'Unable to update Food service control: $error',
      );
    }
  }

  Future<void> assertCanCreateNewOrder() async {
    final FoodServiceControlModel control =
        await getControl();

    if (!control.canAcceptNewOrders) {
      throw FoodServiceUnavailableException(
        message: control.unavailableMessage,
      );
    }
  }

  Future<void>
      assertRestaurantApplicationsEnabled() async {
    final FoodServiceControlModel control =
        await getControl();

    if (!control.canAcceptRestaurantApplications) {
      throw FoodServiceUnavailableException(
        message: control.unavailableMessage.isNotEmpty
            ? control.unavailableMessage
            : 'Restaurant applications are temporarily unavailable.',
      );
    }
  }

  Future<void> assertRiderApplicationsEnabled() async {
    final FoodServiceControlModel control =
        await getControl();

    if (!control.canAcceptRiderApplications) {
      throw FoodServiceUnavailableException(
        message: control.unavailableMessage.isNotEmpty
            ? control.unavailableMessage
            : 'Food Rider applications are temporarily unavailable.',
      );
    }
  }

  String _firebaseMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to update Food service controls.';
      case 'unavailable':
        return 'Food service controls are temporarily unavailable. Please try again.';
      case 'network-request-failed':
        return 'Please check your internet connection and try again.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Unable to access Food service controls.';
    }
  }
}

class FoodServiceControlException implements Exception {
  const FoodServiceControlException({
    required this.message,
    this.code = '',
  });

  final String message;
  final String code;

  @override
  String toString() => message;
}

class FoodServiceUnavailableException
    extends FoodServiceControlException {
  const FoodServiceUnavailableException({
    required super.message,
  }) : super(code: 'food-service-unavailable');
}
