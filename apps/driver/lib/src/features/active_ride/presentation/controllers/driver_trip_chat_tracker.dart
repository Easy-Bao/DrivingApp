import 'dart:async';

import 'package:chat/chat.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';

final class DriverTripChatTracker {
  DriverTripChatTracker({
    required this._chatRepositoryFactory,
    required this._sessionService,
    required this._lifecycleCoordinator,
  });

  final ChatRepositoryFactory _chatRepositoryFactory;
  final SessionStore _sessionService;
  final AppLifecycleCoordinator _lifecycleCoordinator;

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  ChatRepository? _chatRepository;
  String? _driverId;
  int _viewedPassengerMessagesCount = 0;
  bool _isInitialCountFetched = false;
  bool _disposed = false;

  Future<String> resolveDriverId() async {
    final cached = _driverId;
    if (cached != null && cached.isNotEmpty) return cached;
    final driverId = await _sessionService.readDriverId() ?? '';
    if (driverId.isNotEmpty) {
      _driverId = driverId;
    }
    return driverId;
  }

  Future<void> initialize() async {
    final driverId = await resolveDriverId();
    if (_disposed || driverId.isEmpty) return;
    _chatRepository ??= _chatRepositoryFactory.create(currentUserId: driverId);
  }

  void markCurrentUnreadViewed() {
    _viewedPassengerMessagesCount += unreadCount.value;
    _isInitialCountFetched = true;
    unreadCount.value = 0;
  }

  Future<void> refreshUnreadCount(
    String? rideId, {
    bool markAllViewed = false,
  }) async {
    if (_disposed || !_lifecycleCoordinator.isForeground) return;
    try {
      if (rideId == null || rideId.isEmpty) return;
      final driverIdentifier = await resolveDriverId();
      if (_disposed || driverIdentifier.isEmpty) return;
      final chatRepository = _chatRepository;
      if (chatRepository == null) return;

      final result = await chatRepository.fetchRoomMessages(rideId);
      if (_disposed) return;
      if (result case Ok(value: final messages)) {
        var passengerMessages = 0;
        for (final message in messages) {
          if (message.senderId != driverIdentifier) {
            passengerMessages++;
          }
        }
        if (markAllViewed) {
          _viewedPassengerMessagesCount = passengerMessages;
          _isInitialCountFetched = true;
          unreadCount.value = 0;
          return;
        }
        if (!_isInitialCountFetched) {
          _viewedPassengerMessagesCount = 0;
          _isInitialCountFetched = true;
        }
        final nextUnread = (passengerMessages - _viewedPassengerMessagesCount)
            .clamp(0, passengerMessages)
            .toInt();
        if (nextUnread != unreadCount.value) {
          unreadCount.value = nextUnread;
        }
      }
    } catch (_) {
      // Transient chat fetch errors recover on the next bounded refresh tick.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    unreadCount.dispose();
    await _chatRepository?.dispose();
    _chatRepository = null;
  }
}
