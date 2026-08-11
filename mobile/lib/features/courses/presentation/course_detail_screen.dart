import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/auth_provider.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _addressController;

  String _selectedTime = 'Ertalabki (09:00 - 11:00)';
  bool _isSubmitting = false;

  bool _isLoading = true;
  String? _loadError;
  Map<String, dynamic>? _course;

  final List<String> _timeSlots = [
    'Ertalabki (09:00 - 11:00)',
    'Tushki (14:00 - 16:00)',
    'Kechki (17:00 - 19:00)',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _ageController = TextEditingController();
    _addressController = TextEditingController();
    _fetchCourse();
  }

  Future<void> _fetchCourse() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/courses/${widget.courseId}');
      if (mounted) {
        setState(() {
          _course = response.data['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'Kurs ma\'lumotlarini yuklab bo\'lmadi';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  List<String> _extractTopics() {
    final modules = _course?['modules'] as List<dynamic>? ?? [];
    final topics = <String>[];
    for (final m in modules) {
      final moduleTopics = (m as Map<String, dynamic>)['topics'] as List<dynamic>? ?? [];
      for (final t in moduleTopics) {
        topics.add((t as Map<String, dynamic>)['titleUz'] as String? ?? '');
      }
    }
    return topics.where((t) => t.isNotEmpty).toList();
  }

  void _onEnrollPressed() {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kursga yozilish uchun avval ro\'yxatdan o\'ting')),
      );
      context.push('/auth/login');
      return;
    }

    final user = auth.user!;
    _nameController.text = user.fullName;
    _phoneController.text = user.phoneNumber;
    _ageController.text = user.age?.toString() ?? '';
    _addressController.text = user.address ?? '';

    _showApplyDialog();
  }

  void _showApplyDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              child: Form(
                key: _formKey,
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
                        'Kursga yozilish',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _course?['titleUz'] as String? ?? '',
                        style: const TextStyle(color: AppColors.primaryLime, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                        decoration: _fieldDecoration('Ism va Familiyangiz *', isDark),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Ismingizni kiriting' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                        decoration: _fieldDecoration('Telefon raqamingiz *', isDark),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Telefon raqamni kiriting' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                              decoration: _fieldDecoration('Yoshingiz', isDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _addressController,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                        decoration: _fieldDecoration('Manzilingiz', isDark),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedTime,
                        dropdownColor: isDark ? AppColors.navy800 : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 13),
                        decoration: _fieldDecoration("Ma'qul keladigan dars vaqti *", isDark),
                        items: _timeSlots.map((time) {
                          return DropdownMenuItem(value: time, child: Text(time, style: const TextStyle(fontSize: 12)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => _selectedTime = val);
                        },
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLime,
                            foregroundColor: AppColors.navy900,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    setModalState(() => _isSubmitting = true);
                                    await _submitEnrollment(ctx);
                                    setModalState(() => _isSubmitting = false);
                                  }
                                },
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: AppColors.navy900, strokeWidth: 2.5),
                                )
                              : const Text('Kursga yozilish >', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _fieldDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
      filled: true,
      fillColor: isDark ? AppColors.navy800 : const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }

  Future<void> _submitEnrollment(BuildContext sheetContext) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/enrollments', data: {
        'courseId': widget.courseId,
        'preferredTime': _selectedTime,
        'applicantAge': _ageController.text.trim().isNotEmpty ? int.tryParse(_ageController.text.trim()) : null,
        'address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      });

      final enrollment = response.data['data'] as Map<String, dynamic>;

      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      _showSuccessDialog();

      if (!mounted) return;
      final price = (_course?['discountPrice'] ?? _course?['price'] ?? 0) as num;
      context.push('/payment-upload', extra: {
        'enrollmentId': enrollment['id'],
        'amount': price,
      });
    } on DioException catch (e) {
      if (!sheetContext.mounted) return;
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(content: Text(e.response?.data?['error']?.toString() ?? 'Xatolik yuz berdi')),
      );
    } catch (_) {
      if (!sheetContext.mounted) return;
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Kutilmagan xatolik yuz berdi')),
      );
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.navy800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.primaryLime, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Arizangiz qabul qilindi!',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "Endi to'lov chekini yuklab, kursga biriktirilishingizni tasdiqlang.",
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLime,
              foregroundColor: AppColors.navy900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Davom etish", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.navy900 : const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryLime)),
      );
    }

    if (_loadError != null || _course == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.navy900 : const Color(0xFFF8FAFC),
        appBar: AppBar(backgroundColor: isDark ? AppColors.navy900 : Colors.white, elevation: 0),
        body: Center(
          child: Text(_loadError ?? 'Kurs topilmadi', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight)),
        ),
      );
    }

    final course = _course!;
    final topics = _extractTopics();
    final price = course['price'] as num;
    final discountPrice = course['discountPrice'] as num?;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy900 : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(course['titleUz'] as String? ?? ''),
        backgroundColor: isDark ? AppColors.navy900 : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course['titleUz'] as String? ?? '',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if ((course['subtitleUz'] as String?)?.isNotEmpty ?? false)
              Text(
                course['subtitleUz'] as String,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            if ((course['targetAudienceUz'] as String?)?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLime.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_2_outlined, size: 14, color: AppColors.primaryLime),
                    const SizedBox(width: 6),
                    Text(
                      course['targetAudienceUz'] as String,
                      style: const TextStyle(color: AppColors.primaryLime, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                course['coverImage'] as String? ?? '',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: AppColors.navy800,
                  child: const Icon(Icons.school, color: AppColors.primaryLime, size: 60),
                ),
              ),
            ),

            const SizedBox(height: 18),

            if ((course['descriptionUz'] as String?)?.isNotEmpty ?? false)
              Text(
                course['descriptionUz'] as String,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

            const SizedBox(height: 20),

            if (topics.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navy800 : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                  boxShadow: isDark
                      ? []
                      : [
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.navy700 : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        'KURS DAVOMIDA SIZ:',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...topics.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLime,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t,
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),

      // Bottom Bar with "Kursga yozilish >" button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.navy900 : Colors.white,
          border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kurs narxi:',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  Text(
                    discountPrice != null ? '${discountPrice.toStringAsFixed(0)} so\'m' : '${price.toStringAsFixed(0)} so\'m',
                    style: TextStyle(
                      color: isDark ? AppColors.primaryLime : const Color(0xFF059669),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLime,
                      foregroundColor: AppColors.navy900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    onPressed: _onEnrollPressed,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kursga yozilish',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
