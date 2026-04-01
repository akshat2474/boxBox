class NewsArticle {
  final String title;
  final String description;
  final String link;
  final DateTime pubDate;
  final String? imageUrl;

  NewsArticle({
    required this.title,
    required this.description,
    required this.link,
    required this.pubDate,
    this.imageUrl,
  });
}
