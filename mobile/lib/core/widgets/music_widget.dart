import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../app/theme/app_colors.dart';
import '../services/background_music_service.dart';

/// Floating control for the app-wide background jingle, which always keeps
/// looping — there is no pause button. By default this shows only a small
/// speaker icon so it doesn't sit on top of page content: tap it to
/// mute/unmute instantly, or long-press to reveal a volume slider that
/// collapses again a couple seconds after the visitor stops touching it.
class MusicWidget extends StatefulWidget {
  const MusicWidget({super.key});

  @override
  State<MusicWidget> createState() => _MusicWidgetState();
}

class _MusicWidgetState extends State<MusicWidget> {
  final _service = BackgroundMusicService.instance;
  bool _expanded = false;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  void _scheduleCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  void _onIconTap() {
    _service.toggleMute();
    if (_expanded) _scheduleCollapse();
  }

  void _onIconLongPress() {
    setState(() => _expanded = true);
    _scheduleCollapse();
  }

  FaIconData get _volumeIcon {
    if (_service.muted || _service.volume == 0) return FontAwesomeIcons.volumeXmark;
    if (_service.volume < 0.5) return FontAwesomeIcons.volumeLow;
    return FontAwesomeIcons.volumeHigh;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.navy800,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderDark),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _expanded
                    ? SizedBox(
                        width: 90,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            activeTrackColor: AppColors.primaryLime,
                            inactiveTrackColor: AppColors.borderDark,
                            thumbColor: AppColors.primaryLime,
                          ),
                          child: Slider(
                            value: _service.muted ? 0 : _service.volume,
                            onChanged: (v) {
                              _service.setVolume(v);
                              _scheduleCollapse();
                            },
                          ),
                        ),
                      )
                    : const SizedBox(width: 0),
              ),
              GestureDetector(
                onTap: _onIconTap,
                onLongPress: _onIconLongPress,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLime,
                    shape: BoxShape.circle,
                  ),
                  child: FaIcon(
                    _volumeIcon,
                    color: AppColors.navy900,
                    size: 15,
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
