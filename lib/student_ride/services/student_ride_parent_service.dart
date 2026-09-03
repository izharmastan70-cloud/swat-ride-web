import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/student_ride_guardian_model.dart';
import '../models/student_ride_student_model.dart';

class StudentRideParentService {
  StudentRideParentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('student_ride_students');

  CollectionReference<Map<String, dynamic>> get _guardians =>
      _firestore.collection('student_ride_guardians');

  String get _requiredParentId {
    final String? userId = _auth.currentUser?.uid;

    if (userId == null || userId.trim().isEmpty) {
      throw Exception('Parent is not logged in.');
    }

    return userId.trim();
  }

  Future<String> saveStudentDraft(
    StudentRideStudentModel student,
  ) async {
    final String parentId = _requiredParentId;

    final DocumentReference<Map<String, dynamic>> reference =
        student.studentId.trim().isEmpty
            ? _students.doc()
            : _students.doc(student.studentId.trim());

    final Map<String, dynamic> data = student.toMap()
      ..['studentId'] = reference.id
      ..['parentUserId'] = parentId
      ..['status'] = StudentRideStudentStatus.draft.name
      ..['updatedAt'] = FieldValue.serverTimestamp();

    final snapshot = await reference.get();

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await reference.set(
      data,
      SetOptions(merge: true),
    );

    return reference.id;
  }

  Future<void> submitStudent({
    required String studentId,
  }) async {
    final String parentId = _requiredParentId;
    final String normalizedStudentId = studentId.trim();

    if (normalizedStudentId.isEmpty) {
      throw Exception('Student ID is required.');
    }

    final reference = _students.doc(normalizedStudentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw Exception('Student profile was not found.');
      }

      final Map<String, dynamic> data = snapshot.data()!;

      if (data['parentUserId'] != parentId) {
        throw Exception(
          'This Student profile does not belong to you.',
        );
      }

      final StudentRideStudentModel student =
          StudentRideStudentModel.fromMap(
        data,
        documentId: snapshot.id,
      );

      _validateStudent(student);

      transaction.set(
        reference,
        <String, dynamic>{
          'status': StudentRideStudentStatus.submitted.name,
          'submittedAt': FieldValue.serverTimestamp(),
          'rejectionReason': '',
          'adminNotes': '',
          'reviewedBy': '',
          'reviewedAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Stream<List<StudentRideStudentModel>> watchMyStudents() {
    final String parentId = _requiredParentId;

    return _students
        .where('parentUserId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
      final List<StudentRideStudentModel> items =
          snapshot.docs
              .map(
                (document) =>
                    StudentRideStudentModel.fromMap(
                  document.data(),
                  documentId: document.id,
                ),
              )
              .toList();

      items.sort(
        (first, second) =>
            first.fullName.compareTo(second.fullName),
      );

      return items;
    });
  }

  Future<String> saveGuardian(
    StudentRideGuardianModel guardian,
  ) async {
    final String parentId = _requiredParentId;

    _validateGuardian(guardian);

    final DocumentReference<Map<String, dynamic>> reference =
        guardian.guardianId.trim().isEmpty
            ? _guardians.doc()
            : _guardians.doc(guardian.guardianId.trim());

    if (guardian.guardianId.trim().isNotEmpty) {
      final oldSnapshot = await reference.get();
      final oldData = oldSnapshot.data();

      if (oldSnapshot.exists &&
          oldData?['parentUserId'] != parentId) {
        throw Exception(
          'This Guardian record does not belong to you.',
        );
      }
    }

    final Map<String, dynamic> data = guardian.toMap()
      ..['guardianId'] = reference.id
      ..['parentUserId'] = parentId
      ..['verificationStatus'] =
          StudentRideGuardianVerificationStatus.pending.name
      ..['verifiedBy'] = ''
      ..['verifiedAt'] = null
      ..['rejectionReason'] = ''
      ..['updatedAt'] = FieldValue.serverTimestamp();

    final snapshot = await reference.get();

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await reference.set(
      data,
      SetOptions(merge: true),
    );

    return reference.id;
  }

  Stream<List<StudentRideGuardianModel>> watchMyGuardians() {
    final String parentId = _requiredParentId;

    return _guardians
        .where('parentUserId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
      final List<StudentRideGuardianModel> items =
          snapshot.docs
              .map(
                (document) =>
                    StudentRideGuardianModel.fromMap(
                  document.data(),
                  documentId: document.id,
                ),
              )
              .toList();

      items.sort((first, second) {
        if (first.isPrimaryGuardian &&
            !second.isPrimaryGuardian) {
          return -1;
        }

        if (!first.isPrimaryGuardian &&
            second.isPrimaryGuardian) {
          return 1;
        }

        return first.fullName.compareTo(second.fullName);
      });

      return items;
    });
  }

  Future<void> linkGuardianToStudent({
    required String guardianId,
    required String studentId,
  }) async {
    final String parentId = _requiredParentId;
    final String normalizedGuardianId = guardianId.trim();
    final String normalizedStudentId = studentId.trim();

    if (normalizedGuardianId.isEmpty ||
        normalizedStudentId.isEmpty) {
      throw Exception('Guardian and Student are required.');
    }

    final guardianReference =
        _guardians.doc(normalizedGuardianId);
    final studentReference =
        _students.doc(normalizedStudentId);

    await _firestore.runTransaction((transaction) async {
      final guardianSnapshot =
          await transaction.get(guardianReference);
      final studentSnapshot =
          await transaction.get(studentReference);

      if (!guardianSnapshot.exists ||
          !studentSnapshot.exists) {
        throw Exception(
          'Guardian or Student record was not found.',
        );
      }

      final guardianData = guardianSnapshot.data()!;
      final studentData = studentSnapshot.data()!;

      if (guardianData['parentUserId'] != parentId ||
          studentData['parentUserId'] != parentId) {
        throw Exception(
          'Guardian and Student must belong to your account.',
        );
      }

      transaction.set(
        guardianReference,
        <String, dynamic>{
          'authorizedStudentIds':
              FieldValue.arrayUnion(<String>[
            normalizedStudentId,
          ]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        studentReference,
        <String, dynamic>{
          'authorizedGuardianIds':
              FieldValue.arrayUnion(<String>[
            normalizedGuardianId,
          ]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> unlinkGuardianFromStudent({
    required String guardianId,
    required String studentId,
  }) async {
    final String parentId = _requiredParentId;
    final guardianReference =
        _guardians.doc(guardianId.trim());
    final studentReference =
        _students.doc(studentId.trim());

    await _firestore.runTransaction((transaction) async {
      final guardianSnapshot =
          await transaction.get(guardianReference);
      final studentSnapshot =
          await transaction.get(studentReference);

      if (!guardianSnapshot.exists ||
          !studentSnapshot.exists) {
        throw Exception('Guardian or Student was not found.');
      }

      if (guardianSnapshot.data()?['parentUserId'] != parentId ||
          studentSnapshot.data()?['parentUserId'] != parentId) {
        throw Exception('Access denied.');
      }

      if (studentSnapshot.data()?['primaryGuardianId'] ==
          guardianId.trim()) {
        throw Exception(
          'Primary Guardian cannot be removed.',
        );
      }

      transaction.set(
        guardianReference,
        <String, dynamic>{
          'authorizedStudentIds':
              FieldValue.arrayRemove(<String>[
            studentId.trim(),
          ]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        studentReference,
        <String, dynamic>{
          'authorizedGuardianIds':
              FieldValue.arrayRemove(<String>[
            guardianId.trim(),
          ]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  void _validateStudent(
    StudentRideStudentModel student,
  ) {
    if (student.fullName.trim().length < 3) {
      throw Exception('Enter Student full name.');
    }

    if (student.dateOfBirth.trim().isEmpty) {
      throw Exception('Student date of birth is required.');
    }

    if (student.schoolName.trim().length < 3) {
      throw Exception('Enter School name.');
    }

    if (student.className.trim().isEmpty) {
      throw Exception('Student class is required.');
    }

    if (student.homeAddress.trim().length < 5) {
      throw Exception('Enter Student home address.');
    }

    if (student.primaryGuardianId.trim().isEmpty) {
      throw Exception('Primary Guardian is required.');
    }

    if (!student.needsTransport) {
      throw Exception(
        'Select morning or afternoon transport.',
      );
    }
  }

  void _validateGuardian(
    StudentRideGuardianModel guardian,
  ) {
    if (guardian.fullName.trim().length < 3) {
      throw Exception('Enter Guardian full name.');
    }

    if (guardian.phoneNumber.trim().length < 10) {
      throw Exception('Enter a valid Guardian phone number.');
    }

    if (guardian.cnicNumber.trim().length < 13) {
      throw Exception('Enter a valid Guardian CNIC.');
    }
  }
}
