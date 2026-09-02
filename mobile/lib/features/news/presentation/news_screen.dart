import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/storage_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> _newsItems = [];
  bool _isLoading = true;
  bool _hasError = false;

  static const _months = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
    'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
  ];

  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadCachedNews();
    _fetchNewsFromApi();
  }

  String _formatDate(String? isoDate) {
    final date = isoDate == null ? null : DateTime.tryParse(isoDate);
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]}, ${date.year}';
  }

  // Shows the last-fetched news list immediately (works offline) while the
  // live fetch below refreshes it in the background.
  Future<void> _loadCachedNews() async {
    final cached = await _storage.getCache('news_list');
    if (cached != null && mounted) {
      setState(() {
        _newsItems = (cached as List<dynamic>).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNewsFromApi() async {
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/news');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final mapped = list.map<Map<String, dynamic>>((item) => {
          'id': item['id'],
          'title': item['titleUz'],
          'content': item['contentUz'],
          'date': _formatDate(item['createdAt'] as String?),
          'image': item['coverImage'],
        }).toList();
        if (mounted) {
          setState(() {
            _newsItems = mapped;
            _isLoading = false;
            _hasError = false;
          });
        }
        _storage.saveCache('news_list', mapped);
      } else if (_newsItems.isEmpty) {
        if (mounted) setState(() { _isLoading = false; _hasError = true; });
      }
    } catch (_) {
      // Offline or request failed — keep showing the cached list (if any)
      // loaded above instead of an error state.
      if (mounted && _newsItems.isEmpty) {
        setState(() { _isLoading = false; _hasError = true; });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewsDetailModal(Map<String, dynamic> news) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.navy900 : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.navy700 : AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: news['image'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: double.infinity,
                      height: 200,
                      color: AppColors.navy700,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      height: 200,
                      color: AppColors.navy700,
                      child: const Icon(Icons.article, color: AppColors.primaryLime, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.primaryLime, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      news['date'],
                      style: const TextStyle(color: AppColors.primaryLime, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  news['title'],
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  news['content'],
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLime,
                      foregroundColor: AppColors.navy900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Yopish', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy900 : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Akademiya yangiliklari'),
        backgroundColor: isDark ? AppColors.navy900 : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLime))
          : _hasError
              ? Center(
                  child: Text(
                    'Yangiliklarni yuklab bo\'lmadi. Internetni tekshirib, qayta urinib ko\'ring.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                )
              : _newsItems.isEmpty
                  ? Center(
                      child: Text(
                        'Hozircha yangiliklar yo\'q',
                        style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    )
                  : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _newsItems.length,
        itemBuilder: (context, index) {
          final news = _newsItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.navy800 : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _showNewsDetailModal(news),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: CachedNetworkImage(
                      imageUrl: news['image'] as String,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: 180,
                        color: AppColors.navy700,
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: double.infinity,
                        height: 180,
                        color: AppColors.navy700,
                        child: const Icon(Icons.article, color: AppColors.primaryLime, size: 40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppColors.primaryLime, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              news['date'] as String,
                              style: const TextStyle(
                                color: AppColors.primaryLime,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          news['title'] as String,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          news['content'] as String,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
