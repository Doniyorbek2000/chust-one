import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/academy_logo.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/storage/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  List<Map<String, dynamic>> _apiCourses = [];
  List<Map<String, dynamic>> _testimonials = [];

  final _storage = StorageService();

  // Curated accent palette the course grid cycles through so every course —
  // including ones an admin adds later, like "Sun'iy intellekt" — gets a
  // distinct color without needing a hardcoded per-title entry.
  static const List<Color> _paletteColors = [
    Color(0xFF3E8BFF),
    Color(0xFFFF9F43),
    Color(0xFFFF5252),
    Color(0xFF00BEC4),
    Color(0xFFE1306C),
    Color(0xFF10AC84),
    Color(0xFF9B59B6),
    Color(0xFFF39C12),
  ];

  Color _colorForIndex(int index) => _paletteColors[index % _paletteColors.length];

  // Best-effort mapping from the course/category's FontAwesome-style
  // iconName (set in the admin panel) or its title to a polished icon —
  // real brand glyphs (Instagram, Telegram, TikTok, YouTube) where the
  // topic is a specific platform, FontAwesome solid icons elsewhere, with
  // a sensible fallback so brand-new course topics still look intentional.
  FaIconData _iconForCourse(Map<String, dynamic> course) {
    final iconName = (course['category']?['iconName'] as String?) ?? '';
    final title = (course['titleUz'] as String?) ?? '';
    final key = '$iconName $title'.toLowerCase();

    if (key.contains('instagram')) return FontAwesomeIcons.instagram;
    if (key.contains('telegram')) return FontAwesomeIcons.telegram;
    if (key.contains('tiktok')) return FontAwesomeIcons.tiktok;
    if (key.contains('youtube')) return FontAwesomeIcons.youtube;
    if (key.contains('facebook')) return FontAwesomeIcons.facebook;
    if (key.contains('robot') || key.contains('sun\'iy') || key.contains('intellekt') || key.contains('artificial') || key.contains(' ai')) {
      return FontAwesomeIcons.robot;
    }
    if (key.contains('laptop') || key.contains('computer') || key.contains('kompyuter')) return FontAwesomeIcons.laptopCode;
    if (key.contains('mobile') || key.contains('phone') || key.contains('mobilografiya')) return FontAwesomeIcons.mobileScreenButton;
    if (key.contains('video') || key.contains('movie') || key.contains('film')) return FontAwesomeIcons.clapperboard;
    if (key.contains('mic') || key.contains('blog')) return FontAwesomeIcons.microphone;
    if (key.contains('camera') || key.contains('photo')) return FontAwesomeIcons.camera;
    if (key.contains('user') || key.contains('people') || key.contains('smm') || key.contains('group')) return FontAwesomeIcons.users;
    if (key.contains('ad') || key.contains('target') || key.contains('bullhorn') || key.contains('click')) return FontAwesomeIcons.bullseye;
    if (key.contains('code') || key.contains('dastur') || key.contains('program')) return FontAwesomeIcons.code;
    if (key.contains('design') || key.contains('paint') || key.contains('dizayn')) return FontAwesomeIcons.palette;
    if (key.contains('music') || key.contains('musiqa')) return FontAwesomeIcons.music;
    if (key.contains('language') || key.contains('til')) return FontAwesomeIcons.language;
    if (key.contains('game') || key.contains('geym')) return FontAwesomeIcons.gamepad;
    return FontAwesomeIcons.bookOpen;
  }

  // Accepts any YouTube link format (watch?v=, youtu.be/, shorts/, embed/)
  // and extracts the 11-char video id, so thumbnails/links work regardless
  // of which format the admin pasted when adding the testimonial.
  String? _youtubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    final patterns = [
      RegExp(r'[?&]v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCachedCmsData();
    _loadCachedCourses();
    _loadCachedTestimonials();
    _fetchDynamicCmsData();
    _fetchCourses();
    _fetchTestimonials();
  }

  void _applySettingsData(Map<String, dynamic> data) {
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
  }

  // Shows the last-known-good data instantly (works offline) while the live
  // fetch below refreshes it in the background.
  Future<void> _loadCachedCmsData() async {
    final cached = await _storage.getCache('app_settings');
    if (cached != null && mounted) {
      setState(() => _applySettingsData(cached as Map<String, dynamic>));
    }
  }

  Future<void> _loadCachedCourses() async {
    final cached = await _storage.getCache('courses_list');
    if (cached != null && mounted) {
      setState(() => _apiCourses = (cached as List<dynamic>).cast<Map<String, dynamic>>());
    }
  }

  Future<void> _loadCachedTestimonials() async {
    final cached = await _storage.getCache('testimonials_list');
    if (cached != null && mounted) {
      setState(() => _testimonials = (cached as List<dynamic>).cast<Map<String, dynamic>>());
    }
  }

  Future<void> _fetchCourses() async {
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/courses');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = (response.data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
        if (mounted) setState(() => _apiCourses = data);
        _storage.saveCache('courses_list', data);
      }
    } catch (_) {
      // Offline or request failed — the cached data loaded above (if any)
      // keeps showing; hero and location sections still work independently.
    }
  }

  Future<void> _fetchTestimonials() async {
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/content-blocks', queryParameters: {'section': 'TESTIMONIAL'});
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = (response.data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
        if (mounted) setState(() => _testimonials = data);
        _storage.saveCache('testimonials_list', data);
      }
    } catch (_) {
      // Offline or request failed — keep showing cached/empty state.
    }
  }

  Future<void> _fetchDynamicCmsData() async {
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/settings');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted && data != null) {
          setState(() => _applySettingsData(data as Map<String, dynamic>));
        }
        if (data != null) _storage.saveCache('app_settings', data);
      }
    } catch (_) {
      // Offline or request failed — keep showing cached/default content.
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

  // Plays a testimonial video inline (YouTube's iframe player embedded in a
  // WebView) instead of handing the user off to the YouTube app/browser.
  void _showVideoPlayer(String videoId, String title) {
    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(controller: controller),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => controller.close());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isMaintenance) {
      return const Scaffold(
        backgroundColor: AppColors.navy900,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_circle_outlined, color: AppColors.primaryLime, size: 72),
                SizedBox(height: 16),
                Text(
                  'Profilaktika Ishlari',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
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
                    color: Colors.black.withValues(alpha: 0.25),
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
                    child: CachedNetworkImage(
                      imageUrl: _heroBannerImage,
                      width: 110,
                      height: 150,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 110,
                        height: 150,
                        color: AppColors.navy700,
                      ),
                      errorWidget: (context, url, error) => Container(
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

            // 2. VIDEO TESTIMONIALS — admin-managed via the CMS "TESTIMONIAL"
            // content blocks (up to 20+ videos supported, same source that
            // powers the website's "Mijozlar fikri" section).
            if (_testimonials.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'O\'quvchilar fikri',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: _testimonials.length,
                itemBuilder: (context, index) {
                  final item = _testimonials[index];
                  final videoId = _youtubeId(item['mediaUrl'] as String?);
                  final thumbUrl = videoId != null ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg' : null;
                  final title = (item['titleUz'] as String?) ?? '';
                  return InkWell(
                    onTap: videoId == null ? null : () => _showVideoPlayer(videoId, title),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.navy800,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (thumbUrl != null)
                            CachedNetworkImage(
                              imageUrl: thumbUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: AppColors.navy700),
                              errorWidget: (context, url, error) => Container(color: AppColors.navy700),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.65)],
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 44),
                          ),
                          if (title.isNotEmpty)
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 10,
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // 3. COURSE CATEGORIES GRID — driven directly by the courses the
            // admin manages in the backend, so a newly added course (e.g.
            // "Sun'iy intellekt") appears here automatically with no app
            // update needed.
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
              itemCount: _apiCourses.length,
              itemBuilder: (context, index) {
                final course = _apiCourses[index];
                final color = _colorForIndex(index);
                return InkWell(
                  onTap: () => context.push('/course-detail/${course['id']}'),
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
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: course['coverImage'] as String? ?? '',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 44,
                                  height: 44,
                                  color: color.withValues(alpha: 0.12),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 44,
                                  height: 44,
                                  color: color.withValues(alpha: 0.12),
                                  child: FaIcon(_iconForCourse(course), color: color, size: 20),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? AppColors.navy800 : AppColors.surfaceLight, width: 2),
                                ),
                                child: FaIcon(_iconForCourse(course), color: Colors.white, size: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course['titleUz'] as String? ?? '',
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
                    color: Colors.black.withValues(alpha: 0.04),
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
                          color: AppColors.primaryLime.withValues(alpha: 0.2),
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
                    child: CachedNetworkImage(
                      imageUrl: _buildingImage,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 120,
                        width: double.infinity,
                        color: AppColors.navy700,
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        width: double.infinity,
                        color: AppColors.navy700,
                        child: const Icon(Icons.location_city, color: AppColors.primaryLime, size: 32),
                      ),
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
                          image: CachedNetworkImageProvider(_mapImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.navy900.withValues(alpha: 0.85),
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
