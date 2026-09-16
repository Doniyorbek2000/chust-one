import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/background_music_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundMusicService.instance.init();
  runApp(
    const ProviderScope(
      child: ChustOneApp(),
    ),
  );
}
