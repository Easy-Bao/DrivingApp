final class DashboardOfferStore {
  DashboardOfferStore({required this._now});

  static const int _maxTerminalRideIds = 100;

  final DateTime Function() _now;
  final Map<String, DateTime> _resolvedOfferSessions = <String, DateTime>{};
  final Set<String> _terminalRideIds = <String>{};

  bool isTerminalRide(String rideId) => _terminalRideIds.contains(rideId);

  bool recordTerminalRideId(String rideId) {
    final added = _terminalRideIds.add(rideId);
    while (_terminalRideIds.length > _maxTerminalRideIds) {
      _terminalRideIds.remove(_terminalRideIds.first);
    }
    return added;
  }

  void clearResolvedOffers() => _resolvedOfferSessions.clear();

  bool isResolvedOfferSession(String sessionId) {
    final expiresAt = _resolvedOfferSessions[sessionId];
    if (expiresAt == null) return false;
    if (expiresAt.isAfter(_now())) return true;
    _resolvedOfferSessions.remove(sessionId);
    return false;
  }

  void recordResolvedOfferSession(
    String sessionId, {
    required Iterable<Map<String, dynamic>> candidates,
  }) {
    Map<String, dynamic>? matchingBid;
    for (final bid in candidates) {
      if (normalizedString(bid['id']) == sessionId) {
        matchingBid = bid;
        break;
      }
    }
    final expiresAt = DateTime.tryParse(
      normalizedString(matchingBid?['expires_at']) ?? '',
    );
    final retentionUntil = expiresAt != null && expiresAt.isAfter(_now())
        ? expiresAt
        : _now().add(const Duration(minutes: 2));
    _resolvedOfferSessions[sessionId] = retentionUntil;
  }

  ({
    List<Map<String, dynamic>> activeBids,
    List<Map<String, dynamic>> submittedOffers,
    bool changed,
    bool submittedOfferExpired,
  })
  pruneExpiredOffers({
    required List<Map<String, dynamic>> activeBids,
    required List<Map<String, dynamic>> submittedOffers,
  }) {
    final now = _now();
    final remaining = activeBids
        .where((bid) {
          final expiresAt = DateTime.tryParse(
            normalizedString(bid['expires_at']) ?? '',
          );
          return expiresAt == null || expiresAt.isAfter(now);
        })
        .toList(growable: false);
    final remainingSubmitted = submittedOffers
        .where((offer) {
          final expiresAt = DateTime.tryParse(
            normalizedString(offer['expires_at']) ?? '',
          );
          return expiresAt == null || expiresAt.isAfter(now);
        })
        .toList(growable: false);
    _resolvedOfferSessions.removeWhere(
      (_, expiresAt) => !expiresAt.isAfter(now),
    );
    final changed =
        remaining.length != activeBids.length ||
        remainingSubmitted.length != submittedOffers.length;
    return (
      activeBids: remaining,
      submittedOffers: remainingSubmitted,
      changed: changed,
      submittedOfferExpired: remainingSubmitted.length < submittedOffers.length,
    );
  }

  ({
    List<Map<String, dynamic>> activeBids,
    List<Map<String, dynamic>> submittedOffers,
  })
  partitionSnapshotOffers({
    required List<Map<String, dynamic>> snapshotOffers,
    required List<Map<String, dynamic>> currentSubmittedOffers,
    required bool preserveLocalSubmissions,
  }) {
    final offeredSessions = <Map<String, dynamic>>[];
    final submittedOffers = <Map<String, dynamic>>[];
    for (final bid in snapshotOffers) {
      final sessionId = normalizedString(bid['id']);
      if (sessionId != null && isResolvedOfferSession(sessionId)) {
        continue;
      }
      if (hasSubmittedOffer(bid)) {
        submittedOffers.add(bid);
      } else {
        offeredSessions.add(bid);
      }
    }

    if (preserveLocalSubmissions) {
      final submittedSessionIds = submittedOffers
          .map((offer) => normalizedString(offer['id']))
          .whereType<String>()
          .toSet();
      for (final offer in currentSubmittedOffers) {
        final sessionId = normalizedString(offer['id']);
        if (offer['local_offer_submitted'] == true &&
            sessionId != null &&
            !submittedSessionIds.contains(sessionId) &&
            !isResolvedOfferSession(sessionId)) {
          submittedOffers.add(offer);
        }
      }
      final preservedSessionIds = submittedOffers
          .where((offer) => offer['local_offer_submitted'] == true)
          .map((offer) => normalizedString(offer['id']))
          .whereType<String>()
          .toSet();
      offeredSessions.removeWhere(
        (bid) => preservedSessionIds.contains(normalizedString(bid['id'])),
      );
    }

    return (
      activeBids: immutableMaps(offeredSessions),
      submittedOffers: immutableMaps(submittedOffers),
    );
  }

  static bool hasSubmittedOffer(Map<String, dynamic> bid) {
    if (bid['local_offer_submitted'] == true) return true;
    final offers = bid['offers'];
    if (offers is! List) return false;
    return offers.any(
      (offer) =>
          offer is Map &&
          normalizedString(offer['status'])?.toLowerCase() == 'pending',
    );
  }

  static List<Map<String, dynamic>> immutableMaps(
    Iterable<Map<String, dynamic>> values,
  ) {
    return List<Map<String, dynamic>>.unmodifiable(
      values.map(Map<String, dynamic>.from),
    );
  }

  static String? normalizedString(Object? value) {
    final normalized = value?.toString().trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
