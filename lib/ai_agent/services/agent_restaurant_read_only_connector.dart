import '../../food/models/restaurant_model.dart';
import '../../food/services/restaurant_service.dart';
import '../constants/agent_action_ids.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_tool_request.dart';
import 'agent_read_only_connector.dart';

// =========================================================
// AI AGENT — RESTAURANT READ-ONLY CONNECTOR
// =========================================================
//
// Safe scope:
// - read one exact restaurant by restaurantId
// - return customer-facing operational information
//
// Never returns:
// - owner identity
// - phone number or email
// - exact address, landmark or GPS coordinates
// - CNIC, licence or private document URLs
// - commission or internal business totals
// - rejection, suspension or admin review details
// - arbitrary Firestore documents
//
// No write method is exposed.

class AgentRestaurantReadOnlyConnector
    implements AgentReadOnlyConnector {
  final RestaurantService restaurantService;

  AgentRestaurantReadOnlyConnector({
    RestaurantService? restaurantService,
  }) : restaurantService =
            restaurantService ?? RestaurantService();

  @override
  String get connectorId =>
      'connector.restaurant.read_only';

  @override
  String get module => 'restaurant';

  @override
  Set<String> get supportedActionIds => const <String>{
        AgentActionId.readRestaurant,
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
      throw AgentRestaurantConnectorException(
        'Unsupported Restaurant action: ${request.actionId}',
      );
    }

    _validateExactScope(request.actionScope);

    final String restaurantId =
        (request.actionScope['restaurantId'] as String)
            .trim();

    final RestaurantModel? restaurant =
        await restaurantService.getRestaurantById(
      restaurantId,
    );

    if (restaurant == null) {
      throw const AgentRestaurantConnectorException(
        'Restaurant was not found.',
      );
    }

    return AgentReadOnlyPayload(
      actionId: request.actionId,
      module: module,
      data: _safeRestaurantPayload(restaurant),
      generatedAt: DateTime.now().toUtc(),
    );
  }

  static void _validateExactScope(
    Map<String, dynamic> scope,
  ) {
    if (scope.length != 1 ||
        !scope.containsKey('restaurantId')) {
      throw const AgentRestaurantConnectorException(
        'Restaurant read scope must contain only restaurantId.',
      );
    }

    final dynamic restaurantId = scope['restaurantId'];

    if (restaurantId is! String ||
        restaurantId.trim().isEmpty) {
      throw const AgentRestaurantConnectorException(
        'A valid restaurantId is required.',
      );
    }

    if (restaurantId.trim().length > 200) {
      throw const AgentRestaurantConnectorException(
        'restaurantId exceeds the allowed length.',
      );
    }
  }

  static Map<String, dynamic> _safeRestaurantPayload(
    RestaurantModel restaurant,
  ) {
    return <String, dynamic>{
      'restaurantId': restaurant.id,
      'name': restaurant.name,
      'description': restaurant.description,
      'logoUrl': restaurant.logoUrl,
      'coverImageUrl': restaurant.coverImageUrl,
      'originalMenuImageUrls':
          List<String>.unmodifiable(
        restaurant.originalMenuImageUrls,
      ),
      'city': restaurant.city,
      'area': restaurant.area,
      'categories': List<String>.unmodifiable(
        restaurant.categories,
      ),
      'foodTypes': List<String>.unmodifiable(
        restaurant.foodTypes,
      ),
      'rating': restaurant.rating,
      'totalReviews': restaurant.totalReviews,
      'deliveryFee': restaurant.deliveryFee,
      'minimumOrderAmount':
          restaurant.minimumOrderAmount,
      'minimumDeliveryTimeMinutes':
          restaurant.minimumDeliveryTimeMinutes,
      'maximumDeliveryTimeMinutes':
          restaurant.maximumDeliveryTimeMinutes,
      'maximumDeliveryDistanceKm':
          restaurant.maximumDeliveryDistanceKm,
      'isFreeDeliveryAvailable':
          restaurant.isFreeDeliveryAvailable,
      'openingTime': restaurant.openingTime,
      'closingTime': restaurant.closingTime,
      'openDays': List<int>.unmodifiable(
        restaurant.openDays,
      ),
      'availability': _availability(restaurant),
      'canReceiveOrders': restaurant.canReceiveOrders,
      'isOpen': restaurant.isOpen,
      'isBusy': restaurant.isBusy,
      'isTemporarilyClosed':
          restaurant.isTemporarilyClosed,
      'temporaryClosingReason':
          restaurant.isTemporarilyClosed
              ? restaurant.temporaryClosingReason
              : '',
      'isFeatured': restaurant.isFeatured,
      'isPopular': restaurant.isPopular,
      'isSponsored': restaurant.isSponsored,
      'discountPercentage':
          restaurant.discountPercentage,
      'discountTitle': restaurant.discountTitle,
      'acceptsCash': restaurant.acceptsCash,
      'acceptsWallet': restaurant.acceptsWallet,
      'acceptsJazzCash': restaurant.acceptsJazzCash,
      'acceptsEasypaisa': restaurant.acceptsEasypaisa,
      'hasDigitalMenu': restaurant.hasDigitalMenu,
      'hasOriginalMenuImages':
          restaurant.hasOriginalMenuImages,
      'menuApprovedByAdmin':
          restaurant.menuApprovedByAdmin,
      'defaultPreparationTimeMinutes':
          restaurant.defaultPreparationTimeMinutes,
      'updatedAt': _date(restaurant.updatedAt),
    };
  }

  static String _availability(
    RestaurantModel restaurant,
  ) {
    if (!restaurant.isApproved ||
        !restaurant.isActive ||
        restaurant.isSuspended) {
      return 'unavailable';
    }

    if (restaurant.isTemporarilyClosed) {
      return 'temporarily_closed';
    }

    if (restaurant.isBusy) {
      return 'busy';
    }

    if (restaurant.isOpen) {
      return 'open';
    }

    return 'closed';
  }

  static String _date(DateTime value) {
    return value.toUtc().toIso8601String();
  }
}

class AgentRestaurantConnectorException
    implements Exception {
  final String message;

  const AgentRestaurantConnectorException(
    this.message,
  );

  @override
  String toString() =>
      'AgentRestaurantConnectorException: $message';
}