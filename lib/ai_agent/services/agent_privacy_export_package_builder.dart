import 'dart:convert';
import 'dart:typed_data';

import '../constants/agent_privacy_control_export_constants.dart';
import '../constants/agent_privacy_export_delivery_constants.dart';
import '../models/agent_privacy_export_decision.dart';
import '../models/agent_privacy_export_download_payload.dart';
import '../models/agent_privacy_export_record.dart';
import 'agent_privacy_data_classification_policy.dart';

class AgentPrivacyExportPackageBuilder {
  const AgentPrivacyExportPackageBuilder({
    this.classificationPolicy = const AgentPrivacyDataClassificationPolicy(),
  });

  final AgentPrivacyDataClassificationPolicy classificationPolicy;

  AgentPrivacyExportDownloadPayload build({
    required AgentPrivacyExportDecision decision,
    required List<AgentPrivacyExportRecord> records,
  }) {
    decision.validate();

    if (!decision.eligibleForSafeExportPackage ||
        records.isEmpty ||
        records.length >
            AgentPrivacyExportDeliveryLimits.maximumRecordsPerPackage) {
      throw const FormatException(
        'Export package requires an eligible decision and safe records.',
      );
    }

    final allowedKinds = decision.allowedDataKinds.toSet();

    for (final record in records) {
      record.validate();

      if (!allowedKinds.contains(record.dataKind)) {
        throw const FormatException(
          'Export record data kind is outside the eligible export decision.',
        );
      }

      final classification = classificationPolicy.classify(record.dataKind);

      if (classification.restrictedCritical ||
          classification.protectedEvidence) {
        throw const FormatException(
          'Restricted/protected data cannot enter generic export package.',
        );
      }

      if (classification.redactionRequired &&
          !record.redactedProjectionVerified) {
        throw const FormatException(
          'Private export record requires verified redaction.',
        );
      }
    }

    switch (decision.format) {
      case AgentPrivacyExportFormat.json:
        return _buildJson(decision, records);

      case AgentPrivacyExportFormat.csv:
        return _buildCsv(decision, records);

      case AgentPrivacyExportFormat.zipPackage:
        return _buildZip(decision, records);

      default:
        throw const FormatException(
          'Unsupported privacy export package format.',
        );
    }
  }

  AgentPrivacyExportDownloadPayload _buildJson(
    AgentPrivacyExportDecision decision,
    List<AgentPrivacyExportRecord> records,
  ) {
    final content = jsonEncode(<String, Object?>{
      'exportId': decision.exportId,
      'redactedProjectionOnly': true,
      'restrictedCriticalExcluded': true,
      'protectedEvidenceExcluded': true,
      'records': records.map((record) => record.toSafeMap()).toList(),
    });

    return AgentPrivacyExportDownloadPayload(
      exportId: decision.exportId,
      fileName: _fileName(decision.exportId, 'json'),
      mimeType: AgentPrivacyExportMimeType.json,
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
  }

  AgentPrivacyExportDownloadPayload _buildCsv(
    AgentPrivacyExportDecision decision,
    List<AgentPrivacyExportRecord> records,
  ) {
    final buffer = StringBuffer('dataKind,field,value\r\n');

    for (final record in records) {
      for (final entry in record.fields.entries) {
        buffer
          ..write(_csv(record.dataKind))
          ..write(',')
          ..write(_csv(entry.key))
          ..write(',')
          ..write(_csv(jsonEncode(entry.value)))
          ..write('\r\n');
      }
    }

    return AgentPrivacyExportDownloadPayload(
      exportId: decision.exportId,
      fileName: _fileName(decision.exportId, 'csv'),
      mimeType: AgentPrivacyExportMimeType.csv,
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
    );
  }

  AgentPrivacyExportDownloadPayload _buildZip(
    AgentPrivacyExportDecision decision,
    List<AgentPrivacyExportRecord> records,
  ) {
    final dataJson = jsonEncode(<String, Object?>{
      'exportId': decision.exportId,
      'records': records.map((record) => record.toSafeMap()).toList(),
    });

    final manifestJson = jsonEncode(<String, Object?>{
      'exportId': decision.exportId,
      'redactedProjectionOnly': true,
      'restrictedCriticalExcluded': true,
      'protectedEvidenceExcluded': true,
      'recordCount': records.length,
      'dataKinds': decision.allowedDataKinds,
    });

    final zipBytes = _buildStoredZip(<String, Uint8List>{
      'data.json': Uint8List.fromList(utf8.encode(dataJson)),
      'manifest.json': Uint8List.fromList(utf8.encode(manifestJson)),
    });

    return AgentPrivacyExportDownloadPayload(
      exportId: decision.exportId,
      fileName: _fileName(decision.exportId, 'zip'),
      mimeType: AgentPrivacyExportMimeType.zip,
      bytes: zipBytes,
    );
  }

  Uint8List _buildStoredZip(Map<String, Uint8List> entries) {
    final body = BytesBuilder(copy: false);
    final central = BytesBuilder(copy: false);

    final offsets = <String, int>{};
    var bodyLength = 0;

    for (final entry in entries.entries) {
      final nameBytes = Uint8List.fromList(utf8.encode(entry.key));
      final data = entry.value;
      final crc = _crc32(data);

      offsets[entry.key] = bodyLength;

      final localHeader = BytesBuilder(copy: false)
        ..add(_u32(0x04034b50))
        ..add(_u16(20))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0x0021))
        ..add(_u32(crc))
        ..add(_u32(data.length))
        ..add(_u32(data.length))
        ..add(_u16(nameBytes.length))
        ..add(_u16(0))
        ..add(nameBytes)
        ..add(data);

      final localBytes = localHeader.toBytes();
      body.add(localBytes);
      bodyLength += localBytes.length;
    }

    var centralLength = 0;

    for (final entry in entries.entries) {
      final nameBytes = Uint8List.fromList(utf8.encode(entry.key));
      final data = entry.value;
      final crc = _crc32(data);

      final centralHeader = BytesBuilder(copy: false)
        ..add(_u32(0x02014b50))
        ..add(_u16(20))
        ..add(_u16(20))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0x0021))
        ..add(_u32(crc))
        ..add(_u32(data.length))
        ..add(_u32(data.length))
        ..add(_u16(nameBytes.length))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(0))
        ..add(_u32(offsets[entry.key]!))
        ..add(nameBytes);

      final centralBytes = centralHeader.toBytes();
      central.add(centralBytes);
      centralLength += centralBytes.length;
    }

    final end = BytesBuilder(copy: false)
      ..add(_u32(0x06054b50))
      ..add(_u16(0))
      ..add(_u16(0))
      ..add(_u16(entries.length))
      ..add(_u16(entries.length))
      ..add(_u32(centralLength))
      ..add(_u32(bodyLength))
      ..add(_u16(0));

    final result = BytesBuilder(copy: false)
      ..add(body.toBytes())
      ..add(central.toBytes())
      ..add(end.toBytes());

    return result.toBytes();
  }

  Uint8List _u16(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  Uint8List _u32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  int _crc32(Uint8List bytes) {
    var crc = 0xffffffff;

    for (final byte in bytes) {
      crc ^= byte;

      for (var i = 0; i < 8; i++) {
        final mask = -(crc & 1);
        crc = (crc >> 1) ^ (0xedb88320 & mask);
      }
    }

    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  String _csv(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  String _fileName(String exportId, String extension) {
    final token = exportId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

    return 'swat_ride_privacy_export_$token.$extension';
  }

  bool get inMemoryOnly => true;
  bool get fetchesUserData => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get writesFilesystem => false;
  bool get uploadsCloudFile => false;
  bool get autoDownloads => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get overridesRuntimeGate => false;
  bool get callsProvider => false;
  bool get writesBusinessData => false;
  bool get deletesData => false;
}
