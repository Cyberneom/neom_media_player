import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:sint/sint.dart';
import 'package:neom_media_player/ui/neom_video_player.dart';

class VideoControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isFullscreen;
  final VoidCallback? onFullScreenTap;
  final VoidCallback? onTap;

  const VideoControlsOverlay({
    required this.controller,
    this.isFullscreen = false,
    this.onFullScreenTap,
    this.onTap,
    super.key,
  });

  @override
  State<VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<VideoControlsOverlay> {
  bool _isVisible = false;
  Timer? _hideTimer;
  bool _isHoveringVolume = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_videoListener);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_videoListener);
    super.dispose();
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  void _showControls() {
    setState(() {
      _isVisible = true;
    });
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying && !_isHoveringVolume) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 
      ? '${twoDigits(duration.inHours)}:$minutes:$seconds'
      : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => _showControls(),
      onEnter: (_) => _showControls(),
      onExit: (_) {
        if (widget.controller.value.isPlaying) {
          setState(() => _isVisible = false);
        }
      },
      child: GestureDetector(
        onTap: () {
          _showControls();
          if (widget.onTap != null) widget.onTap!();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          opacity: _isVisible || !widget.controller.value.isPlaying ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
              // Play/Pause Big Button in center
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (widget.controller.value.isPlaying) {
                      widget.controller.pause();
                    } else {
                      widget.controller.play();
                    }
                    _showControls();
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 32,
                    child: Icon(
                      widget.controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),

              // Bottom Gradient and Controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom Scrubber
                      Row(
                        children: [
                          Expanded(
                            child: VideoProgressIndicator(
                              widget.controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.redAccent,
                                bufferedColor: Colors.white30,
                                backgroundColor: Colors.white12,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Controls Row
                      Row(
                        children: [
                          // Play/Pause
                          InkWell(
                            onTap: () {
                              if (widget.controller.value.isPlaying) {
                                widget.controller.pause();
                              } else {
                                widget.controller.play();
                              }
                            },
                            child: Icon(
                              widget.controller.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Volume Controls
                          MouseRegion(
                            onEnter: (_) => setState(() => _isHoveringVolume = true),
                            onExit: (_) {
                              setState(() => _isHoveringVolume = false);
                              _showControls(); // Trigger hide timer again
                            },
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    NeomVideoPlayer.isGlobalMuted.value = !NeomVideoPlayer.isGlobalMuted.value;
                                  },
                                  child: Obx(() => Icon(
                                    NeomVideoPlayer.isGlobalMuted.value 
                                      ? Icons.volume_off_rounded 
                                      : Icons.volume_up_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  )),
                                ),
                                // Expandable Volume Slider on Hover (Web only makes sense)
                                if (kIsWeb)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: _isHoveringVolume ? 80 : 0,
                                    curve: Curves.easeInOut,
                                    child: ClipRect(
                                      child: Obx(() => Slider(
                                        value: NeomVideoPlayer.isGlobalMuted.value ? 0.0 : widget.controller.value.volume,
                                        min: 0.0,
                                        max: 1.0,
                                        activeColor: Colors.white,
                                        inactiveColor: Colors.white30,
                                        onChanged: (val) {
                                          if (val > 0) {
                                            NeomVideoPlayer.isGlobalMuted.value = false;
                                            widget.controller.setVolume(val);
                                          } else {
                                            NeomVideoPlayer.isGlobalMuted.value = true;
                                            widget.controller.setVolume(0);
                                          }
                                        },
                                      )),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          // Timestamp
                          Text(
                            '${_formatDuration(widget.controller.value.position)} / ${_formatDuration(widget.controller.value.duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Fullscreen
                          if (widget.onFullScreenTap != null)
                            InkWell(
                              onTap: widget.onFullScreenTap,
                              child: Icon(
                                widget.isFullscreen
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                        ],
                      ),
                    ],
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
