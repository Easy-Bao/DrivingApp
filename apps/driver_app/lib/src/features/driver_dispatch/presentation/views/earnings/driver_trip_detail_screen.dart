import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:driver_app/src/core/config/env_config.dart';
import 'package:driver_app/src/core/themes/app_themes.dart';
import 'package:driver_app/src/shared/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverTripDetailScreen extends StatefulWidget {
  final Map<String, dynamic> trip;
  const DriverTripDetailScreen({super.key, required this.trip});

  @override
  State<DriverTripDetailScreen> createState() => _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState extends State<DriverTripDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _passenger;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPassengerProfile();
  }

  Future<void> _loadPassengerProfile() async {
    final passengerId = widget.trip['passenger_id'] as String?;
    if (passengerId == null || passengerId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No passenger associated with this trip.';
      });
      return;
    }

    try {
      final url = '${EnvConfig.driverServiceUrl}/passengers/$passengerId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _passenger = jsonDecode(response.body) as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Passenger profile not found.';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load passenger profile.';
      });
    }
  }

  Future<void> _contactPassenger() async {
    final passengerId = widget.trip['passenger_id'] as String?;
    final tripId = widget.trip['id'] as String?;

    if (passengerId == null || tripId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driver_id') ?? '';
    if (driverId.isEmpty) return;

    try {
      final driverServiceUrl = EnvConfig.driverServiceUrl;
      final gatewayUrl = driverServiceUrl.replaceAll('8082', '8080');
      final chatRoomsEndpointUrl = '$gatewayUrl/chat/rooms';
      final initializeChatResponse = await http.post(
        Uri.parse(chatRoomsEndpointUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': tripId,
          'driverId': driverId,
          'passengerId': passengerId,
        }),
      );

      if (initializeChatResponse.statusCode == 201 || initializeChatResponse.statusCode == 200) {
        if (mounted) {
          // 2. Push to Driver Chat
          context.pushNamed(
            'DriverChat',
            extra: {
              'roomId': tripId,
              'userId': driverId,
              'peerName': _passenger?['name'] ?? 'Passenger',
            },
          );
        }
      } else {
        if (mounted) {
          CustomToast.show(
            context,
            'Failed to initialize chat channel.',
            isError: true,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        CustomToast.show(
          context,
          'Connection failed to start chat.',
          isError: true,
        );
      }
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Past Trip';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.trip['status'] as String? ?? 'completed';
    final isCompleted = status == 'completed';
    final statusColor = isCompleted ? AppTheme.complete : AppTheme.cancel;
    final statusLabel = isCompleted ? 'Completed' : 'Canceled';
    final fromName = widget.trip['pickup_name'] as String? ?? 'Pickup';
    final toName = widget.trip['dropoff_name'] as String? ?? 'Dropoff';
    final fareAmt = (widget.trip['fare'] as num?)?.toDouble() ?? 0.0;
    final rideType = widget.trip['ride_type'] as String? ?? 'Solo Ride';
    final dateStr = _formatDate(widget.trip['created_at'] as String? ?? '');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Trip Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Route Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.neutralColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderSide),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: AppTheme.borderSide,
                          ),
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.tertiaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fromName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              toName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: AppTheme.borderSide),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RIDE TYPE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rideType,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TOTAL FARE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${fareAmt.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Passenger Profile
            const Text(
              'PASSENGER PROFILE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.tertiaryColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),

            _buildPassengerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cancel.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cancel.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.cancel,
            ),
          ),
        ),
      );
    }

    final rating = _passenger?['rating'] ?? '4.8';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.neutralColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderSide),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _passenger?['name'] ?? 'Passenger',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _passenger?['phone'] ?? 'Unknown phone',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.complete.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '★ $rating',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.complete,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Lost & Found Contact button
        GestureDetector(
          onTap: _contactPassenger,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.message_square,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Contact Passenger (Lost & Found)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
