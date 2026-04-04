class NewsArticleModel {
  final String? title;
  final String? description;
  final String? content;
  final String? imageUrl;
  final String? sourceName;
  final String? sourceUrl;
  final String? publishedAt;
  final List<String?>? category;

  NewsArticleModel({
    this.title,
    this.description,
    this.content,
    this.imageUrl,
    this.sourceName,
    this.sourceUrl,
    this.publishedAt,
    this.category,
  });

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    return NewsArticleModel(
      title: json['title'],
      description: json['description'],
      content: json['content'],
      imageUrl: json['image_url'],
      sourceName: json['source_name'] ?? json['source_id'],
      sourceUrl: json['link'],
      publishedAt: json['pubDate'],
      category: (json['category'] as List?)
          ?.map((e) => e?.toString())
          .toList(),
    );
  }
}