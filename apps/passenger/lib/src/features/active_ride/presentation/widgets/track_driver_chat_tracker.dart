import 'dart:async';

import 'package:chat/chat.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/session/session_store.dart';

class TrackDriverChatTracker {
  TrackDriverChatTracker({
    required this.rideId,
    required this.chatRepositoryFactory,
    required this.sessionService,
    required this.lifecycleCoordinator,
  }) {
    _pollingTask = AppLifecyclePeriodicTask(
      lifecycleCoordinator: lifecycleCoordinator,
      interval: const Duration(seconds: 4),
      onTick: refreshUnreadCount,
      runImmediately: true,
    );
  }

  final String rideId;
  final ChatRepositoryFactory chatRepositoryFactory;
  final SessionStore sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;

  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  late final AppLifecyclePeriodicTask _pollingTask;
  ChatRepository? _chatRepository;
  DateTime? _chatReadAt;
  String _passengerIdentifier = '';
  bool _isPollingChat = false;
  bool _isDisposed = false;

  void start() {
    unawaited(_initialize());
    _pollingTask.start();
  }

  Future<void> _initialize() async {
    final passengerIdentifier = await sessionService.readPassengerId() ?? '';
    if (_isDisposed || passengerIdentifier.isEmpty) return;
    _passengerIdentifier = passengerIdentifier;
    final readAt = await sessionService.readChatReadAt(rideId);
    if (_isDisposed) return;
    _chatReadAt = readAt;
    _chatRepository = chatRepositoryFactory.create(
      currentUserId: passengerIdentifier,
    );
    unawaited(refreshUnreadCount());
  }

  Future<void> markMessagesRead() async {
    final chatRepository = _chatRepository;
    if (_isDisposed || chatRepository == null) return;

    var readAt = DateTime.now().toUtc();
    final result = await chatRepository.fetchRoomMessages(rideId);
    if (result case Ok(value: final messages)) {
      for (final message in messages) {
        if (message.senderId == _passengerIdentifier) continue;
        final createdAt = message.createdAt.toUtc();
        if (createdAt.isAfter(readAt)) readAt = createdAt;
      }
    }
    if (_isDisposed) return;
    _chatReadAt = readAt;
    await sessionService.saveChatReadAt(rideId, readAt);
    if (_isDisposed) return;
    unreadCount.value = 0;
  }

  Future<void> refreshUnreadCount() async {
    if (_isDisposed || _isPollingChat) return;
    _isPollingChat = true;
    try {
      final chatRepository = _chatRepository;
      final passengerIdentifier = _passengerIdentifier;
      if (chatRepository == null || passengerIdentifier.isEmpty) return;

      final result = await chatRepository.fetchRoomMessages(rideId);
      if (_isDisposed) return;

      if (result case Ok(value: final messages)) {
        final readAt = _chatReadAt;
        var nextUnread = 0;
        for (final message in messages) {
          if (message.senderId == passengerIdentifier) continue;
          if (readAt == null || message.createdAt.toUtc().isAfter(readAt)) {
            nextUnread++;
          }
        }
        if (unreadCount.value != nextUnread) {
          unreadCount.value = nextUnread;
        }
      }
    } catch (_) {
      // A later bounded refresh can recover from a transient chat failure.
    } finally {
      _isPollingChat = false;
    }
  }

  void dispose() {
    _isDisposed = true;
    unawaited(_pollingTask.dispose());
    unawaited(_chatRepository?.dispose());
    unreadCount.dispose();
  }
}
