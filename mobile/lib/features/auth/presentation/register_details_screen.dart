import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../core/widgets/academy_logo.dart';
import '../../../core/widgets/custom_button.dart';

// Step 3 (new accounts only) of the phone/SMS-code auth flow: the phone was
// just OTP-verified (registrationToken proves it), so this only collects the
// remaining profile fields and creates the account.
class RegisterDetailsScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String registrationToken;

  const RegisterDetailsScreen({super.key, required this.phoneNumber, required this.registrationToken});

  @override
  ConsumerState<RegisterDetailsScreen> createState() => _RegisterDetailsScreenState();
}

class _RegisterDetailsScreenState extends ConsumerState<RegisterDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _birthDate;
  bool _isLoading = false;
  String? _errorText;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Tug\'ilgan sanangizni tanlang',
      cancelText: 'Bekor qilish',
      confirmText: 'Tanlash',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_birthDate == null) {
      setState(() => _errorText = 'Tug\'ilgan sanangizni tanlang');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/auth/otp/complete-registration', data: {
        'registrationToken': widget.registrationToken,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'birthDate': DateFormat('yyyy-MM-dd').format(_birthDate!),
        'address': _addressController.text.trim(),
      });

      final data = response.data['data'] as Map<String, dynamic>;
      await ref.read(authProvider.notifier).setSession(data['token'] as String, data['user'] as Map<String, dynamic>);

      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = e.response?.data?['error']?.toString() ?? 'Xatolik yuz berdi. Internetni tekshiring.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Kutilmagan xatolik yuz berdi';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy900 : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                const AcademyLogo(size: 56, showText: true),
                const SizedBox(height: 24),
                Text(
                  'Ma\'lumotlaringizni to\'ldiring',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ro\'yxatdan o\'tishni yakunlash uchun quyidagilarni kiriting',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorText != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _errorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],

                _FieldLabel('Ismingiz', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                  decoration: _inputDecoration(isDark, hint: 'Sardorbek', icon: Icons.person_outline),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Ismingizni kiriting' : null,
                ),
                const SizedBox(height: 16),

                _FieldLabel('Familiyangiz', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                  decoration: _inputDecoration(isDark, hint: 'Karimov', icon: Icons.person_outline),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Familiyangizni kiriting' : null,
                ),
                const SizedBox(height: 16),

                _FieldLabel('Tug\'ilgan sanangiz', isDark),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: _inputDecoration(isDark, hint: 'Kun / Oy / Yil', icon: Icons.cake_outlined),
                    child: Text(
                      _birthDate == null ? 'Kun / Oy / Yilni tanlang' : DateFormat('dd.MM.yyyy').format(_birthDate!),
                      style: TextStyle(
                        color: _birthDate == null
                            ? (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8))
                            : (isDark ? Colors.white : AppColors.textPrimaryLight),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _FieldLabel('Yashash manzilingiz', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressController,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                  decoration: _inputDecoration(isDark, hint: 'Shahar / Tuman, ko\'cha', icon: Icons.location_city_outlined),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Manzilingizni kiriting' : null,
                ),

                const SizedBox(height: 24),

                CustomButton(
                  label: 'Ro\'yxatdan o\'tishni yakunlash',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryLime),
      filled: true,
      fillColor: isDark ? AppColors.navy800 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _FieldLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
