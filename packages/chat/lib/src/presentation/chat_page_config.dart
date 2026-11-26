/// App-specific copy and quick replies supplied when mounting [ChatPage].
class const ChatPageConfig({
  required this.defaultPeerName,
  required this.callTooltip,
  required this.quickReplies,
}) {
  final String defaultPeerName;
  final String callTooltip;
  final List<String> quickReplies;

  static const driver = ChatPageConfig(
    defaultPeerName: 'Passenger',
    callTooltip: 'Call passenger',
    quickReplies: ['I have arrived', 'In traffic', 'At pickup point'],
  );

  static const passenger = ChatPageConfig(
    defaultPeerName: 'Driver',
    callTooltip: 'Call driver',
    quickReplies: [
      'Where are you?',
      "I'm at the pickup location",
      'Wait please',
      'Coming out now',
      'Thank you!',
    ],
  );
}
