import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadNotifications());
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final passengerId = prefs.getString('passenger_id') ?? '';
      if (passengerId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final rawNotifications = await getIt<PassengerApiService>()
          .fetchNotifications(passengerId);
      final List<NotificationModel> list = [];

      for (final n in rawNotifications) {
        final map = n as Map<String, dynamic>;
        final type = map['type'] as String? ?? 'system';
        if (type != 'ride' && type != 'driver' && type != 'chat') {
          continue;
        }

        final id = map['id'] as String;
        final title = map['title'] as String;
        final message = map['message'] as String;
        final isRead = map['isRead'] as bool? ?? false;
        final dt =
            DateTime.tryParse(map['timestamp'] as String? ?? '') ??
            DateTime.now();

        list.add(
          NotificationModel(
            id: id,
            title: title,
            message: message,
            timestamp: dt,
            type: type,
            isRead: isRead,
          ),
        );
      }

      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
    }
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    });
  }

  void _dismissNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'ride':
        return LucideIcons.bike;
      case 'promo':
        return LucideIcons.tag;
      case 'system':
        return LucideIcons.shield_check;
      case 'driver':
        return LucideIcons.user;
      case 'chat':
        return LucideIcons.message_square;
      default:
        return LucideIcons.bell;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'ride':
        return AppTheme.primaryColor;
      case 'promo':
        return const Color(0xFF8B5E3C);
      case 'system':
        return AppTheme.tertiaryColor;
      case 'driver':
        return AppTheme.complete;
      case 'chat':
        return AppTheme.primaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 80,
        leading: GestureDetector(
          onTap: () => context.pop(),
          behavior: HitTestBehavior.opaque,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 12),
              Icon(
                LucideIcons.chevron_left,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                setState(() {
                  for (int index = 0; index < _notifications.length; index++) {
                    _notifications[index] = _notifications[index].copyWith(
                      isRead: true,
                    );
                  }
                });
              },
              child: Text(
                'Read all',
                style: TextStyle(
                  color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _dismissNotification(index),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cancel.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      LucideIcons.trash_2,
                      color: AppTheme.cancel,
                      size: 20,
                    ),
                  ),
                  child: _buildNotificationCard(notification, index),
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    return GestureDetector(
      onTap: () => _markAsRead(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppTheme.surface
              : AppTheme.secondaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead
                ? AppTheme.outlineBorderColor
                : AppTheme.secondaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _colorForType(notification.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconForType(notification.type),
                color: _colorForType(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.tertiaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _timeAgo(notification.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              LucideIcons.bell_off,
              size: 36,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll notify you about rides and account activity",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
