import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/academy_logo.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/storage/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _title = 'Kelajagingizni\nbiz bilan yarating!';
  String _subtitle = 'Zamonaviy kasblarni o\'rganing, ko\'nikmalaringizni rivojlantiring va muvaffaqiyat sari qadam qo\'ying.';
  String _imageUrl = 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80';
  String _ctaText = 'Boshlash';
  String _secondaryText = 'Kirish';

  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _fetchDynamicOnboardingData();
  }

  void _applyData(Map<String, dynamic> data) {
    _title = data['onboardingTitleUz'] ?? _title;
    _subtitle = data['onboardingSubtitleUz'] ?? _subtitle;
    _imageUrl = data['onboardingImageUrl'] ?? _imageUrl;
    _ctaText = data['onboardingCtaTextUz'] ?? _ctaText;
    _secondaryText = data['onboardingSecondaryUz'] ?? _secondaryText;
  }

  Future<void> _loadCachedData() async {
    final cached = await _storage.getCache('app_settings');
    if (cached != null && mounted) {
      setState(() => _applyData(cached as Map<String, dynamic>));
    }
  }

  Future<void> _fetchDynamicOnboardingData() async {
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.apiBaseUrl}/settings');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted && data != null) {
          setState(() => _applyData(data as Map<String, dynamic>));
        }
        if (data != null) _storage.saveCache('app_settings', data);
      }
    } catch (_) {
      // Offline or request failed — keep showing cached/default content.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy900 : AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Hexagon Logo
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: AcademyLogo(size: 64, showText: true),
                        ),

                        const SizedBox(height: 16),

                        // Center Hero Image matching Screen 1 reference
                        Container(
                          width: double.infinity,
                          height: constraints.maxHeight * 0.42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: CachedNetworkImage(
                              imageUrl: _imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.navy800,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.navy800,
                                child: const Icon(Icons.school, color: AppColors.primaryLime, size: 60),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Headline & Subtitle
                        Column(
                          children: [
                            Text(
                              _title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                _subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons: Lime Pill "Boshlash >" and Outline "Kirish"
                        Column(
                          children: [
                            CustomButton(
                              label: _ctaText,
                              suffixIcon: Icons.arrow_forward_ios_rounded,
                              onPressed: () => context.go('/home'),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  side: BorderSide(
                                    color: isDark ? AppColors.primaryLime.withValues(alpha: 0.6) : AppColors.navy900,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: () => context.push('/auth/login'),
                                child: Text(
                                  _secondaryText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
