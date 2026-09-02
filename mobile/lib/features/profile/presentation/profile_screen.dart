import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart' as dio;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingAvatar = false;

  List<Map<String, dynamic>> _myEnrollments = [];
  bool _isLoadingEnrollments = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMyEnrollments());
  }

  Future<void> _fetchMyEnrollments() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      setState(() => _isLoadingEnrollments = false);
      return;
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/my/enrollments');
      if (mounted) {
        setState(() {
          _myEnrollments = (response.data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
          _isLoadingEnrollments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingEnrollments = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(picked.path),
      });
      final uploadRes = await apiClient.dio.post('/upload', data: formData);
      final avatarUrl = uploadRes.data['data']['url'] as String;

      final profileRes = await apiClient.patch('/auth/profile', data: {'avatarUrl': avatarUrl});
      await ref.read(authProvider.notifier).updateUser(profileRes.data['data'] as Map<String, dynamic>);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rasm yuklashda xatolik yuz berdi')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showEditProfileModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.read(authProvider);
    final user = auth.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final cityController = TextEditingController(text: user.city ?? '');
    final ageController = TextEditingController(text: user.age?.toString() ?? '');
    final addressController = TextEditingController(text: user.address ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.navy900 : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.navy700 : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Profilni tahrirlash',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: GestureDetector(
                        onTap: _isUploadingAvatar
                            ? null
                            : () async {
                                await _pickAndUploadAvatar();
                                setModalState(() {});
                              },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.primaryLime,
                              backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                              child: user.avatarUrl == null
                                  ? Text(
                                      user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                                      style: const TextStyle(color: AppColors.navy900, fontSize: 32, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLime,
                                  shape: BoxShape.circle,
                                ),
                                child: _isUploadingAvatar
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy900),
                                      )
                                    : const Icon(Icons.photo_camera, color: AppColors.navy900, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Rasm tanlash uchun bosing',
                        style: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B), fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: nameController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Ism va Familiyangiz',
                        labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryLime),
                        filled: true,
                        fillColor: isDark ? AppColors.navy800 : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Yoshingiz',
                        labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.primaryLime),
                        filled: true,
                        fillColor: isDark ? AppColors.navy800 : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: cityController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Shahar / Tumaningiz',
                        labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.primaryLime),
                        filled: true,
                        fillColor: isDark ? AppColors.navy800 : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: addressController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'To\'liq manzilingiz',
                        labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.home_outlined, color: AppColors.primaryLime),
                        filled: true,
                        fillColor: isDark ? AppColors.navy800 : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLime,
                          foregroundColor: AppColors.navy900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final nameParts = nameController.text.trim().split(' ');
                          try {
                            final apiClient = ref.read(apiClientProvider);
                            final res = await apiClient.patch('/auth/profile', data: {
                              'firstName': nameParts.first,
                              'lastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
                              'city': cityController.text.trim(),
                              'age': ageController.text.trim().isNotEmpty ? int.tryParse(ageController.text.trim()) : null,
                              'address': addressController.text.trim(),
                            });
                            await ref.read(authProvider.notifier).updateUser(res.data['data'] as Map<String, dynamic>);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Profil ma\'lumotlari muvaffaqiyatli saqlandi!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saqlashda xatolik yuz berdi')),
                            );
                          }
                        },
                        child: const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMyCoursesModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.navy900 : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
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
                      color: isDark ? AppColors.navy700 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mening kurslarim (${_myEnrollments.length})',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondaryDark, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Siz ro\'yxatdan o\'tgan va o\'qiyotgan barcha o\'quv kurslaringiz',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),

                if (_myEnrollments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        'Hozircha hech qanday kursga yozilmagansiz',
                        style: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  ),

                ..._myEnrollments.map((enrollment) {
                  final course = enrollment['course'] as Map<String, dynamic>? ?? {};
                  final status = enrollment['status'] as String? ?? 'NEW';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.navy800 : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: course['coverImage'] as String? ?? '',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 56,
                              height: 56,
                              color: AppColors.navy700,
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 56,
                              height: 56,
                              color: AppColors.navy700,
                              child: const Icon(Icons.school, color: AppColors.primaryLime, size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLime.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(color: AppColors.primaryLime, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                course['titleUz'] as String? ?? '',
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSupportModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.navy900 : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.phone, color: isDark ? AppColors.primaryLime : const Color(0xFF041426)),
              title: Text('Qo\'ng\'iroq qilish', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
              subtitle: Text(AppConstants.mainPhone, style: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B))),
              onTap: () => _makeCall(AppConstants.mainPhone),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.navy800 : Colors.white,
        title: Text('Tizimdan chiqish', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
        content: Text('Haqiqatan ham tizimdan chiqmoqchimisiz?', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Bekor qilish', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              context.go('/onboarding');
            },
            child: const Text('Chiqish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setState2) => AlertDialog(
            backgroundColor: isDark ? AppColors.navy800 : Colors.white,
            title: Text('Hisobni o\'chirish', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hisobingiz butunlay o\'chiriladi: ism, telefon raqami, email va profil rasmingiz olib tashlanadi hamda hisobga qayta kirib bo\'lmaydi. Bu amalni ortga qaytarib bo\'lmaydi.',
                  style: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    labelText: 'Joriy parolingiz',
                    labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text('Bekor qilish', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (passwordController.text.isEmpty) {
                          setState2(() => errorText = 'Parolni kiriting');
                          return;
                        }
                        setState2(() {
                          isSubmitting = true;
                          errorText = null;
                        });
                        try {
                          final apiClient = ref.read(apiClientProvider);
                          await apiClient.delete('/auth/account', data: {'password': passwordController.text});
                          await ref.read(authProvider.notifier).logout();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!mounted) return;
                          context.go('/onboarding');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Hisobingiz muvaffaqiyatli o\'chirildi')),
                          );
                        } on dio.DioException catch (e) {
                          setState2(() {
                            isSubmitting = false;
                            errorText = e.response?.data?['error'] as String? ?? 'Xatolik yuz berdi';
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Hisobni o\'chirish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.navy900 : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Mening profilim'),
          backgroundColor: isDark ? AppColors.navy900 : Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off_outlined, color: AppColors.primaryLime, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Profilni ko\'rish uchun tizimga kiring',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLime,
                    foregroundColor: AppColors.navy900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  onPressed: () => context.push('/auth/login'),
                  child: const Text('Kirish / Ro\'yxatdan o\'tish', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy900 : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mening profilim'),
        backgroundColor: isDark ? AppColors.navy900 : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryLime),
            onPressed: _showEditProfileModal,
            tooltip: 'Profilni tahrirlash',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Header Card with Avatar Photo & Edit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.navy800 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showEditProfileModal,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryLime,
                          backgroundImage: user!.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: AppColors.navy900, fontWeight: FontWeight.bold, fontSize: 18),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLime,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 10, color: AppColors.navy900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.fullName,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _showEditProfileModal,
                              child: const Icon(Icons.edit, size: 14, color: AppColors.primaryLime),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.phoneNumber,
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primaryLime.withValues(alpha: 0.15) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Talaba',
                      style: TextStyle(
                        color: isDark ? AppColors.primaryLime : const Color(0xFF166534),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile Actions section
            _buildProfileSection(isDark, [
              _buildTile(
                Icons.person_outline,
                'Profil ma\'lumotlarini tahrirlash',
                'Ism, telefon va profil rasmini almashtirish',
                _showEditProfileModal,
                isDark,
              ),
              _buildTile(
                Icons.school_outlined,
                'Mening kurslarim',
                _isLoadingEnrollments ? 'Yuklanmoqda...' : '${_myEnrollments.length} ta faol va ariza berilgan kurs',
                _showMyCoursesModal,
                isDark,
              ),
              _buildTile(Icons.notifications_none_outlined, 'Bildirishnomalar', 'Yangi xabarlaringizni ko\'ring', () => context.push('/notifications'), isDark),
            ]),

            const SizedBox(height: 16),

            // Help & Contact section
            _buildProfileSection(isDark, [
              _buildTile(Icons.help_outline, 'Qo\'llab-quvvatlash va Aloqa', AppConstants.mainPhone, _showSupportModal, isDark),
              _buildTile(Icons.logout, 'Tizimdan chiqish', '', _showLogoutDialog, isDark, isDanger: true),
              _buildTile(Icons.delete_forever_outlined, 'Hisobni o\'chirish', '', _showDeleteAccountDialog, isDark, isDanger: true),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navy800 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    bool isDark, {
    bool isDanger = false,
  }) {
    final iconColor = isDanger ? AppColors.error : (isDark ? AppColors.primaryLime : const Color(0xFF041426));

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? AppColors.error : (isDark ? Colors.white : AppColors.textPrimaryLight),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                fontSize: 12,
              ),
            )
          : null,
      trailing: isDanger ? null : Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8)),
    );
  }
}
