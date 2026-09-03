// SWAT RIDE - UNIVERSAL SAFETY & SOS WIDGETS
//
// Shared Yango-style safety widgets for:
// - All customers
// - All drivers and delivery riders
// - Parents, guardians and students
// - Restaurant partners
// - Cargo and parcel users
// - Hotel guests, owners and staff
// - Tour customers, guides and tourism drivers
// - Admin and safety agents
//
// These widgets contain reusable UI only.
// Actual Firestore/SOS logic remains inside UniversalSafetyService.

import 'package:flutter/material.dart';

import '../models/safety_models.dart';

/// Main shield-style Safety button.
///
/// Use this button on active Ride, Food, Cargo, Student, Hotel and Tour pages.
class UniversalSafetyButton extends StatelessWidget {
  const UniversalSafetyButton({
    super.key,
    required this.onPressed,
    this.label = 'Safety',
    this.enabled = true,
    this.isLoading = false,
    this.compact = false,
    this.showBorder = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final String label;

  final bool enabled;
  final bool isLoading;
  final bool compact;
  final bool showBorder;

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color resolvedForegroundColor =
        foregroundColor ?? theme.colorScheme.primary;

    final Color resolvedBackgroundColor =
        backgroundColor ?? theme.colorScheme.surface;

    final VoidCallback? action =
        enabled && !isLoading ? onPressed : null;

    if (compact) {
      return IconButton(
        tooltip: label,
        onPressed: action,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: resolvedForegroundColor,
                ),
              )
            : Icon(
                Icons.shield_outlined,
                color: enabled
                    ? resolvedForegroundColor
                    : theme.disabledColor,
              ),
      );
    }

    return Material(
      color: resolvedBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 52,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: showBorder
                ? Border.all(
                    color: enabled
                        ? resolvedForegroundColor.withValues(
                            alpha: 0.25,
                          )
                        : theme.disabledColor.withValues(
                            alpha: 0.20,
                          ),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isLoading)
                SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: resolvedForegroundColor,
                  ),
                )
              else
                Icon(
                  Icons.shield_outlined,
                  size: 22,
                  color: enabled
                      ? resolvedForegroundColor
                      : theme.disabledColor,
                ),
              const SizedBox(width: 9),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: enabled
                      ? resolvedForegroundColor
                      : theme.disabledColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large red Emergency SOS button.
///
/// The calling screen should handle confirmation/countdown before creating
/// the real SOS incident.
class EmergencySosButton extends StatelessWidget {
  const EmergencySosButton({
    super.key,
    required this.onPressed,
    this.label = 'Emergency SOS',
    this.subtitle = 'Use only for a real emergency',
    this.enabled = true,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final String subtitle;

  final bool enabled;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color emergencyColor = theme.colorScheme.error;

    final Widget button = Material(
      color: enabled
          ? emergencyColor
          : theme.disabledColor.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled && !isLoading ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.sos,
                  color: Colors.white,
                  size: 28,
                ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(
                            alpha: 0.88,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!fullWidth) {
      return button;
    }

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}

/// Reusable action tile for the Yango-style Safety Center bottom sheet.
///
/// Examples:
/// - Share live trip
/// - Trusted contacts
/// - Call support
/// - Report safety issue
class SafetyActionTile extends StatelessWidget {
  const SafetyActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle = '',
    this.enabled = true,
    this.isDestructive = false,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  final VoidCallback? onTap;

  final bool enabled;
  final bool isDestructive;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color activeColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    final Color contentColor =
        enabled ? activeColor : theme.disabledColor;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: contentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: contentColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style:
                          theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? theme.colorScheme.onSurface
                            : theme.disabledColor,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            theme.textTheme.bodySmall?.copyWith(
                          color: enabled
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.disabledColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.disabledColor,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small section title used inside Safety Center screens and sheets.
class SafetySectionTitle extends StatelessWidget {
  const SafetySectionTitle({
    super.key,
    required this.title,
    this.subtitle = '',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Displays current SOS or safety incident status.
class SafetyStatusBanner extends StatelessWidget {
  const SafetyStatusBanner({
    super.key,
    required this.status,
    this.message = '',
    this.compact = false,
  });

  final SafetyIncidentStatus status;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final _SafetyStatusPresentation presentation =
        _presentationForStatus(
      context,
      status,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 15,
        vertical: compact ? 10 : 13,
      ),
      decoration: BoxDecoration(
        color: presentation.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: presentation.color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            presentation.icon,
            color: presentation.color,
            size: compact ? 20 : 23,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  presentation.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: presentation.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (message.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays GPS, internet or tracking availability.
class SafetySystemStatusChip extends StatelessWidget {
  const SafetySystemStatusChip({
    super.key,
    required this.label,
    required this.isAvailable,
    this.availableText = 'Available',
    this.unavailableText = 'Unavailable',
    this.availableIcon = Icons.check_circle_outline,
    this.unavailableIcon = Icons.error_outline,
  });

  final String label;
  final bool isAvailable;

  final String availableText;
  final String unavailableText;

  final IconData availableIcon;
  final IconData unavailableIcon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color statusColor = isAvailable
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isAvailable
                ? availableIcon
                : unavailableIcon,
            size: 17,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: '
            '${isAvailable ? availableText : unavailableText}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Common incident information card.
///
/// This can display Ride ID, Food order ID, Hotel booking ID or Tour ID.
class SafetyReferenceCard extends StatelessWidget {
  const SafetyReferenceCard({
    super.key,
    required this.contextData,
  });

  final SafetyContext contextData;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final String title =
        contextData.serviceTitle.trim().isNotEmpty
            ? contextData.serviceTitle.trim()
            : safetyServiceLabel(contextData.serviceType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              safetyServiceIcon(contextData.serviceType),
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Reference: ${contextData.referenceId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (contextData.serviceSubtitle
                    .trim()
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    contextData.serviceSubtitle.trim(),
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows one emergency-category option.
class SafetyEmergencyCategoryTile extends StatelessWidget {
  const SafetyEmergencyCategoryTile({
    super.key,
    required this.category,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  final SafetyEmergencyCategory category;
  final VoidCallback? onTap;

  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color categoryColor =
        emergencyCategoryColor(context, category);

    return Material(
      color: selected
          ? categoryColor.withValues(alpha: 0.12)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? categoryColor
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                emergencyCategoryIcon(category),
                color: enabled
                    ? categoryColor
                    : theme.disabledColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  emergencyCategoryLabel(category),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? theme.colorScheme.onSurface
                        : theme.disabledColor,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: categoryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PUBLIC LABEL AND ICON HELPERS
// -----------------------------------------------------------------------------

String safetyServiceLabel(SafetyServiceType serviceType) {
  switch (serviceType) {
    case SafetyServiceType.general:
      return 'General Safety';

    case SafetyServiceType.normalRide:
      return 'Ride Safety';

    case SafetyServiceType.driver:
      return 'Driver Safety';

    case SafetyServiceType.studentRide:
      return 'Student Ride Safety';

    case SafetyServiceType.foodDelivery:
      return 'Food Delivery Safety';

    case SafetyServiceType.restaurantPartner:
      return 'Restaurant Safety';

    case SafetyServiceType.cargoDelivery:
      return 'Cargo Safety';

    case SafetyServiceType.parcelDelivery:
      return 'Parcel Safety';

    case SafetyServiceType.hotelBooking:
      return 'Hotel Booking Safety';

    case SafetyServiceType.hotelStay:
      return 'Hotel Stay Safety';

    case SafetyServiceType.tourBooking:
      return 'Tour Booking Safety';

    case SafetyServiceType.activeTour:
      return 'Active Tour Safety';

    case SafetyServiceType.tourismDriver:
      return 'Tourism Driver Safety';

    case SafetyServiceType.tourGuide:
      return 'Tour Guide Safety';

    case SafetyServiceType.schoolTransport:
      return 'School Transport Safety';
  }
}

IconData safetyServiceIcon(SafetyServiceType serviceType) {
  switch (serviceType) {
    case SafetyServiceType.general:
      return Icons.shield_outlined;

    case SafetyServiceType.normalRide:
    case SafetyServiceType.driver:
      return Icons.local_taxi_outlined;

    case SafetyServiceType.studentRide:
    case SafetyServiceType.schoolTransport:
      return Icons.school_outlined;

    case SafetyServiceType.foodDelivery:
      return Icons.delivery_dining_outlined;

    case SafetyServiceType.restaurantPartner:
      return Icons.restaurant_outlined;

    case SafetyServiceType.cargoDelivery:
      return Icons.local_shipping_outlined;

    case SafetyServiceType.parcelDelivery:
      return Icons.inventory_2_outlined;

    case SafetyServiceType.hotelBooking:
    case SafetyServiceType.hotelStay:
      return Icons.hotel_outlined;

    case SafetyServiceType.tourBooking:
    case SafetyServiceType.activeTour:
      return Icons.travel_explore_outlined;

    case SafetyServiceType.tourismDriver:
      return Icons.directions_car_filled_outlined;

    case SafetyServiceType.tourGuide:
      return Icons.tour_outlined;
  }
}

String emergencyCategoryLabel(
  SafetyEmergencyCategory category,
) {
  switch (category) {
    case SafetyEmergencyCategory.immediateDanger:
      return 'Immediate danger';

    case SafetyEmergencyCategory.medicalEmergency:
      return 'Medical emergency';

    case SafetyEmergencyCategory.accident:
      return 'Accident';

    case SafetyEmergencyCategory.physicalThreat:
      return 'Physical threat';

    case SafetyEmergencyCategory.harassment:
      return 'Harassment';

    case SafetyEmergencyCategory.robbery:
      return 'Robbery';

    case SafetyEmergencyCategory.theft:
      return 'Theft';

    case SafetyEmergencyCategory.unsafeLocation:
      return 'Unsafe location';

    case SafetyEmergencyCategory.unableToContact:
      return 'Unable to contact';

    case SafetyEmergencyCategory.other:
      return 'Other emergency';

    case SafetyEmergencyCategory.dangerousDriving:
      return 'Dangerous driving';

    case SafetyEmergencyCategory.routeDeviation:
      return 'Route deviation';

    case SafetyEmergencyCategory.driverMismatch:
      return 'Driver mismatch';

    case SafetyEmergencyCategory.vehicleMismatch:
      return 'Vehicle mismatch';

    case SafetyEmergencyCategory.passengerThreat:
      return 'Passenger threat';

    case SafetyEmergencyCategory.suspectedKidnapping:
      return 'Suspected kidnapping';

    case SafetyEmergencyCategory.vehicleBreakdown:
      return 'Vehicle breakdown';

    case SafetyEmergencyCategory.childMissing:
      return 'Child missing';

    case SafetyEmergencyCategory.unauthorizedGuardian:
      return 'Unauthorized guardian';

    case SafetyEmergencyCategory.childMedicalEmergency:
      return 'Child medical emergency';

    case SafetyEmergencyCategory.studentNotPickedUp:
      return 'Student not picked up';

    case SafetyEmergencyCategory.studentNotDropped:
      return 'Student not dropped';

    case SafetyEmergencyCategory.schoolArrivalNotConfirmed:
      return 'School arrival not confirmed';

    case SafetyEmergencyCategory.unauthorizedHandover:
      return 'Unauthorized handover';

    case SafetyEmergencyCategory.childLeftInVehicle:
      return 'Child left in vehicle';

    case SafetyEmergencyCategory.unsafeDeliveryLocation:
      return 'Unsafe delivery location';

    case SafetyEmergencyCategory.customerThreatToRider:
      return 'Customer threatening rider';

    case SafetyEmergencyCategory.riderThreatToCustomer:
      return 'Rider threatening customer';

    case SafetyEmergencyCategory.unsafeCashCollection:
      return 'Unsafe cash collection';

    case SafetyEmergencyCategory.orderTamperingConcern:
      return 'Order tampering concern';

    case SafetyEmergencyCategory.deliveryRiderAccident:
      return 'Delivery rider accident';

    case SafetyEmergencyCategory.cargoTheftAttempt:
      return 'Cargo theft attempt';

    case SafetyEmergencyCategory.cargoDamage:
      return 'Cargo damage';

    case SafetyEmergencyCategory.cargoVehicleHijacking:
      return 'Cargo vehicle hijacking';

    case SafetyEmergencyCategory.receiverLocationUnsafe:
      return 'Receiver location unsafe';

    case SafetyEmergencyCategory.dangerousGoodsDetected:
      return 'Dangerous goods detected';

    case SafetyEmergencyCategory.deliveryOtpProblem:
      return 'Delivery OTP problem';

    case SafetyEmergencyCategory.fireOrSmoke:
      return 'Fire or smoke';

    case SafetyEmergencyCategory.unauthorizedRoomAccess:
      return 'Unauthorized room access';

    case SafetyEmergencyCategory.hotelStaffThreat:
      return 'Hotel staff threat';

    case SafetyEmergencyCategory.violentGuest:
      return 'Violent guest';

    case SafetyEmergencyCategory.evacuationRequired:
      return 'Evacuation required';

    case SafetyEmergencyCategory.unsafeRoom:
      return 'Unsafe room';

    case SafetyEmergencyCategory.guestMissing:
      return 'Guest missing';

    case SafetyEmergencyCategory.touristMissing:
      return 'Tourist missing';

    case SafetyEmergencyCategory.groupSeparated:
      return 'Group separated';

    case SafetyEmergencyCategory.guideUnreachable:
      return 'Guide unreachable';

    case SafetyEmergencyCategory.tourismDriverUnreachable:
      return 'Tourism driver unreachable';

    case SafetyEmergencyCategory.unsafeWeather:
      return 'Unsafe weather';

    case SafetyEmergencyCategory.unsafeRoad:
      return 'Unsafe road';

    case SafetyEmergencyCategory.mountainEmergency:
      return 'Mountain emergency';

    case SafetyEmergencyCategory.groupEmergency:
      return 'Whole group emergency';
  }
}

IconData emergencyCategoryIcon(
  SafetyEmergencyCategory category,
) {
  switch (category) {
    case SafetyEmergencyCategory.medicalEmergency:
    case SafetyEmergencyCategory.childMedicalEmergency:
      return Icons.medical_services_outlined;

    case SafetyEmergencyCategory.accident:
    case SafetyEmergencyCategory.deliveryRiderAccident:
      return Icons.car_crash_outlined;

    case SafetyEmergencyCategory.fireOrSmoke:
      return Icons.local_fire_department_outlined;

    case SafetyEmergencyCategory.childMissing:
    case SafetyEmergencyCategory.guestMissing:
    case SafetyEmergencyCategory.touristMissing:
      return Icons.person_search_outlined;

    case SafetyEmergencyCategory.vehicleBreakdown:
      return Icons.car_repair_outlined;

    case SafetyEmergencyCategory.routeDeviation:
    case SafetyEmergencyCategory.unsafeRoad:
      return Icons.alt_route_outlined;

    case SafetyEmergencyCategory.unsafeWeather:
      return Icons.thunderstorm_outlined;

    case SafetyEmergencyCategory.mountainEmergency:
      return Icons.landscape_outlined;

    case SafetyEmergencyCategory.robbery:
    case SafetyEmergencyCategory.theft:
    case SafetyEmergencyCategory.cargoTheftAttempt:
    case SafetyEmergencyCategory.cargoVehicleHijacking:
      return Icons.security_outlined;

    case SafetyEmergencyCategory.harassment:
    case SafetyEmergencyCategory.physicalThreat:
    case SafetyEmergencyCategory.passengerThreat:
    case SafetyEmergencyCategory.customerThreatToRider:
    case SafetyEmergencyCategory.riderThreatToCustomer:
    case SafetyEmergencyCategory.hotelStaffThreat:
    case SafetyEmergencyCategory.violentGuest:
      return Icons.warning_amber_rounded;

    case SafetyEmergencyCategory.unauthorizedGuardian:
    case SafetyEmergencyCategory.unauthorizedHandover:
    case SafetyEmergencyCategory.unauthorizedRoomAccess:
      return Icons.no_accounts_outlined;

    case SafetyEmergencyCategory.immediateDanger:
    case SafetyEmergencyCategory.suspectedKidnapping:
    case SafetyEmergencyCategory.groupEmergency:
      return Icons.sos;

    default:
      return Icons.report_problem_outlined;
  }
}

Color emergencyCategoryColor(
  BuildContext context,
  SafetyEmergencyCategory category,
) {
  final ThemeData theme = Theme.of(context);

  switch (category) {
    case SafetyEmergencyCategory.immediateDanger:
    case SafetyEmergencyCategory.suspectedKidnapping:
    case SafetyEmergencyCategory.childMissing:
    case SafetyEmergencyCategory.fireOrSmoke:
    case SafetyEmergencyCategory.groupEmergency:
      return theme.colorScheme.error;

    case SafetyEmergencyCategory.medicalEmergency:
    case SafetyEmergencyCategory.childMedicalEmergency:
      return theme.colorScheme.tertiary;

    default:
      return theme.colorScheme.primary;
  }
}

// -----------------------------------------------------------------------------
// PRIVATE STATUS HELPERS
// -----------------------------------------------------------------------------

_SafetyStatusPresentation _presentationForStatus(
  BuildContext context,
  SafetyIncidentStatus status,
) {
  final ThemeData theme = Theme.of(context);

  switch (status) {
    case SafetyIncidentStatus.created:
      return _SafetyStatusPresentation(
        title: 'Emergency created',
        icon: Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
      );

    case SafetyIncidentStatus.alertSent:
      return _SafetyStatusPresentation(
        title: 'Alert sent',
        icon: Icons.notifications_active_outlined,
        color: theme.colorScheme.primary,
      );

    case SafetyIncidentStatus.acknowledged:
      return _SafetyStatusPresentation(
        title: 'Safety team acknowledged',
        icon: Icons.verified_outlined,
        color: theme.colorScheme.primary,
      );

    case SafetyIncidentStatus.agentAssigned:
      return _SafetyStatusPresentation(
        title: 'Safety agent assigned',
        icon: Icons.support_agent_outlined,
        color: theme.colorScheme.primary,
      );

    case SafetyIncidentStatus.contactingUser:
      return _SafetyStatusPresentation(
        title: 'Contacting user',
        icon: Icons.phone_in_talk_outlined,
        color: theme.colorScheme.primary,
      );

    case SafetyIncidentStatus.emergencyServiceContacted:
      return _SafetyStatusPresentation(
        title: 'Emergency service contacted',
        icon: Icons.local_police_outlined,
        color: theme.colorScheme.error,
      );

    case SafetyIncidentStatus.responding:
      return _SafetyStatusPresentation(
        title: 'Response in progress',
        icon: Icons.emergency_share_outlined,
        color: theme.colorScheme.primary,
      );

    case SafetyIncidentStatus.userMarkedSafe:
      return _SafetyStatusPresentation(
        title: 'User marked safe',
        icon: Icons.check_circle_outline,
        color: theme.colorScheme.primary,
      );

    case SafetyIncidentStatus.underInvestigation:
      return _SafetyStatusPresentation(
        title: 'Under investigation',
        icon: Icons.manage_search_outlined,
        color: theme.colorScheme.tertiary,
      );

    case SafetyIncidentStatus.resolved:
      return _SafetyStatusPresentation(
        title: 'Incident resolved',
        icon: Icons.task_alt_outlined,
        color: theme.colorScheme.primary,
      );

    case SafetyIncidentStatus.falseAlarm:
      return _SafetyStatusPresentation(
        title: 'False alarm',
        icon: Icons.info_outline,
        color: theme.colorScheme.onSurfaceVariant,
      );

    case SafetyIncidentStatus.closed:
      return _SafetyStatusPresentation(
        title: 'Incident closed',
        icon: Icons.lock_outline,
        color: theme.colorScheme.onSurfaceVariant,
      );
  }
}

class _SafetyStatusPresentation {
  const _SafetyStatusPresentation({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}