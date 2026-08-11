import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../core/widgets/academy_logo.dart';
import '../../../core/widgets/custom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isSignUpMode = false;
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+998 ');
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorText;

  Future<void> _submitAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;

      Response response;
      if (_isSignUpMode) {
        final nameParts = _fullNameController.text.trim().split(' ');
        response = await apiClient.post('/auth/register', data: {
          'firstName': nameParts.first,
          'lastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          'phoneNumber': phone,
          'password': password,
          'age': _ageController.text.trim().isNotEmpty ? int.tryParse(_ageController.text.trim()) : null,
          'address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        });
      } else {
        response = await apiClient.post('/auth/login', data: {
          'phoneNumber': phone,
          'password': password,
        });
      }

      final data = response.data['data'];
      await ref.read(authProvider.notifier).setSession(data['token'] as String, data['user'] as Map<String, dynamic>);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
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

                // Top Logo
                const AcademyLogo(size: 64, showText: true),

                const SizedBox(height: 24),

                // Mode Switcher (Kirish / Ro'yxatdan o'tish)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.navy800 : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSignUpMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSignUpMode
                                  ? (isDark ? AppColors.primaryLime : const Color(0xFF041426))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Kirish',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !_isSignUpMode
                                    ? (isDark ? AppColors.navy900 : Colors.white)
                                    : (isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isSignUpMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSignUpMode
                                  ? (isDark ? AppColors.primaryLime : const Color(0xFF041426))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Ro\'yxatdan o\'tish',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isSignUpMode
                                    ? (isDark ? AppColors.navy900 : Colors.white)
                                    : (isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Form Title & Subtitle
                Text(
                  _isSignUpMode ? 'Ro\'yxatdan o\'tish' : 'Tizimga kirish',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUpMode
                      ? 'Yangi hisob yarating va kurslarga yoziling!'
                      : 'Chust One Academy platformasiga xush kelibsiz!',
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

                // Full Name (Only in SignUp Mode)
                if (_isSignUpMode) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ism va Familiyangiz',
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _fullNameController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Sardorbek Karimov',
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryLime),
                      filled: true,
                      fillColor: isDark ? AppColors.navy800 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    validator: (val) => _isSignUpMode && (val == null || val.trim().isEmpty) ? 'Ismingizni kiriting' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Phone Input
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
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryLime),
                    filled: true,
                    fillColor: isDark ? AppColors.navy800 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Telefon raqamni kiriting' : null,
                ),

                const SizedBox(height: 16),

                // Age & Address (Only in SignUp Mode)
                if (_isSignUpMode) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Yoshingiz',
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Masalan: 18',
                      prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.primaryLime),
                      filled: true,
                      fillColor: isDark ? AppColors.navy800 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Manzilingiz',
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Shahar / Tuman, ko\'cha',
                      prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.primaryLime),
                      filled: true,
                      fillColor: isDark ? AppColors.navy800 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Password Input
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Parolingiz',
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryLime),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondaryDark,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.navy800 : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  validator: (val) => val == null || val.length < 4 ? 'Parolni kiriting (kamida 4 belgi)' : null,
                ),

                const SizedBox(height: 24),

                // Submit Button
                CustomButton(
                  label: _isSignUpMode ? 'Ro\'yxatdan o\'tish' : 'Kirish',
                  isLoading: _isLoading,
                  onPressed: _submitAuth,
                ),

                const SizedBox(height: 16),

                // Mode Toggle Footer Link
                TextButton(
                  onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                  child: Text(
                    _isSignUpMode
                        ? 'Akkauntingiz bormi? Tizimga kiring'
                        : 'Akkauntingiz yo\'qmi? Ro\'yxatdan o\'ting',
                    style: const TextStyle(
                      color: AppColors.primaryLime,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),

                // Guest Mode Button
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
