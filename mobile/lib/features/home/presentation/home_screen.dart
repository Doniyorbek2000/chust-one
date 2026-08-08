import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/academy_logo.dart';
import '../../../core/widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _heroTitle = 'Bilim bilan\nkelajagingni\nyor!';
  String _heroSubtitle = 'Zamonaviy kasblarga ega bo\'ling va orzularingizni amalga oshiring.';
  String _heroBannerImage = 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80';
  String _heroCtaText = 'Kurslarni ko\'rish';

  // Dynamic Location Card CMS fields
  String _locationTitle = 'BIZNING YANGI MANZILIMIZ:';
  String _buildingImage = 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=600&q=80';
  String _addressLandmark = 'Book Kafee yonida,\nIlhom Travel binosida.';
  String _addressCity = 'Manzil: Chust shahrida:';
  String _mapImage = 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=600&q=80';
  String _mapLocationUrl = 'https://yandex.com/maps/?text=Chust+One+Academy';
  String _contactHeader = 'Ro\'yxatdan o\'tish uchun:';

  String _mainPhone = AppConstants.mainPhone;
  String _telegramUser = AppConstants.telegramGroup;
  String _telegramContact = AppConstants.telegramContact;
  String _instagramUser = AppConstants.instagramUser;

  bool _isMaintenance = false;

  final List<Map<String, dynamic>> _courseCategories = [
    {
      'id': 'comp',
      'title': 'Kompyuter\nsavodxonligi',
      'icon': Icons.laptop_chromebook,
      'color': const Color(0xFF3E8BFF),
    },
    {
      'id': 'mob',
      'title': 'Mobilografiya',
      'icon': Icons.smartphone,
      'color': const Color(0xFFFF9F43),
    },
    {
      'id': 'vid',
      'title': 'Videomontaj',
      'icon': Icons.movie_creation_outlined,
      'color': const Color(0xFFFF5252),
    },
    {
      'id': 'blog',
      'title': 'Blogerlik',
      'icon': Icons.mic_none,
      'color': const Color(0xFF00BEC4),
    },
    {
      'id': 'insta',
      'title': 'Instagramni\nto\'g\'ri yuritish',
      'icon': Icons.camera_alt_outlined,
      'color': const Color(0xFFE1306C),
    },
    {
      'id': 'smm',
      'title': 'SMM\nxizmatlari',
      'icon': Icons.people_outline,
      'color': const Color(0xFF10AC84),
    },
  ];

  final List<Map<String, dynamic>> _additionalCourses = [
    {'title': 'Mobilografiya', 'icon': Icons.camera_enhance_outlined, 'id': 'mob'},
    {'title': 'Videomontaj', 'icon': Icons.video_library_outlined, 'id': 'vid'},
    {'title': 'Blogerlik', 'icon': Icons.mic_external_on_outlined, 'id': 'blog'},
    {'title': 'Instagramni to\'g\'ri yuritish', 'icon': Icons.camera_alt_outlined, 'id': 'insta'},
    {'title': 'SMM xizmatlari', 'icon': Icons.groups_outlined, 'id': 'smm'},
    {'title': 'Professional target yoqish', 'icon': Icons.ads_click, 'id': 'target'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDynamicCmsData();
  }

  Future<void> _fetchDynamicCmsData() async {
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/settings');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted && data != null) {
          setState(() {
            _heroTitle = data['heroTitleUz'] ?? _heroTitle;
            _heroSubtitle = data['heroSubtitleUz'] ?? _heroSubtitle;
            _heroBannerImage = data['heroBannerImage'] ?? _heroBannerImage;
            _heroCtaText = data['heroCtaTextUz'] ?? _heroCtaText;

            _locationTitle = data['locationTitleUz'] ?? _locationTitle;
            _buildingImage = data['buildingImageUrl'] ?? _buildingImage;
            _addressLandmark = data['addressLandmarkUz'] ?? _addressLandmark;
            _addressCity = data['addressCityUz'] ?? _addressCity;
            _mapImage = data['mapImageUrl'] ?? _mapImage;
            _mapLocationUrl = data['mapLocationUrl'] ?? _mapLocationUrl;
            _contactHeader = data['contactHeaderUz'] ?? _contactHeader;

            _mainPhone = data['mainPhone'] ?? _mainPhone;
            _telegramUser = data['telegramUser'] ?? _telegramUser;
            _telegramContact = data['telegramContact'] ?? _telegramContact;
            _instagramUser = data['instagramUser'] ?? _instagramUser;
            _isMaintenance = data['isMaintenance'] ?? false;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isMaintenance) {
      return Scaffold(
        backgroundColor: AppColors.navy900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.build_circle_outlined, color: AppColors.primaryLime, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'Profilaktika Ishlari',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ilovamizda profilaktika va yangilanish ishlari olib borilmoqda. Tez orada qaytamiz!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy900 : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navy900 : AppColors.surfaceLight,
        elevation: 0,
        title: const AcademyLogo(size: 36, showText: true),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_none_outlined,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  size: 26,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLime,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DYNAMIC HERO BANNER fetched from API
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy800, AppColors.navy700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderDark, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _heroTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _heroSubtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          label: _heroCtaText,
                          suffixIcon: Icons.arrow_forward_ios_rounded,
                          width: 165,
                          height: 42,
                          borderRadius: 14,
                          onPressed: () => context.push('/courses'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _heroBannerImage,
                      width: 110,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 110,
                        height: 150,
                        color: AppColors.navy700,
                        child: const Icon(Icons.school, color: AppColors.primaryLime, size: 40),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. COURSE CATEGORIES GRID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bizning kurslar',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/courses'),
                  child: const Text(
                    'Barchasi',
                    style: TextStyle(
                      color: AppColors.primaryLime,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _courseCategories.length,
              itemBuilder: (context, index) {
                final cat = _courseCategories[index];
                return InkWell(
                  onTap: () => context.push('/course-detail/${cat['id']}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.navy800 : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (cat['color'] as Color).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: cat['color'] as Color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['title'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // Target banner card
            InkWell(
              onTap: () => context.push('/course-detail/target'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navy800 : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.ads_click, color: Color(0xFFFF5252), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Professional target yoqish',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryLime, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 3. "BUNDAN TASHQARI SIZ" LIST SECTION matching Screen 4 reference
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
                children: const [
                  TextSpan(text: 'BUNDAN TASHQARI SIZ '),
                  TextSpan(text: 'SIZ', style: TextStyle(color: AppColors.primaryLime)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'zamonaviy kasblarni o\'rganishingiz mumkin!',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),

            Column(
              children: _additionalCourses.map((item) {
                return InkWell(
                  onTap: () => context.push('/course-detail/${item['id']}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.navy800 : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData, color: AppColors.primaryLime, size: 22),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondaryDark, size: 16),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // 4. FULL DYNAMIC BRANCH LOCATION CARD fetched live from API
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.navy800 : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLime.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.primaryLime, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _locationTitle,
                          style: const TextStyle(
                            color: AppColors.primaryLime,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Dynamic Building photo banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      _buildingImage,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _addressLandmark,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _addressCity,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dynamic Map container
                  InkWell(
                    onTap: () => _openUrl(_mapLocationUrl),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        image: DecorationImage(
                          image: NetworkImage(_mapImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.navy900.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryLime, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map, color: AppColors.primaryLime, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Xaritada ko\'rish',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderDark, height: 1),
                  const SizedBox(height: 14),

                  // Contacts Header
                  Text(
                    _contactHeader,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildContactItem(
                    icon: Icons.phone,
                    text: _mainPhone,
                    onTap: () => _makeCall(_mainPhone),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildContactItem(
                    icon: Icons.send,
                    text: _telegramUser,
                    onTap: () => _openUrl('https://t.me/${_telegramUser.replaceAll('@', '')}'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildContactItem(
                    icon: Icons.person_outline,
                    text: _telegramContact,
                    onTap: () => _openUrl('https://t.me/${_telegramContact.replaceAll('@', '')}'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildContactItem(
                    icon: Icons.camera_alt_outlined,
                    text: _instagramUser,
                    onTap: () => _openUrl('https://instagram.com/${_instagramUser.replaceAll('@', '')}'),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryLime, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
