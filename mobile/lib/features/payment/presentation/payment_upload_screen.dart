import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../core/widgets/custom_button.dart';

class PaymentUploadScreen extends ConsumerStatefulWidget {
  final String? enrollmentId;
  final num? amount;

  const PaymentUploadScreen({super.key, this.enrollmentId, this.amount});

  @override
  ConsumerState<PaymentUploadScreen> createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends ConsumerState<PaymentUploadScreen> {
  String _selectedMethod = 'Click';
  File? _receiptFile;
  bool _isSubmitting = false;

  final List<Map<String, String>> _methods = [
    {'name': 'Click', 'icon': '💳'},
    {'name': 'Payme', 'icon': '📲'},
    {'name': 'Uzum Bank', 'icon': '💎'},
    {'name': 'Naqd / Administrator', 'icon': '💵'},
  ];

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _receiptFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (widget.enrollmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ariza topilmadi. Avval kursga yozilishni yakunlang.')),
      );
      return;
    }
    if (_receiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, to\'lov chekini yuklang')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);

      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(_receiptFile!.path),
      });
      final uploadResponse = await apiClient.dio.post('/upload', data: formData);
      final receiptUrl = uploadResponse.data['data']['url'] as String;

      await apiClient.post('/payments', data: {
        'enrollmentId': widget.enrollmentId,
        'amount': widget.amount,
        'method': _selectedMethod,
        'receiptUrl': receiptUrl,
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('To\'lov cheki qabul qilindi. Tez orada admin tasdiqlaydi.'),
        ),
      );
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yuklashda xatolik yuz berdi. Qaytadan urinib ko\'ring.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy900 : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('To\'lov qilish'),
        backgroundColor: isDark ? AppColors.navy900 : AppColors.surfaceLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLime.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryLime, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.amount != null
                          ? 'Arizangiz qabul qilindi. To\'lov summasi: ${widget.amount!.toStringAsFixed(0)} so\'m. Kursga biriktirilishingiz uchun to\'lov chekini yuklang.'
                          : 'Arizangiz qabul qilindi. Kursga biriktirilishingiz uchun to\'lov chekini yuklang.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'To\'lov turini tanlang',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _methods.map((method) {
                final isSelected = _selectedMethod == method['name'];
                return InkWell(
                  onTap: () => setState(() => _selectedMethod = method['name']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLime
                          : (isDark ? AppColors.navy800 : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryLime : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(method['icon']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          method['name']!,
                          style: TextStyle(
                            color: isSelected ? AppColors.navy900 : (isDark ? Colors.white : AppColors.textPrimaryLight),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            Text(
              'To\'lov chekini yuklash (Screenshot)',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            InkWell(
              onTap: _pickReceipt,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navy800 : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _receiptFile != null ? AppColors.success : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: _receiptFile != null ? 2 : 1,
                  ),
                ),
                child: _receiptFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_receiptFile!, fit: BoxFit.cover, width: double.infinity, height: 160),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryLime, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Rasm yuklash uchun bosing',
                              style: TextStyle(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 32),

            CustomButton(
              label: 'Tasdiqqa yuborish',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
