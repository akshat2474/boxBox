import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news_article.dart';

class NewsService {
  static const String rssFeedUrl = 'https://racer.com/category/formula-1/feed/';

  Future<List<NewsArticle>> getLatestNews() async {
    final response = await http.get(Uri.parse(rssFeedUrl));
    
    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');
      
      final articles = items.map((node) {
        final title = node.findElements('title').single.innerText;
        final description = node.findElements('description').single.innerText;
        final link = node.findElements('link').single.innerText;
        
        final pubDateStr = node.findElements('pubDate').single.innerText;
        DateTime pubDate = DateTime.now();
        try {
          pubDate = HttpDate.parse(pubDateStr);
        } catch (_) {
          // If formatting is anomalous.
        }

        String? imageUrl;
        final mediaElements = node.findElements('media:thumbnail');
        if (mediaElements.isNotEmpty) {
          imageUrl = mediaElements.first.getAttribute('url');
        }

        return NewsArticle(
          title: title,
          description: description,
          link: link,
          pubDate: pubDate,
          imageUrl: imageUrl,
        );
      }).toList();

      // Sort by recency (newest first = most important typically in F1 feeds)
      articles.sort((a, b) => b.pubDate.compareTo(a.pubDate));
      return articles;
    } else {
      throw Exception('Failed to load news');
    }
  }
}

final newsServiceProvider = Provider((ref) => NewsService());

final latestNewsProvider = FutureProvider<List<NewsArticle>>((ref) async {
  final service = ref.watch(newsServiceProvider);
  return await service.getLatestNews();
});
