import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide background jingle: starts as soon as the app launches (no user
/// gesture needed on Android/iOS, unlike a web page) and stays alive across
/// screen navigation. A single instance lives for the app's lifetime.
///
/// Audio session is deliberately configured to respect the platform's
/// silent/mute conventions:
/// - iOS: [AVAudioSessionCategory.ambient] — silenced by the Ring/Silent
///   switch and by screen locking, and mixes with any other app's audio.
///   This avoids needing the `UIBackgroundModes: audio` capability, which
///   Apple review flags when an app doesn't have a genuine background-audio
///   use case.
/// - Android: standard `media`/`music` usage so it follows the media volume
///   stream like any normal audio app.
class BackgroundMusicService extends ChangeNotifier with WidgetsBindingObserver {
  BackgroundMusicService._internal();
  static final BackgroundMusicService instance = BackgroundMusicService._internal();

  static const _prefsVolumeKey = 'bg_music_volume';
  static const _prefsMutedKey = 'bg_music_muted';
  static const _assetPath = 'audio/music.mp3';

  final AudioPlayer _player = AudioPlayer();

  double volume = 0.6;
  bool muted = false;

  bool _initialized = false;
  bool _wasPlayingBeforeBackground = false;
  bool _pausedForForegroundVideo = false;

  bool get isPlaying => _player.state == PlayerState.playing;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    volume = prefs.getDouble(_prefsVolumeKey) ?? 0.6;
    muted = prefs.getBool(_prefsMutedKey) ?? false;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
    await _player.setVolume(muted ? 0 : volume);

    _player.onPlayerStateChanged.listen((_) => notifyListeners());

    WidgetsBinding.instance.addObserver(this);

    if (!muted) {
      await _player.play(AssetSource(_assetPath));
    }
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsVolumeKey, volume);
    await prefs.setBool(_prefsMutedKey, muted);
  }

  Future<void> _resumeOrStart() async {
    if (_player.source == null) {
      await _player.play(AssetSource(_assetPath));
    } else {
      await _player.resume();
    }
  }

  Future<void> toggleMute() async {
    muted = !muted;
    await _player.setVolume(muted ? 0 : volume);
    if (!muted && !isPlaying && !_pausedForForegroundVideo) {
      await _resumeOrStart();
    }
    await _savePrefs();
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    volume = value.clamp(0.0, 1.0);
    muted = volume == 0;
    await _player.setVolume(muted ? 0 : volume);
    await _savePrefs();
    notifyListeners();
  }

  /// Call when another in-app audio/video (e.g. a testimonial clip) starts
  /// playing, so the two sources don't overlap.
  Future<void> pauseForForegroundVideo() async {
    if (isPlaying) {
      _pausedForForegroundVideo = true;
      await _player.pause();
    }
  }

  /// Call once that other audio/video finishes or is dismissed.
  Future<void> resumeAfterForegroundVideo() async {
    if (_pausedForForegroundVideo) {
      _pausedForForegroundVideo = false;
      if (!muted) {
        await _resumeOrStart();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _wasPlayingBeforeBackground = isPlaying;
        if (isPlaying) _player.pause();
        break;
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforeBackground && !muted && !_pausedForForegroundVideo) {
          _resumeOrStart();
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }
}
