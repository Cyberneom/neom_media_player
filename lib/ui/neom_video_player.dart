import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_core/domain/use_cases/audio_handler_service.dart';
import 'package:sint/sint.dart';
import 'package:video_player/video_player.dart';

import 'full_screen/full_screen_video_page.dart';
import 'media_player_controller.dart';

class NeomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final bool showProgress;
  final GlobalKey videoKey; // ✅ Nuevo parámetro para la clave única
  final bool isFullscreen;
  final VoidCallback? onFullScreenTap;

  // Global mute state shared across all instances
  static final RxBool isGlobalMuted = true.obs;

  // Track active fullscreen video URLs to prevent double rendering inline
  static final RxSet<String> _fullscreenUrls = <String>{}.obs;

  final bool isTransitioning;

  // Static cache to keep video controllers alive and reuse them on Web
  static final Map<String, VideoPlayerController> _webVideoCache = {};

  static VideoPlayerController? getVideoController(String url) {
    return _webVideoCache[url];
  }

  const NeomVideoPlayer({
    required this.videoUrl,
    required this.videoKey,
    this.showProgress = true,
    this.thumbnailUrl = '',
    this.isFullscreen = false,
    this.onFullScreenTap,
    this.isTransitioning = false,
    super.key,
  });

  @override
  State<NeomVideoPlayer> createState() => _NeomVideoPlayerState();
}

class _NeomVideoPlayerState extends State<NeomVideoPlayer> {
  late VideoPlayerController _controller;
  final isInitialized = false.obs;
  bool _isFullScreenActive = false;
  dynamic _muteSubscription;

  void _pauseMusicPlayer() {
    if (Sint.isRegistered<AudioHandlerService>()) {
      final audioHandler = Sint.find<AudioHandlerService>();
      if (audioHandler.isPlaying) {
        audioHandler.pause();
        audioHandler.stoppedByVideo = true;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isFullscreen) {
      NeomVideoPlayer._fullscreenUrls.add(widget.videoUrl);
    }
    final cached = NeomVideoPlayer._webVideoCache[widget.videoUrl];
    if (kIsWeb && cached != null) {
      _controller = cached;
      isInitialized.value = _controller.value.isInitialized;
      if (isInitialized.value) {
        _controller.setVolume((NeomVideoPlayer.isGlobalMuted.value || !widget.isFullscreen) ? 0 : 1);
      }
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          isInitialized.value = true;
          _controller.setVolume((NeomVideoPlayer.isGlobalMuted.value || !widget.isFullscreen) ? 0 : 1);

          if (Sint.isRegistered<MediaPlayerController>()) {
            final mediaPlayerController = Sint.find<MediaPlayerController>();
            mediaPlayerController.registerVideoKeyController(widget.videoUrl, widget.videoKey, _controller);
          } else {
            _controller.play(); // ▶️ Reproducir automáticamente
          }
        });
      if (kIsWeb) {
        NeomVideoPlayer._webVideoCache[widget.videoUrl] = _controller;
      }
    }

    _muteSubscription = NeomVideoPlayer.isGlobalMuted.listen((muted) {
      if (mounted && isInitialized.value) {
        _controller.setVolume((muted || !widget.isFullscreen) ? 0 : 1);
        if (!muted && widget.isFullscreen && _controller.value.isPlaying) {
          _pauseMusicPlayer();
        }
      }
    });

    _controller.addListener(() {
      if (mounted && _controller.value.isPlaying && widget.isFullscreen && !NeomVideoPlayer.isGlobalMuted.value) {
        _pauseMusicPlayer();
      }
    });
  }

  @override
  void dispose() {
    if (widget.isFullscreen) {
      NeomVideoPlayer._fullscreenUrls.remove(widget.videoUrl);
    }
    _muteSubscription?.cancel();
    
    if (Sint.isRegistered<MediaPlayerController>()) {
      Sint.find<MediaPlayerController>().unregisterVideoKeyController(widget.videoUrl);
    }
    
    if (kIsWeb) {
      NeomVideoPlayer._webVideoCache.remove(widget.videoUrl);
    }
    
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final isVertical = _controller.value.isInitialized && _controller.value.aspectRatio < 1.1;
      final fit = widget.isFullscreen
          ? BoxFit.contain
          : (isVertical ? BoxFit.contain : BoxFit.cover);

      return Obx(() {
        final isUrlInFullscreen = NeomVideoPlayer._fullscreenUrls.contains(widget.videoUrl);
        final showPlaceholder = _isFullScreenActive || 
                               widget.isTransitioning || 
                               (isUrlInFullscreen && !widget.isFullscreen);

        return isInitialized.value
            ? SizedBox.expand(
                child: GestureDetector(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Hero(
                        tag: 'video-hero-${widget.videoUrl}',
                        child: showPlaceholder
                            ? HandledCachedNetworkImage(
                                widget.thumbnailUrl.isNotEmpty ? widget.thumbnailUrl : widget.videoUrl,
                                fit: fit,
                              )
                            : SizedBox.expand(
                                child: FittedBox(
                                  fit: fit,
                                  clipBehavior: Clip.hardEdge,
                                  child: SizedBox(
                                    width: _controller.value.size.width,
                                    height: _controller.value.size.height,
                                    child: VideoPlayer(_controller),
                                  ),
                                ),
                              ),
                      ),
                    if (widget.showProgress)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.grey,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          NeomVideoPlayer.isGlobalMuted.toggle();
                        },
                        child: Obx(() => CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 16,
                          child: Icon(
                            NeomVideoPlayer.isGlobalMuted.value ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                            size: 20,
                          ),
                        )),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: widget.onFullScreenTap != null
                            ? widget.onFullScreenTap
                            : () async {
                                setState(() => _isFullScreenActive = true);
                                await Sint.to(() => FullScreenVideoPage(controller: _controller),
                                    transition: Transition.zoom);
                                if (mounted) setState(() => _isFullScreenActive = false);
                              },
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 16,
                          child: Icon(
                            widget.isFullscreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                },
                onDoubleTap: widget.onFullScreenTap != null
                    ? widget.onFullScreenTap
                    : () async {
                        setState(() => _isFullScreenActive = true);
                        await Sint.to(() => FullScreenVideoPage(controller: _controller),
                            transition: Transition.zoom);
                        if (mounted) setState(() => _isFullScreenActive = false);
                      },
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                HandledCachedNetworkImage(widget.thumbnailUrl.isNotEmpty ? widget.thumbnailUrl : widget.videoUrl),
                const Center(child: CircularProgressIndicator()),
              ],
            );
      });
    }

    return Obx(() {
      final isUrlInFullscreen = NeomVideoPlayer._fullscreenUrls.contains(widget.videoUrl);
      final showPlaceholder = _isFullScreenActive || 
                             widget.isTransitioning || 
                             (isUrlInFullscreen && !widget.isFullscreen);

      return isInitialized.value
          ? Center(
              child: AspectRatio(
                key: widget.videoKey,
                aspectRatio: _controller.value.aspectRatio,
                child: GestureDetector(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Hero(
                        tag: 'video-hero-${widget.videoUrl}',
                        child: showPlaceholder
                            ? HandledCachedNetworkImage(
                                widget.thumbnailUrl.isNotEmpty ? widget.thumbnailUrl : widget.videoUrl,
                                fit: BoxFit.cover,
                              )
                            : VideoPlayer(_controller),
                      ),
                      if (widget.showProgress)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.red,
                              bufferedColor: Colors.grey,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            NeomVideoPlayer.isGlobalMuted.toggle();
                          },
                          child: Obx(() => CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: Icon(
                              NeomVideoPlayer.isGlobalMuted.value ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 20,
                            ),
                          )),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (NeomVideoPlayer.isGlobalMuted.value) {
                      NeomVideoPlayer.isGlobalMuted.value = false;
                    }
                    setState(() => _isFullScreenActive = true);
                    await Sint.to(() => FullScreenVideoPage(controller: _controller),
                        transition: Transition.zoom);
                    if (mounted) setState(() => _isFullScreenActive = false);
                  },
                ),
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                HandledCachedNetworkImage(widget.thumbnailUrl.isNotEmpty ? widget.thumbnailUrl : widget.videoUrl),
                const Center(child: CircularProgressIndicator()),
              ],
            );
    });
  }
}
