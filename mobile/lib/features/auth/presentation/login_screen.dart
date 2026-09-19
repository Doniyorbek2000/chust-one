import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../core/widgets/academy_logo.dart';
import '../../../core/widgets/custom_button.dart';

// Step 1 of the phone/SMS-code auth flow: collect the phone number and send
// the 4-digit code. Step 2 (otp_screen) verifies it, then either logs the
// user straight in (existing account) or routes to register_details_screen
// (new account) — see docs in otp_screen.dart for the full flow.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+998 ');

  bool _isLoading = false;
  String? _errorText;

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final phone = _phoneController.text.trim();

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/auth/otp/request', data: {'phoneNumber': phone});

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.push('/auth/otp', extra: {'phoneNumber': phone});
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
                const SizedBox(height: 4),

                if (context.canPop())
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? AppColors.navy800 : Colors.white,
                        padding: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                const AcademyLogo(size: 64, showText: true),

                const SizedBox(height: 24),

                Text(
                  'Tizimga kirish',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Telefon raqamingizni kiriting, biz sizga tasdiqlash kodini SMS orqali yuboramiz.',
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

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Telefon raqamingiz',
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '+998 90 123 45 67',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryLime),
                    filled: true,
                    fillColor: isDark ? AppColors.navy800 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  validator: (val) {
                    final digits = (val ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length < 9) return 'Telefon raqamni to\'liq kiriting';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                CustomButton(
                  label: 'SMS kod yuborish',
                  isLoading: _isLoading,
                  onPressed: _sendCode,
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Mexmon sifatida davom etish >',
                    style: TextStyle(
                      color: isDark ? AppColors.primaryLime : const Color(0xFF041426),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
