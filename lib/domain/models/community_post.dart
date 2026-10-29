class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.body,
    required this.likeCount,
    required this.liked,
  });

  final String id;
  final String authorName;
  final String body;
  final int likeCount;
  final bool liked;
}
