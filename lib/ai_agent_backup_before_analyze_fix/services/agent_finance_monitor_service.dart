import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_finance_constants.dart';
import '../models/agent_finance_record.dart';
import '../models/agent_finance_summary.dart';

// =========================================================
// AI AGENT — FINANCE MONITOR SERVICE
// =========================================================
//
// Reads/writes only the standalone `agent_finance_records` collection.
// Real Wallet/Payment/Commission collections are NOT connected yet.

class AgentFinanceMonitorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionPath = 'agent_finance_records';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Future<AgentFinanceRecord> addMonitoringRecord({
    required String type,
    required String module,
    required String referenceId,
    required int amountRs,
    required int commissionRs,
    required String note,
  }) async {
    final DocumentReference<Map<String, dynamic>> doc = _collection.doc();

    final int net = amountRs - commissionRs;

    final AgentFinanceRecord record = AgentFinanceRecord(
      recordId: doc.id,
      type: type,
      module: module,
      referenceId: referenceId,
      amountRs: amountRs,
      commissionRs: commissionRs,
      netAmountRs: net < 0 ? 0 : net,
      status: AgentFinanceStatus.pending,
      note: note,
      createdAt: DateTime.now(),
      updatedAt: null,
    );

    record.validate();
    await doc.set(record.toMap());
    return record;
  }

  Future<List<AgentFinanceRecord>> getRecent({
    int limit = 200,
  }) async {
    final int safeLimit = limit.clamp(1, 500).toInt();

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection
            .orderBy('createdAt', descending: true)
            .limit(safeLimit)
            .get();

    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              AgentFinanceRecord.fromSnapshot(doc),
        )
        .toList(growable: false);
  }

  Stream<List<AgentFinanceRecord>> watchRecent({
    int limit = 200,
  }) {
    final int safeLimit = limit.clamp(1, 500).toInt();

    return _collection
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  AgentFinanceRecord.fromSnapshot(doc),
            )
            .toList(growable: false);
      },
    );
  }

  Future<AgentFinanceSummary> buildSummary() async {
    final List<AgentFinanceRecord> records = await getRecent(limit: 500);

    int gross = 0;
    int commission = 0;
    int net = 0;
    int pending = 0;
    int preparedSettlements = 0;
    int refundsPrepared = 0;
    int withdrawalsPrepared = 0;

    for (final AgentFinanceRecord item in records) {
      gross += item.amountRs;
      commission += item.commissionRs;
      net += item.netAmountRs;

      if (item.status == AgentFinanceStatus.pending) {
        pending += item.netAmountRs;
      }

      if (item.type == AgentFinanceRecordType.settlement &&
          item.status == AgentFinanceStatus.prepared) {
        preparedSettlements++;
      }

      if (item.type == AgentFinanceRecordType.refund &&
          item.status == AgentFinanceStatus.prepared) {
        refundsPrepared++;
      }

      if (item.type == AgentFinanceRecordType.withdrawal &&
          item.status == AgentFinanceStatus.prepared) {
        withdrawalsPrepared++;
      }
    }

    return AgentFinanceSummary(
      grossRs: gross,
      commissionRs: commission,
      netRs: net,
      pendingRs: pending,
      preparedSettlements: preparedSettlements,
      refundsPrepared: refundsPrepared,
      withdrawalsPrepared: withdrawalsPrepared,
      businessConnectorsAttached: false,
      generatedAt: DateTime.now(),
    );
  }
}
