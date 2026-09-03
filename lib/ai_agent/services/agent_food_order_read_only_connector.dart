import '../../food/models/cart_item_model.dart';
import '../../food/models/food_order_model.dart';
import '../../food/services/food_order_service.dart';
import '../constants/agent_action_ids.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_tool_request.dart';
import 'agent_read_only_connector.dart';

// =========================================================
// AI AGENT — FOOD ORDER READ-ONLY CONNECTOR
// =========================================================
//
// Safe scope:
// - read one exact food order by orderId
// - return operational status, safe item summary and totals
//
// Never returns:
// - customer ID
// - customer/receiver name or phone
// - delivery address or instructions
// - customer delivery OTP
// - rider ID
// - rider or delivery GPS coordinates
// - arbitrary Firestore documents
//
// No write method is exposed.

class AgentFoodOrderReadOnlyConnector
    implements AgentReadOnlyConnector {
  final FoodOrderService orderService;

  AgentFoodOrderReadOnlyConnector({
    FoodOrderService? orderService,
  }) : orderService = orderService ?? FoodOrderService();

  @override
  String get connectorId => 'connector.food.order.read_only';

  @override
  String get module => 'food';

  @override
  Set<String> get supportedActionIds => const <String>{
        AgentActionId.readFoodOrder,
      };

  @override
  bool supports(String actionId) =>
      supportedActionIds.contains(actionId);

  @override
  Future<AgentReadOnlyPayload> executeReadOnly(
    AgentToolRequest request,
  ) async {
    request.validate();

    if (!supports(request.actionId)) {
      throw AgentFoodOrderConnectorException(
        'Unsupported Food action: ${request.actionId}',
      );
    }

    _validateExactScope(request.actionScope);

    final String orderId =
        (request.actionScope['orderId'] as String).trim();

    final FoodOrderModel? order =
        await orderService.getOrderById(orderId);

    if (order == null) {
      throw const AgentFoodOrderConnectorException(
        'Food order was not found.',
      );
    }

    return AgentReadOnlyPayload(
      actionId: request.actionId,
      module: module,
      data: _safeOrderPayload(order),
      generatedAt: DateTime.now().toUtc(),
    );
  }

  static void _validateExactScope(
    Map<String, dynamic> scope,
  ) {
    if (scope.length != 1 ||
        !scope.containsKey('orderId')) {
      throw const AgentFoodOrderConnectorException(
        'Food order read scope must contain only orderId.',
      );
    }

    final dynamic orderId = scope['orderId'];

    if (orderId is! String ||
        orderId.trim().isEmpty) {
      throw const AgentFoodOrderConnectorException(
        'A valid orderId is required.',
      );
    }

    if (orderId.trim().length > 200) {
      throw const AgentFoodOrderConnectorException(
        'orderId exceeds the allowed length.',
      );
    }
  }

  static Map<String, dynamic> _safeOrderPayload(
    FoodOrderModel order,
  ) {
    return <String, dynamic>{
      'orderId': order.orderId,
      'restaurantId': order.restaurantId,
      'restaurantName': order.restaurantName,
      'status': order.status.name,
      'paymentMethod': order.paymentMethod.name,
      'paymentState': _paymentState(order),
      'hasAssignedRider': order.riderId.trim().isNotEmpty,
      'canTrackOrder': order.canTrackOrder,
      'itemCount': order.items.fold<int>(
        0,
        (
          int currentCount,
          CartItemModel item,
        ) =>
            currentCount + item.quantity,
      ),
      'items': order.items
          .map<Map<String, dynamic>>(
            _safeItemPayload,
          )
          .toList(growable: false),
      'itemsTotal': order.itemsTotal,
      'deliveryFee': order.deliveryFee,
      'discount': order.discount,
      'serviceFee': order.serviceFee,
      'grandTotal': order.grandTotal,
      'createdAt': _date(order.createdAt),
      'updatedAt': _date(order.updatedAt),
    };
  }

  static Map<String, dynamic> _safeItemPayload(
    CartItemModel item,
  ) {
    return <String, dynamic>{
      'menuItemId': item.menuItemId,
      'name': item.menuItemName,
      'variant': item.selectedVariantName,
      'quantity': item.quantity,
      'unitTotal': item.unitTotal,
      'totalPrice': item.totalPrice,
      'addOns': item.selectedAddOns
          .map<Map<String, dynamic>>(
            (SelectedAddOnModel addOn) =>
                <String, dynamic>{
              'name': addOn.name,
              'quantity': addOn.quantity,
              'unitPrice': addOn.unitPrice,
              'totalPrice': addOn.totalPrice,
            },
          )
          .toList(growable: false),
    };
  }

  static String _paymentState(
    FoodOrderModel order,
  ) {
    if (order.paymentMethod == FoodPaymentMethod.cash) {
      return order.status == FoodOrderStatus.delivered
          ? 'cash_collection_expected'
          : 'cash_due';
    }

    return 'electronic_payment_selected';
  }

  static String _date(DateTime value) {
    return value.toUtc().toIso8601String();
  }
}

class AgentFoodOrderConnectorException
    implements Exception {
  final String message;

  const AgentFoodOrderConnectorException(
    this.message,
  );

  @override
  String toString() =>
      'AgentFoodOrderConnectorException: $message';
}