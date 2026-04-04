import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:curren_see/Module/NewsArticleModel.dart';
import 'package:curren_see/Constants/Constants.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsArticleModel article;

  const NewsDetailScreen({super.key, required this.article});

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openInBrowser(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Could not open link',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    final double w = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [

          //SLIVER APP BAR WITH IMAGE
          SliverAppBar(
            expandedHeight: h * 0.35,
            pinned: true,
            backgroundColor: gold,

            //UPDATED: Gold themed back arrow only
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: gold.withAlpha(200),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(80),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  //Hero Image
                  _buildImage(article.imageUrl, isDark),

                  //Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withAlpha(180),
                        ],
                      ),
                    ),
                  ),

                  //Source name at bottom of image
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [goldLight, goldDark]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            article.sourceName ?? 'News',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded,
                                  color: Colors.white70, size: 12),
                              SizedBox(width: 4),
                              Text(
                                _timeAgo(article.publishedAt),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          //NEWS CONTENT
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(w * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Category chips
                  if (article.category != null &&
                      article.category!.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: article.category!
                          .where((c) => c != null && c.isNotEmpty)
                          .map((cat) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? gold.withAlpha(38)
                              : Color(0xFFF0E8C8),
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? goldBorder30
                                : gold.withAlpha(80),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          cat!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? gold : goldDark,
                          ),
                        ),
                      ))
                          .toList(),
                    ),

                  if (article.category != null &&
                      article.category!.isNotEmpty)
                    SizedBox(height: h * 0.02),

                  //Title
                  Text(
                    article.title ?? 'No Title',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color:
                      isDark ? darkTextPrimary : Colors.black87,
                      height: 1.35,
                      letterSpacing: -0.3,
                    ),
                  ),

                  SizedBox(height: h * 0.012),

                  //Source & Date Row
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: w * 0.03, vertical: h * 0.01),
                    decoration: BoxDecoration(
                      color: isDark ? darkBg : lightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.newspaper_rounded,
                            color: gold, size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            article.sourceName ?? 'Unknown Source',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? gold : goldDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.access_time_rounded,
                            color:
                            isDark ? darkTextGrey : Colors.grey,
                            size: 14),
                        SizedBox(width: 4),
                        Text(
                          _timeAgo(article.publishedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? darkTextGrey
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.025),

                  //Divider
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: gold,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Full Story',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? gold : goldDark,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: h * 0.018),

                  //Description
                  if (article.description != null &&
                      article.description!.isNotEmpty)
                    Text(
                      article.description!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? darkTextPrimary
                            : Colors.black87,
                        height: 1.6,
                      ),
                    ),

                  if (article.description != null &&
                      article.description!.isNotEmpty)
                    SizedBox(height: h * 0.02),

                  //Full Content
                  if (article.content != null &&
                      article.content!.isNotEmpty)
                    Text(
                      article.content!,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? darkTextGrey
                            : Colors.grey.shade700,
                        height: 1.7,
                        letterSpacing: 0.1,
                      ),
                    ),

                  //If no content available
                  if ((article.content == null ||
                      article.content!.isEmpty) &&
                      (article.description == null ||
                          article.description!.isEmpty))
                    Center(
                      child: Column(
                        children: [
                          SizedBox(height: h * 0.05),
                          Icon(Icons.article_outlined,
                              color: isDark
                                  ? darkTextGrey
                                  : Colors.grey.shade300,
                              size: 50),
                          SizedBox(height: 12),
                          Text(
                            'Full content not available',
                            style: TextStyle(
                              color: isDark
                                  ? darkTextGrey
                                  : Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: h * 0.035),

                  //Read Full Article Button
                  if (article.sourceUrl != null &&
                      article.sourceUrl!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _openInBrowser(article.sourceUrl, context),
                        icon: Icon(Icons.open_in_new,
                            color: Colors.white, size: 18),
                        label: Text(
                          'Read Full Article',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: h * 0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                  SizedBox(height: h * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? url, bool isDark) {
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return Container(
        color: isDark ? darkCard : Color(0xFFFFF8E1),
        child: Center(
          child: Icon(Icons.article_rounded,
              color: goldLight, size: 50),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      headers: {
        'User-Agent': 'Mozilla/5.0',
        'Referer': 'https://newsdata.io/'
      },
      errorBuilder: (_, __, ___) {
        final proxied =
            'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}&w=600&output=jpg';
        return Image.network(
          proxied,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: isDark ? darkCard : Color(0xFFFFF8E1),
            child: Center(
              child: Icon(Icons.article_rounded,
                  color: goldLight, size: 50),
            ),
          ),
        );
      },
    );
  }
}