/// AI Agent Backend Connection Service
/// 
/// Manages connections to remote AI agent services (Email, WhatsApp, Custom Agents)
/// and provides unified interface for the Flutter app to invoke them.
///
/// Handles:
/// - Connection pooling and health checks
/// - Retry logic and exponential backoff
/// - Request signing and verification
/// - Telemetry and error reporting

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Result of an agent connection check
class AgentConnectionStatus {
  final String agentId;
  final bool isHealthy;
  final String? endpoint;
  final DateTime lastCheckedAt;
  final String? errorMessage;

  const AgentConnectionStatus({
    required this.agentId,
    required this.isHealthy,
    this.endpoint,
    required this.lastCheckedAt,
    this.errorMessage,
  });

  factory AgentConnectionStatus.unhealthy(
    String agentId, {
    String? errorMessage,
  }) {
    return AgentConnectionStatus(
      agentId: agentId,
      isHealthy: false,
      lastCheckedAt: DateTime.now(),
      errorMessage: errorMessage,
    );
  }

  factory AgentConnectionStatus.healthy(
    String agentId, {
    String? endpoint,
  }) {
    return AgentConnectionStatus(
      agentId: agentId,
      isHealthy: true,
      endpoint: endpoint,
      lastCheckedAt: DateTime.now(),
    );
  }
}

/// Result of an agent invocation
class AgentInvocationResult {
  final bool success;
  final String agentId;
  final dynamic responseData;
  final String? errorCode;
  final String? errorMessage;
  final DateTime invokedAt;
  final Duration? executionDuration;

  const AgentInvocationResult({
    required this.success,
    required this.agentId,
    this.responseData,
    this.errorCode,
    this.errorMessage,
    required this.invokedAt,
    this.executionDuration,
  });

  factory AgentInvocationResult.success(
    String agentId, {
    dynamic responseData,
  }) {
    return AgentInvocationResult(
      success: true,
      agentId: agentId,
      responseData: responseData,
      invokedAt: DateTime.now(),
    );
  }

  factory AgentInvocationResult.failure(
    String agentId, {
    String? errorCode,
    String? errorMessage,
  }) {
    return AgentInvocationResult(
      success: false,
      agentId: agentId,
      errorCode: errorCode,
      errorMessage: errorMessage,
      invokedAt: DateTime.now(),
    );
  }
}

/// Main agent connection service
class AiAgentConnectionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _client;
  
  static const String _configCollection = 'ai_agent_config';
  static const String _healthCheckCollection = 'agent_health_checks';
  static const Duration _healthCheckInterval = Duration(minutes: 5);
  static const Duration _requestTimeout = Duration(seconds: 30);

  // Connection cache
  final Map<String, AgentConnectionStatus> _connectionCache = {};
  final Map<String, DateTime> _lastHealthCheckTime = {};

  AiAgentConnectionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? client,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client();

  /// Get connection status for a specific agent
  /// 
  /// Checks cache first, then validates against Firestore config.
  /// Performs health check if cache is stale.
  Future<AgentConnectionStatus> getConnectionStatus(String agentId) async {
    try {
      // Check cache
      if (_connectionCache.containsKey(agentId)) {
        final cached = _connectionCache[agentId]!;
        final lastCheck = _lastHealthCheckTime[agentId];
        
        if (lastCheck != null &&
            DateTime.now().difference(lastCheck) < _healthCheckInterval) {
          return cached;
        }
      }

      // Fetch fresh config from Firestore
      final doc = await _firestore
          .collection(_configCollection)
          .doc(agentId)
          .get()
          .timeout(_requestTimeout);

      if (!doc.exists) {
        return AgentConnectionStatus.unhealthy(
          agentId,
          errorMessage: 'Agent configuration not found.',
        );
      }

      final data = doc.data()!;
      
      if (data['enabled'] != true) {
        return AgentConnectionStatus.unhealthy(
          agentId,
          errorMessage: 'Agent is disabled.',
        );
      }

      final endpoint = data['endpoint'] as String?;
      if (endpoint == null || endpoint.isEmpty) {
        return AgentConnectionStatus.unhealthy(
          agentId,
          errorMessage: 'Agent endpoint not configured.',
        );
      }

      // Perform health check
      final isHealthy = await _checkAgentHealth(endpoint);

      final status = isHealthy
          ? AgentConnectionStatus.healthy(agentId, endpoint: endpoint)
          : AgentConnectionStatus.unhealthy(
              agentId,
              errorMessage: 'Health check failed.',
            );

      // Cache result
      _connectionCache[agentId] = status;
      _lastHealthCheckTime[agentId] = DateTime.now();

      return status;
    } catch (e) {
      return AgentConnectionStatus.unhealthy(
        agentId,
        errorMessage: 'Error checking connection: $e',
      );
    }
  }

  /// Invoke a specific agent with request data
  /// 
  /// Ensures authentication, validates connection, and handles retries.
  Future<AgentInvocationResult> invokeAgent(
    String agentId, {
    required Map<String, dynamic> requestData,
    int maxRetries = 2,
  }) async {
    final startTime = DateTime.now();

    try {
      // Verify user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        return AgentInvocationResult.failure(
          agentId,
          errorCode: 'AUTH_REQUIRED',
          errorMessage: 'User must be authenticated.',
        );
      }

      // Check connection status
      final connectionStatus = await getConnectionStatus(agentId);
      if (!connectionStatus.isHealthy) {
        return AgentInvocationResult.failure(
          agentId,
          errorCode: 'CONNECTION_UNAVAILABLE',
          errorMessage: connectionStatus.errorMessage,
        );
      }

      final endpoint = connectionStatus.endpoint;
      if (endpoint == null) {
        return AgentInvocationResult.failure(
          agentId,
          errorCode: 'ENDPOINT_MISSING',
          errorMessage: 'Agent endpoint is not available.',
        );
      }

      // Get ID token for request signing
      final idToken = await user.getIdToken();

      // Build request with authentication
      final request = {
        'agentId': agentId,
        'userId': user.uid,
        'timestamp': DateTime.now().toIso8601String(),
        'data': requestData,
      };

      // Invoke with retry logic
      return await _invokeWithRetry(
        agentId: agentId,
        endpoint: endpoint,
        request: request,
        idToken: idToken,
        attempt: 0,
        maxRetries: maxRetries,
        startTime: startTime,
      );
    } catch (e) {
      return AgentInvocationResult(
        success: false,
        agentId: agentId,
        errorCode: 'INVOCATION_EXCEPTION',
        errorMessage: 'Unexpected error: $e',
        invokedAt: DateTime.now(),
        executionDuration: DateTime.now().difference(startTime),
      );
    }
  }

  Future<AgentInvocationResult> _invokeWithRetry({
    required String agentId,
    required String endpoint,
    required Map<String, dynamic> request,
    required String idToken,
    required int attempt,
    required int maxRetries,
    required DateTime startTime,
  }) async {
    try {
      final http.Response response = await _client
          .post(
            _endpointUri(endpoint, 'invoke'),
            headers: <String, String>{
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(request),
          )
          .timeout(_requestTimeout);
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic>? body = decoded is Map<String, dynamic>
          ? decoded
          : null;
      if (response.statusCode < 200 || response.statusCode >= 300 ||
          body?['ok'] != true) {
        throw _AgentHttpException(response.statusCode);
      }

      final duration = DateTime.now().difference(startTime);
      return AgentInvocationResult(
        success: true,
        agentId: agentId,
        responseData: {'status': 'pending', 'requestId': request['timestamp']},
        invokedAt: DateTime.now(),
        executionDuration: duration,
      );
    } catch (e) {
      if (_isTransientFailure(e) && attempt < maxRetries) {
        final backoffMs = 100 * (1 << attempt); // 100ms, 200ms, 400ms
        await Future.delayed(Duration(milliseconds: backoffMs));
        
        return _invokeWithRetry(
          agentId: agentId,
          endpoint: endpoint,
          request: request,
          idToken: idToken,
          attempt: attempt + 1,
          maxRetries: maxRetries,
          startTime: startTime,
        );
      }

      final duration = DateTime.now().difference(startTime);
      return AgentInvocationResult(
        success: false,
        agentId: agentId,
        errorCode: e is _AgentHttpException
            ? 'AGENT_HTTP_${e.statusCode}'
            : 'INVOCATION_FAILED',
        errorMessage: 'Agent invocation failed.',
        invokedAt: DateTime.now(),
        executionDuration: duration,
      );
    }
  }

  /// Check if agent endpoint is responding
  Future<bool> _checkAgentHealth(String endpoint) async {
    try {
      final response = await _client
          .get(_endpointUri(endpoint, 'health'))
          .timeout(_requestTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  Uri _endpointUri(String endpoint, String route) {
    final Uri base = Uri.parse(endpoint.endsWith('/') ? endpoint : '$endpoint/');
    if (!base.hasScheme || !base.hasAuthority) {
      throw const FormatException('Agent endpoint must be an absolute URL.');
    }
    return base.resolve(route);
  }

  bool _isTransientFailure(Object error) {
    if (error is TimeoutException || error is http.ClientException) return true;
    return error is _AgentHttpException && error.statusCode >= 500;
  }

  /// Clear connection cache to force fresh checks
  void clearCache() {
    _connectionCache.clear();
    _lastHealthCheckTime.clear();
  }

  /// Get all configured agents
  Future<List<String>> getConfiguredAgents() async {
    try {
      final snapshot = await _firestore
          .collection(_configCollection)
          .where('enabled', isEqualTo: true)
          .get()
          .timeout(_requestTimeout);

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// Report agent invocation telemetry
  Future<void> reportTelemetry(
    AgentInvocationResult result, {
    String? userId,
  }) async {
    try {
      final user = userId ?? _auth.currentUser?.uid;
      if (user == null) return;

      await _firestore
          .collection('agent_invocation_telemetry')
          .add({
            'agentId': result.agentId,
            'userId': user,
            'success': result.success,
            'errorCode': result.errorCode,
            'invokedAt': result.invokedAt.toIso8601String(),
            'durationMs': result.executionDuration?.inMilliseconds,
            'timestamp': FieldValue.serverTimestamp(),
          })
          .timeout(_requestTimeout);
    } catch (e) {
      // Silently fail telemetry reporting
    }
  }
}

class _AgentHttpException implements Exception {
  const _AgentHttpException(this.statusCode);

  final int statusCode;
}
