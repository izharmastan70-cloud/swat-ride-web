// lib/food/food_routes.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Complete Food Module Route Manager
//
// Connected:
// - Customer Food flow
// - Restaurant Partner flow
// - Food Delivery Rider flow
// - Food Admin flow
//
// Existing Ride, Tourism, Hotel, Cargo and Student modules
// remain untouched.
// =============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../feedback/admin/feedback_management_screen.dart';
import '../feedback/models/feedback_model.dart';
import '../feedback/models/feedback_reply_model.dart';
import '../feedback/partner/partner_reviews_screen.dart';
import '../feedback/partner/review_reply_screen.dart';

import 'admin/screens/food_admin_dashboard_screen.dart';
import 'admin/screens/food_analytics_screen.dart';
import 'admin/screens/food_commission_management_screen.dart';
import 'admin/screens/food_order_management_screen.dart';
import 'admin/screens/food_promo_management_screen.dart';
import 'admin/screens/food_reports_screen.dart';
import 'admin/screens/food_restaurant_management_screen.dart';
import 'admin/screens/food_rider_management_screen.dart';
import 'admin/screens/food_settings_screen.dart';
import 'admin/screens/food_support_screen.dart';

import 'models/food_order_model.dart';
import 'models/restaurant_model.dart';

// =============================================================
// RESTAURANT PARTNER
// =============================================================

import 'restaurant_partner/models/food_item_model.dart';
import 'restaurant_partner/models/restaurant_partner_model.dart';
import 'restaurant_partner/screens/add_food_category_screen.dart';
import 'restaurant_partner/screens/add_food_item_screen.dart';
import 'restaurant_partner/screens/edit_food_item_screen.dart';
import 'restaurant_partner/screens/menu_management_screen.dart';
import 'restaurant_partner/screens/menu_preview_screen.dart';
import 'restaurant_partner/screens/restaurant_order_details_screen.dart';
import 'restaurant_partner/screens/restaurant_order_management_screen.dart';
import 'restaurant_partner/screens/restaurant_partner_dashboard_screen.dart';
import 'restaurant_partner/screens/restaurant_partner_disputes_screen.dart';
import 'restaurant_partner/screens/restaurant_partner_earnings_screen.dart';
import 'restaurant_partner/screens/restaurant_partner_notifications_screen.dart';
import 'restaurant_partner/screens/restaurant_partner_registration_screen.dart';
import 'restaurant_partner/screens/restaurant_partner_settings_screen.dart';
import 'restaurant_partner/screens/restaurant_partner_status_screen.dart';
import 'restaurant_partner/screens/profile_screen.dart';

// =============================================================
// FOOD RIDER
// =============================================================

import 'rider/models/food_delivery_rider_model.dart';
import 'rider/screens/food_delivery_active_delivery_screen.dart';
import 'rider/screens/food_delivery_available_orders_screen.dart';
import 'rider/screens/food_delivery_earnings_screen.dart';
import 'rider/screens/food_delivery_history_screen.dart';
import 'rider/screens/food_delivery_notifications_screen.dart';
import 'rider/screens/food_delivery_profile_screen.dart';
import 'rider/screens/food_delivery_rider_dashboard_screen.dart';
import 'rider/screens/food_delivery_rider_disputes_screen.dart';
import 'rider/screens/food_delivery_rider_registration_screen.dart';
import 'rider/screens/food_delivery_rider_status_screen.dart';
import 'rider/screens/food_delivery_support_screen.dart';
import 'rider/screens/food_delivery_wallet_screen.dart';

// =============================================================
// CUSTOMER FOOD
// =============================================================

import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/customer_order_details_screen.dart';
import 'screens/food_home_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/restaurant_details_screen.dart';
import 'screens/restaurant_list_screen.dart';

import 'admin/screens/food_dispute_management_screen.dart';

class FoodRoutes {
  const FoodRoutes._();

  // ===========================================================
  // CUSTOMER ROUTES
  // ===========================================================

  static const String home = '/food';
  static const String cart = '/food_cart';
  static const String checkout = '/food_checkout';
  static const String orderTracking = '/food_order_tracking';
  static const String restaurantDetails = '/food_restaurant_details';
  static const String restaurantList = '/food_restaurants';
  static const String customerOrderDetails = '/food_customer_order_details';

  // ===========================================================
  // RESTAURANT PARTNER ROUTES
  // ===========================================================

  static const String partnerRegistration = '/food_partner_registration';
  static const String partnerStatus = '/food_partner_status';
  static const String partnerDashboard = '/food_partner_dashboard';
  static const String partnerOrders = '/food_partner_orders';
  static const String partnerDisputes = '/food_partner_disputes';
  static const String partnerMenuManagement = '/food_partner_menu_management';
  static const String partnerAddMenuItem = '/food_partner_add_menu_item';
  static const String partnerEditMenuItem = '/food_partner_edit_menu_item';
  static const String partnerAddCategory = '/food_partner_add_category';
  static const String partnerMenuPreview = '/food_partner_menu_preview';
  static const String partnerOrderDetails = '/food_partner_order_details';
  static const String partnerEarnings = '/food_partner_earnings';
  static const String partnerReviews = '/food_partner_reviews';
  static const String partnerProfile = '/food_partner_profile';
  static const String partnerSettings = '/food_partner_settings';
  static const String partnerNotifications = '/food_partner_notifications';

  // ===========================================================
  // FOOD RIDER ROUTES
  // ===========================================================

  static const String riderRegistration = '/food_rider_registration';
  static const String riderStatus = '/food_rider_status';
  static const String riderDashboard = '/food_rider_dashboard';
  static const String riderAvailableOrders = '/food_rider_available_orders';
  static const String riderActiveDelivery = '/food_rider_active_delivery';
  static const String riderDeliveryHistory = '/food_rider_delivery_history';
  static const String riderDisputes = '/food_rider_disputes';
  static const String riderEarnings = '/food_rider_earnings';
  static const String riderReviews = '/food_rider_reviews';
  static const String riderNotifications = '/food_rider_notifications';
  static const String riderProfile = '/food_rider_profile';
  static const String riderWallet = '/food_rider_wallet';
  static const String riderSupport = '/food_rider_support';
  static const String riderOrderDetails = '/food_rider_order_details';

  // ===========================================================
  // FOOD ADMIN ROUTES
  // ===========================================================

  static const String adminDashboard = '/food_admin_dashboard';
  static const String adminRestaurants = '/food_admin_restaurants';
  static const String adminRiders = '/food_admin_riders';
  static const String adminOrders = '/food_admin_orders';
  static const String adminDisputes = '/food_admin_disputes';
  static const String adminReviews = '/food_admin_reviews';
  static const String adminLowRatings = '/food_admin_low_ratings';
  static const String adminReviewReports = '/food_admin_review_reports';
  static const String adminOrderDetails = '/food_admin_order_details';
  static const String adminMenu = '/food_admin_menu';
  static const String adminCommissions = '/food_admin_commissions';
  static const String adminPromos = '/food_admin_promos';
  static const String adminReports = '/food_admin_reports';
  static const String adminAnalytics = '/food_admin_analytics';
  static const String adminSettings = '/food_admin_settings';
  static const String adminSupport = '/food_admin_support';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // =======================================================
      // CUSTOMER
      // =======================================================

      case home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodHomeScreen(),
        );

      case cart:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const CartScreen(),
        );

      case checkout:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const CheckoutScreen(),
        );

      case restaurantList:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const RestaurantListScreen(),
        );

      case customerOrderDetails:
        final Object? arguments = settings.arguments;

        if (arguments is! FoodOrderModel) {
          return _errorRoute(
            settings: settings,
            message: 'Customer food order details are missing.',
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              CustomerOrderDetailsScreen(order: arguments),
        );

      case restaurantDetails:
        final Object? arguments = settings.arguments;

        if (arguments is! RestaurantModel) {
          return _errorRoute(
            settings: settings,
            message: 'Restaurant details are missing.',
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              RestaurantDetailsScreen(restaurant: arguments),
        );

      case orderTracking:
        final Object? arguments = settings.arguments;

        if (arguments is! String || arguments.trim().isEmpty) {
          return _errorRoute(
            settings: settings,
            message: 'Food order ID is missing for tracking.',
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              OrderTrackingScreen(orderId: arguments),
        );

      // =======================================================
      // RESTAURANT PARTNER
      // =======================================================

      case partnerRegistration:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const RestaurantPartnerRegistrationScreen(),
        );

      case partnerStatus:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const RestaurantPartnerStatusScreen(),
        );

      case partnerDashboard:
        final RestaurantPartnerModel? partner = _partnerFrom(
          settings.arguments,
        );

        if (partner == null) {
          return _partnerArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              RestaurantPartnerDashboardScreen(partner: partner),
        );

      case partnerOrders:
        final RestaurantPartnerModel? partner = _partnerFrom(
          settings.arguments,
        );

        if (partner == null) {
          return _partnerArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              RestaurantOrderManagementScreen(partner: partner),
        );

      case partnerDisputes:
        final RestaurantPartnerModel? partner = _partnerFrom(
          settings.arguments,
        );

        if (partner == null) {
          return _partnerArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              RestaurantPartnerDisputesScreen(partner: partner),
        );
      case partnerMenuManagement:
        final RestaurantPartnerModel? partner = _partnerFrom(
          settings.arguments,
        );

        if (partner == null) {
          return _partnerArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              MenuManagementScreen(partner: partner),
        );

      case partnerAddMenuItem:
        final RestaurantPartnerModel? partner = _partnerFrom(
          settings.arguments,
        );

        if (partner == null) {
          return _partnerArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              AddFoodItemScreen(partner: partner),
        );

      case partnerEditMenuItem:
        final Object? arguments = settings.arguments;

        if (arguments is! Map ||
            arguments['partner'] is! RestaurantPartnerModel ||
            arguments['item'] is! RestaurantFoodItemModel) {
          return _errorRoute(
            settings: settings,
            message: 'Food item editing details are invalid.',
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => EditFoodItemScreen(
            partner: arguments['partner'] as RestaurantPartnerModel,
            item: arguments['item'] as RestaurantFoodItemModel,
          ),
        );

      case partnerAddCategory:
        final RestaurantPartnerModel? partner = _partnerFrom(
          settings.arguments,
        );

        if (partner == null) {
          return _partnerArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              AddFoodCategoryScreen(partner: partner),
        );

      case partnerMenuPreview:
        final RestaurantPartnerModel? partner = _partnerFrom(
          settings.arguments,
        );

        if (partner == null) {
          return _partnerArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              MenuPreviewScreen(partner: partner),
        );

      case partnerOrderDetails:
        final Object? arguments = settings.arguments;

        if (arguments is! FoodOrderModel) {
          return _errorRoute(
            settings: settings,
            message: 'Food order details are missing.',
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              RestaurantOrderDetailsScreen(order: arguments),
        );

      case partnerEarnings:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const RestaurantPartnerEarningsScreen(),
        );

      case partnerReviews:
        final RestaurantPartnerModel? partner = _partnerFrom(
          settings.arguments,
        );

        if (partner == null) {
          return _partnerArgumentError(settings);
        }

        if (partner.restaurantId.trim().isEmpty) {
          return _errorRoute(
            settings: settings,
            message: 'Approved restaurant record is not available.',
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => PartnerReviewsScreen(
            serviceType: FeedbackServiceType.food,
            targetType: FeedbackTargetType.restaurant,
            targetId: partner.restaurantId,
            partnerName: partner.restaurantName,
            onReplyRequested: (FeedbackModel review) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => ReviewReplyScreen(
                    review: review,
                    authorId: partner.userId,
                    authorName: partner.restaurantName,
                    authorType: FeedbackReplyAuthorType.restaurantOwner,
                  ),
                ),
              );
            },
          ),
        );

      case partnerProfile:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const ProfileScreen(),
        );

      case partnerSettings:
        final RestaurantPartnerModel? partner = _partnerFrom(
          settings.arguments,
        );

        if (partner == null) {
          return _partnerArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              RestaurantPartnerSettingsScreen(partner: partner),
        );

      case partnerNotifications:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const RestaurantPartnerNotificationsScreen(),
        );

      case riderRegistration:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const FoodDeliveryRiderRegistrationScreen(),
        );

      case riderStatus:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const FoodDeliveryRiderStatusScreen(),
        );

      case riderDashboard:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              FoodDeliveryRiderDashboardScreen(rider: rider),
        );

      case riderAvailableOrders:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              FoodDeliveryAvailableOrdersScreen(rider: rider),
        );

      case riderActiveDelivery:
        final Object? arguments = settings.arguments;

        if (arguments is! Map ||
            arguments['rider'] is! FoodDeliveryRiderModel ||
            arguments['order'] is! FoodOrderModel) {
          return _errorRoute(
            settings: settings,
            message:
                'Active delivery details are missing. Open an assigned order first.',
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => FoodDeliveryActiveDeliveryScreen(
            rider: arguments['rider'] as FoodDeliveryRiderModel,
            order: arguments['order'] as FoodOrderModel,
          ),
        );

      case riderDeliveryHistory:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              FoodDeliveryHistoryScreen(rider: rider),
        );

      case riderReviews:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        if (rider.riderId.trim().isEmpty) {
          return _errorRoute(
            settings: settings,
            message: 'Approved Food Rider record is not available.',
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => PartnerReviewsScreen(
            serviceType: FeedbackServiceType.food,
            targetType: FeedbackTargetType.foodRider,
            targetId: rider.riderId,
            partnerName: rider.fullName,
            onReplyRequested: (FeedbackModel review) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => ReviewReplyScreen(
                    review: review,
                    authorId: rider.userId,
                    authorName: rider.fullName,
                    authorType: FeedbackReplyAuthorType.foodRider,
                  ),
                ),
              );
            },
          ),
        );
      case riderDisputes:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              FoodDeliveryRiderDisputesScreen(rider: rider),
        );
      case riderEarnings:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              FoodDeliveryEarningsScreen(rider: rider),
        );

      case riderNotifications:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              FoodDeliveryNotificationsScreen(rider: rider),
        );

      case riderProfile:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              FoodDeliveryProfileScreen(rider: rider),
        );

      case riderWallet:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              FoodDeliveryWalletScreen(rider: rider),
        );

      case riderSupport:
        final FoodDeliveryRiderModel? rider = _riderFrom(settings.arguments);

        if (rider == null) {
          return _riderArgumentError(settings);
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              FoodDeliverySupportScreen(rider: rider),
        );

      case riderOrderDetails:
        final Object? arguments = settings.arguments;

        if (arguments is! FoodOrderModel) {
          return _errorRoute(
            settings: settings,
            message: 'Food Rider order details are missing.',
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              CustomerOrderDetailsScreen(order: arguments),
        );

      // =======================================================
      // FOOD ADMIN
      // =======================================================

      case adminDashboard:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodAdminDashboardScreen(),
        );

      case adminRestaurants:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const FoodRestaurantManagementScreen(),
        );

      case adminRiders:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodRiderManagementScreen(),
        );

      case adminOrders:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodOrderManagementScreen(),
        );
      case adminReviews:
        final String adminId =
            FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (BuildContext context) {
            if (adminId.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Food Reviews')),
                body: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Admin login is required to moderate Food reviews.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            return FeedbackManagementScreen(
              adminId: adminId,
              initialServiceType: FeedbackServiceType.food,
              lockServiceType: true,
              reviewsOnly: true,
            );
          },
        );

      case adminLowRatings:
        final String adminId =
            FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (BuildContext context) {
            if (adminId.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Low Rating Food Reviews')),
                body: const Center(child: Text('Admin login is required.')),
              );
            }

            return FeedbackManagementScreen(
              adminId: adminId,
              initialServiceType: FeedbackServiceType.food,
              lockServiceType: true,
              lowRatingOnly: true,
              lowRatingMaximum: 2,
            );
          },
        );

      case adminReviewReports:
        final String adminId =
            FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (BuildContext context) {
            if (adminId.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Reported Food Reviews')),
                body: const Center(child: Text('Admin login is required.')),
              );
            }

            return FeedbackManagementScreen(
              adminId: adminId,
              initialServiceType: FeedbackServiceType.food,
              lockServiceType: true,
              reportsOnly: true,
              reportsServiceType: FeedbackServiceType.food,
            );
          },
        );

      case adminDisputes:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const FoodDisputeManagementScreen(),
        );

      case adminOrderDetails:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodOrderManagementScreen(),
        );

      case adminMenu:
        return _comingSoonRoute(
          settings: settings,
          title: 'Food Menu Administration',
          message:
              'Restaurant menu control is currently handled from Restaurant Management and Partner Menu screens.',
        );

      case adminCommissions:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) =>
              const FoodCommissionManagementScreen(),
        );

      case adminPromos:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodPromoManagementScreen(),
        );

      case adminReports:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodReportsScreen(),
        );

      case adminAnalytics:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodAnalyticsScreen(),
        );

      case adminSettings:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodSettingsScreen(),
        );

      case adminSupport:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => const FoodSupportScreen(),
        );

      default:
        return null;
    }
  }

  // ===========================================================
  // ARGUMENT HELPERS
  // ===========================================================

  static RestaurantPartnerModel? _partnerFrom(Object? arguments) {
    if (arguments is RestaurantPartnerModel) {
      return arguments;
    }

    if (arguments is Map && arguments['partner'] is RestaurantPartnerModel) {
      return arguments['partner'] as RestaurantPartnerModel;
    }

    return null;
  }

  static FoodDeliveryRiderModel? _riderFrom(Object? arguments) {
    if (arguments is FoodDeliveryRiderModel) {
      return arguments;
    }

    if (arguments is Map && arguments['rider'] is FoodDeliveryRiderModel) {
      return arguments['rider'] as FoodDeliveryRiderModel;
    }

    return null;
  }

  static Route<void> _partnerArgumentError(RouteSettings settings) {
    return _errorRoute(
      settings: settings,
      message: 'Restaurant Partner details are missing.',
    );
  }

  static Route<void> _riderArgumentError(RouteSettings settings) {
    return _errorRoute(
      settings: settings,
      message: 'Food Delivery Rider details are missing.',
    );
  }

  // ===========================================================
  // PLACEHOLDER / ERROR ROUTES
  // ===========================================================

  static Route<void> _comingSoonRoute({
    required RouteSettings settings,
    required String title,
    required String message,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D0D0D),
            title: Text(title),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.construction_outlined,
                    color: Color(0xFFFFD60A),
                    size: 66,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD60A),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Route<void> _errorRoute({
    required RouteSettings settings,
    required String message,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D0D0D),
            title: const Text('Food Delivery'),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD60A),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
