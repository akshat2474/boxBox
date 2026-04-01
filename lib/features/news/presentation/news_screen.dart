import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/liquid_glass_theme.dart';
import '../../../services/news_service.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(latestNewsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('News', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: () => ref.refresh(latestNewsProvider),
          ),
        ],
      ),
      body: newsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.f1Red)),
        error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
        data: (articles) {
          if (articles.isEmpty) {
            return const Center(child: Text('No news available', style: TextStyle(color: AppTheme.textSecondary)));
          }

          final featured = articles.first;
          final rest = articles.skip(1).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // Featured hero article
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(featured.link);
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                },
                child: Stack(
                  children: [
                    if (featured.imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: featured.imageUrl!,
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Container(height: 260, color: AppTheme.surface),
                      )
                    else
                      Container(height: 260, color: AppTheme.surface),
                    // Gradient overlay
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppTheme.bg.withOpacity(0.95)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppTheme.f1Red, borderRadius: BorderRadius.circular(4)),
                              child: const Text('LATEST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                            ),
                            const SizedBox(height: 8),
                            Text(featured.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(DateFormat('MMM d, yyyy · HH:mm').format(featured.pubDate.toLocal()), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text('More News', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ),

              // Rest as cards
              ...rest.map((article) {
                final cleanDesc = article.description.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
                return GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(article.link);
                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail
                        if (article.imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: article.imageUrl!,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(width: 110, height: 110, color: AppTheme.surfaceElevated),
                            ),
                          )
                        else
                          Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                            ),
                            child: const Icon(Icons.article, color: AppTheme.textMuted, size: 32),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3)),
                                const SizedBox(height: 6),
                                Text(cleanDesc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                                const SizedBox(height: 8),
                                Text(DateFormat('MMM d · HH:mm').format(article.pubDate.toLocal()), style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
