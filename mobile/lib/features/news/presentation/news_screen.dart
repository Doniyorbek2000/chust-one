import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<Map<String, dynamic>> _newsItems = [
    {
      'id': 'news-1',
      'date': '04 Avgust, 2026',
      'title': 'Chust One Academy yangi o\'quv binoga ko\'chdi!',
      'content': 'Bizning yangi manzilimiz: Book Kafee yonida, Ilhom Travel binosida. O\'quvchilarimiz uchun barcha zamonaviy sharoitlar va kompyuter xonalari hozirlandi.\n\nYangi binomizda 3 ta zamonaviy kompyuter laboratoriyasi, yuqori tezlikdagi Optik Internet hamda o\'quvchilarimiz uchun qahva va dam olish zonasi (Coffee & Chill Zone) tashkil etilgan.',
      'image': 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'news-2',
      'date': '01 Avgust, 2026',
      'title': '1–5 sinf o\'quvchilari uchun "Kompyuter Kids" guruhi Ochildi!',
      'content': 'Mantiqiy fikrlash, kompyuter ko\'nikmalari va amaliy mashg\'ulotlarni o\'z ichiga olgan 2 oylik maxsus tayyorlov kursi.\n\nDarslar interaktiv tarzda olib borilib, bolalarda algoritmik fikrlash va axborot texnologiyalariga bo\'lgan qiziqishni oshiradi.',
      'image': 'https://images.unsplash.com/photo-1577896851231-70ef18881754?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'news-3',
      'date': '28 Iyul, 2026',
      'title': 'Mobilografiya va Videomontaj kursiga yangi master-klasslar!',
      'content': 'Chust One Academy talabalari uchun CapCut va Premiere Pro dasturlarida professional montaj qilish hamda Reels va TikTok uchun yuqori sifatli video olish sirlari o\'rgatiladi.',
      'image': 'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?auto=format&fit=crop&w=600&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchNewsFromApi();
  }

  Future<void> _fetchNewsFromApi() async {
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/news');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        if (mounted && list.isNotEmpty) {
          setState(() {
            _newsItems = list.map((item) => {
              'id': item['id'],
              'title': item['titleUz'] ?? item['title'],
              'content': item['contentUz'] ?? item['content'],
              'date': '04 Avgust, 2026',
              'image': item['coverImage'],
            }).toList();
          });
        }
      }
    } catch (_) {}
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
                  child: Image.network(
                    news['image'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
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
      body: ListView.builder(
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
                  color: Colors.black.withOpacity(0.04),
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
                    child: Image.network(
                      news['image'] as String,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
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
