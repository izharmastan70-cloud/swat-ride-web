// SWAT RIDE - UNIVERSAL TRUSTED CONTACT SERVICE
//
// Shared trusted-contact service for:
// - Ride users and drivers
// - Student Ride parents, guardians and drivers
// - Food users, riders and restaurant partners
// - Cargo / Parcel users and drivers
// - Hotel guests, owners and staff
// - Tour customers, guides and tourism drivers
//
// One user keeps one shared trusted-contact list.
// The same contacts can be used across all SWAT RIDE services.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/trusted_contact_model.dart';

class TrustedContactService {
  TrustedContactService({
    FirebaseFirestore? firestore,
    this.defaultMaximumContacts = 3,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Safe local default.
  ///
  /// Later this limit will come from UniversalSafetyConfig.
  final int defaultMaximumContacts;

  static const String collectionName = 'trusted_contacts';

  CollectionReference<Map<String, dynamic>>
      get _contactsRef {
    return _firestore.collection(collectionName);
  }

  // ---------------------------------------------------------------------------
  // CREATE CONTACT
  // ---------------------------------------------------------------------------

  Future<String> addContact({
    required String userId,
    required String name,
    required String phoneNumber,
    required String relationship,
    bool isPrimary = false,
    bool isEnabled = true,
    bool receiveSosAlerts = true,
    bool receiveLiveLocation = true,
    bool receiveServiceDetails = true,
    bool receiveSafetyUpdates = true,
    int? maximumContacts,
  }) async {
    final String cleanUserId = userId.trim();
    final String cleanName = name.trim();
    final String cleanPhoneNumber = phoneNumber.trim();
    final String cleanRelationship = relationship.trim();

    _validateRequiredData(
      userId: cleanUserId,
      name: cleanName,
      phoneNumber: cleanPhoneNumber,
      relationship: cleanRelationship,
    );

    final int resolvedMaximumContacts =
        maximumContacts ?? defaultMaximumContacts;

    if (resolvedMaximumContacts < 1) {
      throw const TrustedContactServiceException(
        message:
            'Maximum trusted-contact limit must be at least 1.',
        code: 'invalid-contact-limit',
      );
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          existingContacts = await _contactsRef
              .where('userId', isEqualTo: cleanUserId)
              .get();

      if (existingContacts.docs.length >=
          resolvedMaximumContacts) {
        throw TrustedContactServiceException(
          message:
              'You can add a maximum of $resolvedMaximumContacts trusted contacts.',
          code: 'trusted-contact-limit-reached',
        );
      }

      final bool duplicateExists =
          existingContacts.docs.any(
        (
          QueryDocumentSnapshot<Map<String, dynamic>>
              document,
        ) {
          final String existingPhone =
              document.data()['phoneNumber']
                      ?.toString()
                      .trim() ??
                  '';

          return _normalizePhone(existingPhone) ==
              _normalizePhone(cleanPhoneNumber);
        },
      );

      if (duplicateExists) {
        throw const TrustedContactServiceException(
          message:
              'This phone number is already saved as a trusted contact.',
          code: 'duplicate-trusted-contact',
        );
      }

      final DocumentReference<Map<String, dynamic>>
          contactDocument = _contactsRef.doc();

      final bool shouldBecomePrimary =
          isPrimary || existingContacts.docs.isEmpty;

      final WriteBatch batch = _firestore.batch();

      if (shouldBecomePrimary) {
        for (final QueryDocumentSnapshot<
                Map<String, dynamic>> document
            in existingContacts.docs) {
          batch.update(
            document.reference,
            <String, dynamic>{
              'isPrimary': false,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }

      final TrustedContactModel contact =
          TrustedContactModel(
        contactId: contactDocument.id,
        userId: cleanUserId,
        name: cleanName,
        phoneNumber: cleanPhoneNumber,
        relationship: cleanRelationship,
        isPrimary: shouldBecomePrimary,
        isEnabled: isEnabled,
        receiveSosAlerts: receiveSosAlerts,
        receiveLiveLocation: receiveLiveLocation,
        receiveServiceDetails: receiveServiceDetails,
        receiveSafetyUpdates: receiveSafetyUpdates,
      );

      batch.set(
        contactDocument,
        contact.toMap(),
      );

      await batch.commit();

      return contactDocument.id;
    } on TrustedContactServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to add trusted contact: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to add trusted contact: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE CONTACT
  // ---------------------------------------------------------------------------

  Future<void> updateContact({
    required TrustedContactModel contact,
  }) async {
    final String cleanContactId =
        contact.contactId.trim();

    final String cleanUserId =
        contact.userId.trim();

    final String cleanName =
        contact.name.trim();

    final String cleanPhoneNumber =
        contact.phoneNumber.trim();

    final String cleanRelationship =
        contact.relationship.trim();

    if (cleanContactId.isEmpty) {
      throw const TrustedContactServiceException(
        message: 'Trusted contact ID is required.',
        code: 'missing-contact-id',
      );
    }

    _validateRequiredData(
      userId: cleanUserId,
      name: cleanName,
      phoneNumber: cleanPhoneNumber,
      relationship: cleanRelationship,
    );

    try {
      final QuerySnapshot<Map<String, dynamic>>
          userContacts = await _contactsRef
              .where('userId', isEqualTo: cleanUserId)
              .get();

      final bool duplicateExists =
          userContacts.docs.any(
        (
          QueryDocumentSnapshot<Map<String, dynamic>>
              document,
        ) {
          if (document.id == cleanContactId) {
            return false;
          }

          final String existingPhone =
              document.data()['phoneNumber']
                      ?.toString()
                      .trim() ??
                  '';

          return _normalizePhone(existingPhone) ==
              _normalizePhone(cleanPhoneNumber);
        },
      );

      if (duplicateExists) {
        throw const TrustedContactServiceException(
          message:
              'Another trusted contact already uses this phone number.',
          code: 'duplicate-trusted-contact',
        );
      }

      final WriteBatch batch = _firestore.batch();

      if (contact.isPrimary) {
        for (final QueryDocumentSnapshot<
                Map<String, dynamic>> document
            in userContacts.docs) {
          if (document.id == cleanContactId) {
            continue;
          }

          batch.update(
            document.reference,
            <String, dynamic>{
              'isPrimary': false,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }

      batch.update(
        _contactsRef.doc(cleanContactId),
        <String, dynamic>{
          'userId': cleanUserId,
          'name': cleanName,
          'phoneNumber': cleanPhoneNumber,
          'relationship': cleanRelationship,
          'isPrimary': contact.isPrimary,
          'isEnabled': contact.isEnabled,
          'receiveSosAlerts':
              contact.receiveSosAlerts,
          'receiveLiveLocation':
              contact.receiveLiveLocation,
          'receiveServiceDetails':
              contact.receiveServiceDetails,
          'receiveSafetyUpdates':
              contact.receiveSafetyUpdates,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } on TrustedContactServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to update trusted contact: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to update trusted contact: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE CONTACT
  // ---------------------------------------------------------------------------

  Future<void> deleteContact({
    required String contactId,
    required String userId,
  }) async {
    final String cleanContactId = contactId.trim();
    final String cleanUserId = userId.trim();

    if (cleanContactId.isEmpty ||
        cleanUserId.isEmpty) {
      throw const TrustedContactServiceException(
        message:
            'Trusted contact ID and user ID are required.',
        code: 'missing-delete-data',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          contactDocument =
          _contactsRef.doc(cleanContactId);

      final DocumentSnapshot<Map<String, dynamic>>
          contactSnapshot =
          await contactDocument.get();

      if (!contactSnapshot.exists ||
          contactSnapshot.data() == null) {
        return;
      }

      final Map<String, dynamic> contactData =
          contactSnapshot.data()!;

      if (contactData['userId']?.toString() !=
          cleanUserId) {
        throw const TrustedContactServiceException(
          message:
              'You are not allowed to delete this trusted contact.',
          code: 'contact-owner-mismatch',
        );
      }

      final bool wasPrimary =
          contactData['isPrimary'] == true;

      final WriteBatch batch = _firestore.batch();

      batch.delete(contactDocument);

      if (wasPrimary) {
        final QuerySnapshot<Map<String, dynamic>>
            remainingContacts = await _contactsRef
                .where(
                  'userId',
                  isEqualTo: cleanUserId,
                )
                .get();

        final List<
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>
            candidates = remainingContacts.docs
                .where(
                  (
                    QueryDocumentSnapshot<
                            Map<String, dynamic>>
                        document,
                  ) =>
                      document.id != cleanContactId,
                )
                .toList();

        if (candidates.isNotEmpty) {
          batch.update(
            candidates.first.reference,
            <String, dynamic>{
              'isPrimary': true,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }

      await batch.commit();
    } on TrustedContactServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to delete trusted contact: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to delete trusted contact: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SET PRIMARY CONTACT
  // ---------------------------------------------------------------------------

  Future<void> setPrimaryContact({
    required String userId,
    required String contactId,
  }) async {
    final String cleanUserId = userId.trim();
    final String cleanContactId = contactId.trim();

    if (cleanUserId.isEmpty ||
        cleanContactId.isEmpty) {
      throw const TrustedContactServiceException(
        message:
            'User ID and trusted contact ID are required.',
        code: 'missing-primary-contact-data',
      );
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          contactsSnapshot = await _contactsRef
              .where('userId', isEqualTo: cleanUserId)
              .get();

      final bool targetExists =
          contactsSnapshot.docs.any(
        (
          QueryDocumentSnapshot<Map<String, dynamic>>
              document,
        ) =>
            document.id == cleanContactId,
      );

      if (!targetExists) {
        throw const TrustedContactServiceException(
          message:
              'The selected trusted contact could not be found.',
          code: 'trusted-contact-not-found',
        );
      }

      final WriteBatch batch = _firestore.batch();

      for (final QueryDocumentSnapshot<
              Map<String, dynamic>> document
          in contactsSnapshot.docs) {
        batch.update(
          document.reference,
          <String, dynamic>{
            'isPrimary':
                document.id == cleanContactId,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    } on TrustedContactServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to set primary trusted contact: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to set primary trusted contact: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ENABLE / DISABLE CONTACT
  // ---------------------------------------------------------------------------

  Future<void> updateContactEnabledStatus({
    required String contactId,
    required String userId,
    required bool isEnabled,
  }) async {
    final String cleanContactId = contactId.trim();
    final String cleanUserId = userId.trim();

    if (cleanContactId.isEmpty ||
        cleanUserId.isEmpty) {
      throw const TrustedContactServiceException(
        message:
            'Trusted contact ID and user ID are required.',
        code: 'missing-contact-status-data',
      );
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          contactDocument =
          _contactsRef.doc(cleanContactId);

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await contactDocument.get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        throw const TrustedContactServiceException(
          message:
              'Trusted contact could not be found.',
          code: 'trusted-contact-not-found',
        );
      }

      if (snapshot.data()!['userId']?.toString() !=
          cleanUserId) {
        throw const TrustedContactServiceException(
          message:
              'You are not allowed to update this trusted contact.',
          code: 'contact-owner-mismatch',
        );
      }

      await contactDocument.update(
        <String, dynamic>{
          'isEnabled': isEnabled,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } on TrustedContactServiceException {
      rethrow;
    } on FirebaseException catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to update trusted contact status: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to update trusted contact status: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET SINGLE CONTACT
  // ---------------------------------------------------------------------------

  Future<TrustedContactModel?> getContact(
    String contactId,
  ) async {
    final String cleanContactId = contactId.trim();

    if (cleanContactId.isEmpty) {
      throw const TrustedContactServiceException(
        message: 'Trusted contact ID is required.',
        code: 'missing-contact-id',
      );
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await _contactsRef.doc(cleanContactId).get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        return null;
      }

      return TrustedContactModel.fromDocument(snapshot);
    } on FirebaseException catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to load trusted contact: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to load trusted contact: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // WATCH USER CONTACTS
  // ---------------------------------------------------------------------------

  Stream<List<TrustedContactModel>>
      watchUserContacts({
    required String userId,
  }) {
    final String cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      return Stream<List<TrustedContactModel>>.error(
        const TrustedContactServiceException(
          message: 'User ID is required.',
          code: 'missing-user-id',
        ),
      );
    }

    return _contactsRef
        .where('userId', isEqualTo: cleanUserId)
        .snapshots()
        .map(_contactsFromQuery);
  }

  // ---------------------------------------------------------------------------
  // GET ELIGIBLE SOS CONTACTS
  // ---------------------------------------------------------------------------

  Future<List<TrustedContactModel>>
      getEligibleSosContacts({
    required String userId,
  }) async {
    final String cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      throw const TrustedContactServiceException(
        message: 'User ID is required.',
        code: 'missing-user-id',
      );
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _contactsRef
              .where('userId', isEqualTo: cleanUserId)
              .get();

      return _contactsFromQuery(snapshot)
          .where(
            (TrustedContactModel contact) =>
                contact.canReceiveEmergencyAlert,
          )
          .toList();
    } on FirebaseException catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to load SOS contacts: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to load SOS contacts: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET PRIMARY CONTACT
  // ---------------------------------------------------------------------------

  Future<TrustedContactModel?> getPrimaryContact({
    required String userId,
  }) async {
    final List<TrustedContactModel> contacts =
        await getEligibleSosContacts(userId: userId);

    for (final TrustedContactModel contact
        in contacts) {
      if (contact.isPrimary) {
        return contact;
      }
    }

    if (contacts.isEmpty) {
      return null;
    }

    return contacts.first;
  }

  // ---------------------------------------------------------------------------
  // CONTACT COUNT
  // ---------------------------------------------------------------------------

  Future<int> getUserContactCount({
    required String userId,
  }) async {
    final String cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      throw const TrustedContactServiceException(
        message: 'User ID is required.',
        code: 'missing-user-id',
      );
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _contactsRef
              .where('userId', isEqualTo: cleanUserId)
              .get();

      return snapshot.docs.length;
    } on FirebaseException catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to count trusted contacts: ${error.message ?? error.code}',
        code: error.code,
      );
    } catch (error) {
      throw TrustedContactServiceException(
        message:
            'Unable to count trusted contacts: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // INTERNAL HELPERS
  // ---------------------------------------------------------------------------

  void _validateRequiredData({
    required String userId,
    required String name,
    required String phoneNumber,
    required String relationship,
  }) {
    if (userId.isEmpty) {
      throw const TrustedContactServiceException(
        message: 'User ID is required.',
        code: 'missing-user-id',
      );
    }

    if (name.isEmpty) {
      throw const TrustedContactServiceException(
        message: 'Trusted contact name is required.',
        code: 'missing-contact-name',
      );
    }

    if (phoneNumber.isEmpty) {
      throw const TrustedContactServiceException(
        message:
            'Trusted contact phone number is required.',
        code: 'missing-phone-number',
      );
    }

    if (relationship.isEmpty) {
      throw const TrustedContactServiceException(
        message:
            'Trusted contact relationship is required.',
        code: 'missing-relationship',
      );
    }

    final String normalizedPhone =
        _normalizePhone(phoneNumber);

    if (normalizedPhone.length < 7) {
      throw const TrustedContactServiceException(
        message:
            'Enter a valid trusted contact phone number.',
        code: 'invalid-phone-number',
      );
    }
  }

  String _normalizePhone(String value) {
    return value.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );
  }

  List<TrustedContactModel> _contactsFromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<TrustedContactModel> contacts =
        snapshot.docs
            .map(TrustedContactModel.fromDocument)
            .toList();

    contacts.sort(
      (
        TrustedContactModel first,
        TrustedContactModel second,
      ) {
        if (first.isPrimary && !second.isPrimary) {
          return -1;
        }

        if (!first.isPrimary && second.isPrimary) {
          return 1;
        }

        return first.name
            .toLowerCase()
            .compareTo(second.name.toLowerCase());
      },
    );

    return contacts;
  }
}

class TrustedContactServiceException
    implements Exception {
  const TrustedContactServiceException({
    required this.message,
    this.code = 'trusted-contact-error',
  });

  final String message;
  final String code;

  @override
  String toString() {
    return 'TrustedContactServiceException'
        '(code: $code, message: $message)';
  }
}