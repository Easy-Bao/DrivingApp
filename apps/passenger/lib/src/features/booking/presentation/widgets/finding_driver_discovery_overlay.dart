import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/domain/entities/driver.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/widgets/driver_dropdown_card.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

class FindingDriverDiscoveryOverlay extends StatelessWidget {
  const FindingDriverDiscoveryOverlay({
    super.key,
    required this.isWideScreen,
    required this.buildWhen,
    required this.nearbyDrivers,
    required this.selectedDriver,
    required this.isViewingDriverProfile,
    required this.profileRepository,
    required this.onBackPressed,
    required this.onSelectNearbyChip,
    required this.onViewFullProfile,
    required this.onHideDriverProfile,
    required this.onStartDirectBooking,
    required this.onCloseDropdown,
  });

  final bool isWideScreen;
  final BlocBuilderCondition<BookingState> buildWhen;
  final List<Driver> nearbyDrivers;
  final Driver? selectedDriver;
  final bool isViewingDriverProfile;
  final DriverProfileRepository profileRepository;
  final VoidCallback onBackPressed;
  final ValueChanged<Driver> onSelectNearbyChip;
  final ValueChanged<Driver> onViewFullProfile;
  final VoidCallback onHideDriverProfile;
  final ValueChanged<Driver> onStartDirectBooking;
  final VoidCallback onCloseDropdown;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 600.0 : double.infinity,
          ),
          child: BlocBuilder<BookingBloc, BookingState>(
            buildWhen: buildWhen,
            builder: (context, state) {
              final showDriverDiscovery = state is NearestDriverFound;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: AppMapBackButton(onPressed: onBackPressed),
                  ),
                  if (showDriverDiscovery && nearbyDrivers.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          for (final driver in nearbyDrivers)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _NearbyDriverSelectionChip(
                                driver: driver,
                                isSelected: selectedDriver?.id == driver.id,
                                onTap: () => onSelectNearbyChip(driver),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (showDriverDiscovery)
                    if (selectedDriver case final driver?)
                      DriverDropdownCard(
                        driver: driver,
                        isNearestDriver:
                            nearbyDrivers.isNotEmpty &&
                            driver.id == nearbyDrivers.first.id,
                        isProfileVisible: isViewingDriverProfile,
                        onViewFullProfilePressed: () =>
                            onViewFullProfile(driver),
                        onProfileBackPressed: onHideDriverProfile,
                        onSelectDriverPressed: () =>
                            onStartDirectBooking(driver),
                        onCloseDropdownPressed: onCloseDropdown,
                        profileRepository: profileRepository,
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class const _NearbyDriverSelectionChip({
  required this.driver,
  required this.isSelected,
  required this.onTap,
}) extends StatelessWidget {
  final Driver driver;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _vehicleIcon {
    final vehicleType = driver.vehicleType.toLowerCase();
    if (vehicleType.contains('suv') || vehicleType.contains('sedan')) {
      return LucideIcons.car_front;
    }
    return LucideIcons.car;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(AppRadius.pill);
    final foregroundColor = isSelected ? scheme.onPrimary : scheme.onSurface;
    final distance = DistanceFormatter.fromKilometers(driver.distanceKm);

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${driver.displayName}, ${driver.vehicleType}, rating ${driver.rating.toStringAsFixed(1)}, $distance away',
      child: Material(
        color: isSelected ? scheme.primary : scheme.surfaceContainerLowest,
        elevation: isSelected ? 1 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? (isSelected ? scheme.onPrimary : scheme.primary).withValues(
                    alpha: isSelected ? 0.16 : 0.12,
                  )
                : Colors.transparent,
          ),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSize.minimumTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
              ),
              borderRadius: radius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_vehicleIcon, size: 17, color: foregroundColor),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: isSelected
                              ? scheme.onPrimary
                              : context.semanticColors.rating,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          driver.rating.toStringAsFixed(1),
                          style: context.textStyles.labelSmall?.tabular
                              .copyWith(
                                color: foregroundColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          distance,
                          style: context.textStyles.labelSmall?.tabular
                              .copyWith(
                                color: foregroundColor.withValues(alpha: 0.78),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
