import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import 'custom_button.dart';

/// Full-screen, non-dismissible gate shown when the CMS marks the installed
/// app version as below `minAppVersion` with `forceUpdate` enabled.
class UpdateRequiredScreen extends StatelessWidget {
  final String storeUrl;

  const UpdateRequiredScreen({super.key, required this.storeUrl});

  Future<void> _openStore() async {
    if (storeUrl.isEmpty) return;
    await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt_rounded, color: AppColors.primaryLime, size: 72),
              const SizedBox(height: 16),
              const Text(
                'Yangi versiya mavjud',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ilovadan foydalanishni davom ettirish uchun uni eng so\'nggi versiyaga yangilang.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Hozir yangilash',
                onPressed: storeUrl.isEmpty ? null : _openStore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
