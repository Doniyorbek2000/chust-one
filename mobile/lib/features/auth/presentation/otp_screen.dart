import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../core/widgets/custom_button.dart';

// Step 2 of the phone/SMS-code auth flow. Verifies the 4-digit code the user
// received; the backend then reports one of two outcomes:
//  - "logged_in": the phone already belongs to an account -> log straight in.
//  - "registration_required": new phone -> hand off a short-lived
//    registration token to register_details_screen to finish signup.
class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _codeLength = 4;

  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorText;
  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown(60);
    _codeController.addListener(() {
      if (_codeController.text.length == _codeLength && !_isVerifying) {
        _verify();
      }
    });
    // Repaints the box highlight when focus is gained/lost (e.g. tapping
    // away to dismiss the keyboard).
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() => _resendCooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/auth/otp/verify', data: {
        'phoneNumber': widget.phoneNumber,
        'code': _codeController.text.trim(),
      });

      final data = response.data['data'] as Map<String, dynamic>;
      if (!mounted) return;

      if (data['status'] == 'logged_in') {
        await ref.read(authProvider.notifier).setSession(data['token'] as String, data['user'] as Map<String, dynamic>);
        if (!mounted) return;
        context.go('/home');
      } else {
        context.push('/auth/register-details', extra: {
          'phoneNumber': widget.phoneNumber,
          'registrationToken': data['registrationToken'] as String,
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = e.response?.data?['error']?.toString() ?? 'Kod tekshirilmadi. Internetni tekshiring.';
        _codeController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorText = 'Kutilmagan xatolik yuz berdi';
        _codeController.clear();
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _errorText = null;
    });
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/auth/otp/request', data: {'phoneNumber': widget.phoneNumber});
      final cooldown = (response.data['data']?['cooldownSeconds'] as num?)?.toInt() ?? 60;
      if (!mounted) return;
      setState(() => _isResending = false);
      _codeController.clear();
      _startCooldown(cooldown);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorText = e.response?.data?['error']?.toString() ?? 'Kod qayta yuborilmadi';
      });
    }
  }

  Widget _buildCodeBoxes(bool isDark) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_focusNode),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _codeController,
            builder: (context, value, _) {
              final text = value.text;
              final activeIndex = text.length.clamp(0, _codeLength - 1);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_codeLength, (i) {
                  final filled = i < text.length;
                  final isActive = i == activeIndex && _focusNode.hasFocus;
                  return Container(
                    width: 56,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.navy800 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive || filled
                            ? AppColors.primaryLime
                            : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                        width: isActive ? 2 : 1.5,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primaryLime.withValues(alpha: 0.25),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      filled ? text[i] : '',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          // The real input is invisible but still occupies the same space, so
          // taps land on it and the OS's SMS-code autofill bar still targets
          // it — the boxes above are purely a visual reflection of its text.
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: (56.0 + 14.0) * _codeLength,
              height: 64,
              child: TextField(
                controller: _codeController,
                focusNode: _focusNode,
                autofocus: true,
                enabled: !_isVerifying,
                showCursor: false,
                enableInteractiveSelection: false,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: _codeLength,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy900 : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // Soft ambient glow, matching the splash/onboarding brand style.
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLime.withValues(alpha: 0.10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLime.withValues(alpha: 0.10),
                        blurRadius: 90,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Align(
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
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.62),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? AppColors.navy800 : Colors.white,
                              border: Border.all(color: AppColors.primaryLime.withValues(alpha: 0.6), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryLime.withValues(alpha: 0.18),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.sms_outlined, color: AppColors.primaryLime, size: 36),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tasdiqlash kodi',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.phoneNumber} raqamiga yuborilgan\n4 xonali kodni kiriting',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          if (_errorText != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
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

                          _buildCodeBoxes(isDark),

                          const SizedBox(height: 28),

                          if (_isVerifying)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 20),
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLime)),
                              ),
                            ),

                          CustomButton(
                            label: _resendCooldown > 0 ? 'Qayta yuborish (${_resendCooldown}s)' : 'Kodni qayta yuborish',
                            variant: ButtonVariant.outline,
                            width: 240,
                            isLoading: _isResending,
                            onPressed: _resendCooldown > 0 ? null : _resend,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
