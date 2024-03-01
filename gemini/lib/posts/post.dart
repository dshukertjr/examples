class Post {
  final String id;
  final String content;
  final DateTime createdAt;
  final String embedding;
  final String openAIEmbedding;
  final double? similarity;
  final double? openAISimilarity;

  Post({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.embedding,
    required this.openAIEmbedding,
    required this.similarity,
    required this.openAISimilarity,
  });

  factory Post.fromJson(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      embedding: map['embedding'] as String,
      openAIEmbedding: map['open_ai_embedding'] as String,
      similarity: map['similarity'] as double?,
      openAISimilarity: map['open_ai_similarity'] as double?,
    );
  }
}
