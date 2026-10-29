class ChatProposal {
  const ChatProposal({
    required this.id,
    required this.title,
    required this.detail,
    required this.status,
  });

  final String id;
  final String title;
  final String detail;
  final String status;
}

class ChatTurn {
  const ChatTurn({
    required this.id,
    required this.role,
    required this.body,
    this.provider,
    this.proposals = const [],
  });

  final String id;
  final String role;
  final String body;
  final String? provider;
  final List<ChatProposal> proposals;
}
