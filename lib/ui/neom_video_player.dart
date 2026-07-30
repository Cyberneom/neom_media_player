import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_core/domain/use_cases/audio_handler_service.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/data/firestore/post_firestore.dart';
import 'package:neom_core/domain/use_cases/timeline_service.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter/services.dart';

import 'full_screen/full_screen_video_page.dart';
import 'media_player_controller.dart';
import 'video_controls_overlay.dart';
import 'video_url_helper_stub.dart'
    if (dart.library.html) 'video_url_helper_web.dart';

class NeomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final bool showProgress;
  final GlobalKey? videoKey; // ✅ Nuevo parámetro opcional para la clave única
  final bool isFullscreen;
  final void Function(VideoPlayerController)? onFullScreenTap;
  final Post? post; // ✅ Objeto de publicación para auto-curar la relación de aspecto

  // Global mute state shared across all instances
  static final RxBool isGlobalMuted = true.obs;

  // Track active fullscreen video URLs to prevent double rendering inline
  static final RxSet<String> _fullscreenUrls = <String>{}.obs;

  final bool isTransitioning;

  // Static cache to keep video controllers alive and reuse them on Web
  static final Map<String, VideoPlayerController> _webVideoCache = {};
  static final Map<String, int> _webVideoRefCount = {};

  static VideoPlayerController? getVideoController(String url) {
    return _webVideoCache[url];
  }

  static void preloadVideo(String url) {
    if (Sint.isRegistered<MediaPlayerController>()) {
      Sint.find<MediaPlayerController>().preloadLazyPlayer(url);
    }
  }

  final VideoPlayerController? controller;

  const NeomVideoPlayer({
    required this.videoUrl,
    this.videoKey,
    this.showProgress = true,
    this.thumbnailUrl = '',
    this.isFullscreen = false,
    this.onFullScreenTap,
    this.isTransitioning = false,
    this.post,
    this.controller,
    super.key,
  });

  @override
  State<NeomVideoPlayer> createState() => _NeomVideoPlayerState();
}

class _NeomVideoPlayerState extends State<NeomVideoPlayer> {
  late GlobalKey _videoKey;
  late VideoPlayerController _controller;
  final isInitialized = false.obs;
  final isControllerCreated = false.obs;
  final hasError = false.obs;
  bool _isFullScreenActive = false;
  dynamic _muteSubscription;
  bool _isControllerLocal = true;
  bool _isInitializing = false;

  void _pauseMusicPlayer() {
    if (Sint.isRegistered<AudioHandlerService>()) {
      final audioHandler = Sint.find<AudioHandlerService>();
      if (audioHandler.isPlaying) {
        audioHandler.pause();
        audioHandler.stoppedByVideo = true;
      }
    }
  }

  Widget _buildPlaceholder(BoxFit fit) {
    final lowerUrl = widget.thumbnailUrl.toLowerCase();
    final hasThumbnail = widget.thumbnailUrl.isNotEmpty &&
        !lowerUrl.contains('.mp4') &&
        !lowerUrl.contains('.mov') &&
        !lowerUrl.contains('.m4v') &&
        !lowerUrl.contains('.3gp') &&
        !lowerUrl.contains('.mkv');

    return hasThumbnail
        ? HandledCachedNetworkImage(widget.thumbnailUrl, fit: fit)
        : Container(
            color: Colors.black87,
            child: const Center(
              child: Icon(
                Icons.movie_creation_outlined,
                color: Colors.white24,
                size: 48,
              ),
            ),
          );
  }

  void initializePlayer() {
    if (isInitialized.value || hasError.value) return;
    _initializeController();
  }

  void _videoPlayerListener() {
    if (mounted && _controller.value.isPlaying && !NeomVideoPlayer.isGlobalMuted.value) {
      _pauseMusicPlayer();
    }
  }

  void _initializeController() {
    if (isInitialized.value || hasError.value || _isInitializing) return;
    _isInitializing = true;

    final cached = NeomVideoPlayer._webVideoCache[widget.videoUrl];
    if (kIsWeb && cached != null) {
      _controller = cached;
      isControllerCreated.value = true;
      _isControllerLocal = true;
      _controller.removeListener(_videoPlayerListener);
      _controller.addListener(_videoPlayerListener);

      // Increment reference count
      NeomVideoPlayer._webVideoRefCount[widget.videoUrl] =
          (NeomVideoPlayer._webVideoRefCount[widget.videoUrl] ?? 0) + 1;

      isInitialized.value = _controller.value.isInitialized;
      _isInitializing = false; // Reset flag since cache is already loaded/loading

      if (isInitialized.value) {
        _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
        _healPostAspectRatio(_controller.value.aspectRatio);
      } else {
        _controller.initialize().timeout(const Duration(seconds: 10)).then((_) {
          isInitialized.value = true;
          if (mounted) {
            _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
            _healPostAspectRatio(_controller.value.aspectRatio);
          }
        }).catchError((error) {
          print('NeomVideoPlayer: Failed to initialize cached video: $error');
          if (mounted) {
            hasError.value = true;
          }
        });
      }
    } else {
      getPlayableVideoUrl(widget.videoUrl).then((playableUrl) {
        if (!mounted) {
          _isInitializing = false;
          return;
        }
        _controller = VideoPlayerController.networkUrl(Uri.parse(playableUrl));
        isControllerCreated.value = true;
        _controller.removeListener(_videoPlayerListener);
        _controller.addListener(_videoPlayerListener);
        if (kIsWeb) {
          _controller.setVolume(0);
        }
        _controller.initialize().timeout(const Duration(seconds: 15)).then((_) {
          isInitialized.value = true;
          _isInitializing = false;
          _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
          _healPostAspectRatio(_controller.value.aspectRatio);

          if (Sint.isRegistered<MediaPlayerController>()) {
            final mediaPlayerController = Sint.find<MediaPlayerController>();
            mediaPlayerController.registerVideoKeyController(widget.videoUrl, _videoKey, _controller);
          } else {
            _controller.play(); // ▶️ Reproducir automáticamente
          }
        }).catchError((error) {
          print('NeomVideoPlayer: Failed to initialize video or timed out: $error');
          if (mounted) {
            // Web Fallback: Try playing via Blob URL if direct URL fails (e.g. CORS)
            if (kIsWeb && !playableUrl.startsWith('blob:')) {
              print('NeomVideoPlayer: Direct URL failed, trying Blob URL fallback...');
              getBlobFallbackUrl(widget.videoUrl).then((blobUrl) {
                if (!mounted) {
                  _isInitializing = false;
                  return;
                }
                // Dispose previous failed controller to prevent leak
                _controller.dispose();

                _controller = VideoPlayerController.networkUrl(Uri.parse(blobUrl));
                if (kIsWeb) {
                  NeomVideoPlayer._webVideoCache[widget.videoUrl] = _controller;
                }
                _controller.removeListener(_videoPlayerListener);
                _controller.addListener(_videoPlayerListener);
                _controller.setVolume(0);

                _controller.initialize().timeout(const Duration(seconds: 15)).then((_) {
                  isInitialized.value = true;
                  _isInitializing = false;
                  _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
                  _healPostAspectRatio(_controller.value.aspectRatio);

                  if (Sint.isRegistered<MediaPlayerController>()) {
                    Sint.find<MediaPlayerController>().registerVideoKeyController(widget.videoUrl, _videoKey, _controller);
                  } else {
                    _controller.play();
                  }
                }).catchError((blobError) {
                  print('NeomVideoPlayer: Fallback Blob URL also failed: $blobError');
                  isInitialized.value = false;
                  _isInitializing = false;
                  hasError.value = true;
                });
              }).catchError((_) {
                _isInitializing = false;
                hasError.value = true;
              });
            } else {
              _isInitializing = false;
              hasError.value = true;
            }
          } else {
            _isInitializing = false;
          }
        });
        if (kIsWeb) {
          NeomVideoPlayer._webVideoCache[widget.videoUrl] = _controller;
          NeomVideoPlayer._webVideoRefCount[widget.videoUrl] = 1;
        }
      }).catchError((error) {
        print('NeomVideoPlayer: Error getting playable URL: $error');
        if (mounted) {
          hasError.value = true;
        }
        _isInitializing = false;
      });
    }
  }

  void _safeSetRxBool(RxBool rx, bool value) {
    if (rx.value != value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) rx.value = value;
      });
    }
  }

  void _safeAddFullscreenUrl(String url) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NeomVideoPlayer._fullscreenUrls.add(url);
    });
  }

  void _safeRemoveFullscreenUrl(String url) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NeomVideoPlayer._fullscreenUrls.remove(url);
    });
  }

  @override
  void initState() {
    super.initState();
    _videoKey = widget.videoKey ?? GlobalKey();
    if (widget.isFullscreen) {
      _safeAddFullscreenUrl(widget.videoUrl);
    }

    if (widget.controller != null) {
      _controller = widget.controller!;
      _isControllerLocal = false;
      _safeSetRxBool(isControllerCreated, true);
      _controller.removeListener(_videoPlayerListener);
      _controller.addListener(_videoPlayerListener);
      _safeSetRxBool(isInitialized, _controller.value.isInitialized);
      if (_controller.value.isInitialized) {
        _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
        _healPostAspectRatio(_controller.value.aspectRatio);
      } else {
        _controller.initialize().timeout(const Duration(seconds: 15)).then((_) {
          if (mounted) {
            isInitialized.value = true;
            _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
            _healPostAspectRatio(_controller.value.aspectRatio);
          }
        }).catchError((e) {
          print('NeomVideoPlayer: Failed to initialize external controller: $e');
        });
      }
      if (Sint.isRegistered<MediaPlayerController>()) {
        Sint.find<MediaPlayerController>().registerVideoKeyController(widget.videoUrl, _videoKey, _controller);
      }
    } else {
      final cached = kIsWeb ? NeomVideoPlayer._webVideoCache[widget.videoUrl] : null;
      if (cached != null && cached.value.isInitialized) {
        _controller = cached;
        _safeSetRxBool(isControllerCreated, true);
        _isControllerLocal = true;
        if (kIsWeb) {
          NeomVideoPlayer._webVideoRefCount[widget.videoUrl] =
              (NeomVideoPlayer._webVideoRefCount[widget.videoUrl] ?? 0) + 1;
        }
        _controller.removeListener(_videoPlayerListener);
        _controller.addListener(_videoPlayerListener);
        _safeSetRxBool(isInitialized, true);
        _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
        _healPostAspectRatio(_controller.value.aspectRatio);

        if (Sint.isRegistered<MediaPlayerController>()) {
          Sint.find<MediaPlayerController>().registerVideoKeyController(widget.videoUrl, _videoKey, _controller);
        }
      } else {
        if (Sint.isRegistered<MediaPlayerController>()) {
          final mediaPlayerController = Sint.find<MediaPlayerController>();
          mediaPlayerController.registerLazyPlayer(widget.videoUrl, this, _videoKey);
        } else {
          _initializeController();
        }
      }
    }

    _muteSubscription = NeomVideoPlayer.isGlobalMuted.listen((muted) {
      if (mounted && isInitialized.value) {
        _controller.setVolume(muted ? 0 : 1);
        if (!muted && _controller.value.isPlaying) {
          _pauseMusicPlayer();
        }
      }
    });
  }

  void _healPostAspectRatio(double realRatio) async {
    if (widget.post != null) {
      final oldRatio = widget.post!.aspectRatio;
      if (oldRatio == 1.0 || oldRatio == 0.0) {
        if ((realRatio - 1.0).abs() > 0.05) {
          widget.post!.aspectRatio = realRatio;
          AppConfig.logger.d("Healed aspect ratio in memory for post ${widget.post!.id} to $realRatio");

          try {
            await PostFirestore().updateFields(widget.post!.id, {'aspectRatio': realRatio});
            AppConfig.logger.d("Healed aspect ratio in Firestore for post ${widget.post!.id} to $realRatio");
          } catch (e, st) {
            NeomErrorLogger.recordError(e, st, module: 'neom_media_player', operation: 'healPostAspectRatioFirestore');
          }

          if (Sint.isRegistered<TimelineService>()) {
            final service = Sint.find<TimelineService>();
            try {
              (service as dynamic).update(['timeline']);
            } catch (e) {
              AppConfig.logger.w("Failed to call dynamic update on TimelineService: $e");
            }
          }
        }
      }
    }
  }

  void _cleanup(String url) {
    if (widget.isFullscreen) {
      _safeRemoveFullscreenUrl(url);
    }
    if (Sint.isRegistered<MediaPlayerController>()) {
      final mediaPlayerController = Sint.find<MediaPlayerController>();
      mediaPlayerController.unregisterVideoKeyController(url);
      mediaPlayerController.unregisterLazyPlayer(url);
    }
    if (isInitialized.value) {
      try {
        _controller.removeListener(_videoPlayerListener);
      } catch (_) {}
    }
    if (kIsWeb && _isControllerLocal && isControllerCreated.value) {
      // Decrement reference count
      final count = (NeomVideoPlayer._webVideoRefCount[url] ?? 1) - 1;
      NeomVideoPlayer._webVideoRefCount[url] = count;

      if (count <= 0) {
        NeomVideoPlayer._webVideoCache.remove(url);
        NeomVideoPlayer._webVideoRefCount.remove(url);
        _controller.dispose();
      }
    } else if (!kIsWeb && _isControllerLocal && isControllerCreated.value) {
      _controller.dispose();
    }
  }

  @override
  void dispose() {
    _cleanup(widget.videoUrl);
    _muteSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(NeomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoUrl != oldWidget.videoUrl) {
      _cleanup(oldWidget.videoUrl);

      // Reset state flags
      _safeSetRxBool(isInitialized, false);
      _safeSetRxBool(isControllerCreated, false);
      _safeSetRxBool(hasError, false);
      _isInitializing = false;
      _videoKey = widget.videoKey ?? GlobalKey();

      if (widget.isFullscreen) {
        _safeAddFullscreenUrl(widget.videoUrl);
      }

      if (widget.controller != null) {
        _controller = widget.controller!;
        _isControllerLocal = false;
        isControllerCreated.value = true;
        _controller.removeListener(_videoPlayerListener);
        _controller.addListener(_videoPlayerListener);
        isInitialized.value = _controller.value.isInitialized;
        if (isInitialized.value) {
          _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
          _healPostAspectRatio(_controller.value.aspectRatio);
        } else {
          _controller.initialize().timeout(const Duration(seconds: 15)).then((_) {
            isInitialized.value = true;
            _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
            _healPostAspectRatio(_controller.value.aspectRatio);
          }).catchError((e) {
            print('NeomVideoPlayer: Failed to initialize external controller in didUpdateWidget: $e');
          });
        }
        if (Sint.isRegistered<MediaPlayerController>()) {
          Sint.find<MediaPlayerController>().registerVideoKeyController(widget.videoUrl, _videoKey, _controller);
        }
      } else {
        _isControllerLocal = true;
        final cached = kIsWeb ? NeomVideoPlayer._webVideoCache[widget.videoUrl] : null;
        if (cached != null && cached.value.isInitialized) {
          _controller = cached;
          isControllerCreated.value = true;
          _isControllerLocal = true;
          _controller.removeListener(_videoPlayerListener);
          _controller.addListener(_videoPlayerListener);
          isInitialized.value = true;
          
          // Increment reference count
          NeomVideoPlayer._webVideoRefCount[widget.videoUrl] =
              (NeomVideoPlayer._webVideoRefCount[widget.videoUrl] ?? 0) + 1;
              
          _controller.setVolume(NeomVideoPlayer.isGlobalMuted.value ? 0 : 1);
          _healPostAspectRatio(_controller.value.aspectRatio);

          if (Sint.isRegistered<MediaPlayerController>()) {
            Sint.find<MediaPlayerController>().registerVideoKeyController(widget.videoUrl, _videoKey, _controller);
          }
        } else {
          if (Sint.isRegistered<MediaPlayerController>()) {
            final mediaPlayerController = Sint.find<MediaPlayerController>();
            mediaPlayerController.registerLazyPlayer(widget.videoUrl, this, _videoKey);
          } else {
            _initializeController();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Obx(() {
        final isVertical = isInitialized.value && _controller.value.isInitialized && _controller.value.aspectRatio < 1.1;
        final fit = widget.isFullscreen
            ? BoxFit.contain
            : (isVertical ? BoxFit.contain : BoxFit.cover);

        final isUrlInFullscreen = NeomVideoPlayer._fullscreenUrls.contains(widget.videoUrl);
        final showPlaceholder = _isFullScreenActive || 
                               widget.isTransitioning || 
                               (isUrlInFullscreen && !widget.isFullscreen);

        if (hasError.value) {
          return SizedBox.expand(
            key: _videoKey,
            child: GestureDetector(
              onTap: widget.onFullScreenTap != null
                  ? () => widget.onFullScreenTap!(_controller)
                  : () async {
                      if (isInitialized.value) {
                        setState(() => _isFullScreenActive = true);
                        await Sint.to(() => FullScreenVideoPage(controller: _controller),
                            transition: Transition.zoom);
                        if (mounted) setState(() => _isFullScreenActive = false);
                      }
                    },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildPlaceholder(fit),
                  const CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 28,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
          );
        }

        final mountVideo = isInitialized.value;
        if (!mountVideo) {
          return SizedBox.expand(
            key: _videoKey,
            child: _buildPlaceholder(fit),
          );
        }

        return SizedBox.expand(
          key: _videoKey,
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && isInitialized.value) {
                if (event.logicalKey == LogicalKeyboardKey.space) {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
                  NeomVideoPlayer.isGlobalMuted.toggle();
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
                  if (widget.onFullScreenTap != null) {
                    widget.onFullScreenTap!(_controller);
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  final newPosition = _controller.value.position - const Duration(seconds: 5);
                  _controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  final newPosition = _controller.value.position + const Duration(seconds: 5);
                  _controller.seekTo(newPosition > _controller.value.duration ? _controller.value.duration : newPosition);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: VideoPlayer(_controller),
                ),
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    final showLoading = !isInitialized.value;
                    if (showLoading) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildPlaceholder(fit),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      );
                    }
                    return showPlaceholder
                        ? SizedBox.expand(child: _buildPlaceholder(fit))
                        : const SizedBox.shrink();
                  },
                ),
                if (isInitialized.value)
                  Positioned.fill(
                    child: VideoControlsOverlay(
                      controller: _controller,
                      isFullscreen: widget.isFullscreen,
                      onFullScreenTap: widget.onFullScreenTap != null
                          ? () => widget.onFullScreenTap!(_controller)
                          : () async {
                              setState(() => _isFullScreenActive = true);
                              await Sint.to(() => FullScreenVideoPage(controller: _controller),
                                  transition: Transition.zoom);
                              if (mounted) setState(() => _isFullScreenActive = false);
                            },
                      onTap: () {
                        // handled inside overlay
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      });
    }

    return Obx(() {
      final isUrlInFullscreen = NeomVideoPlayer._fullscreenUrls.contains(widget.videoUrl);
      final showPlaceholder = _isFullScreenActive || 
                             widget.isTransitioning || 
                             (isUrlInFullscreen && !widget.isFullscreen);

      if (hasError.value) {
        return Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              onTap: () async {
                if (isInitialized.value) {
                  setState(() => _isFullScreenActive = true);
                  await Sint.to(() => FullScreenVideoPage(controller: _controller),
                      transition: Transition.zoom);
                  if (mounted) setState(() => _isFullScreenActive = false);
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildPlaceholder(BoxFit.cover),
                  const CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 28,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final mountVideo = isControllerCreated.value;
      if (!mountVideo) {
        return Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlaceholder(BoxFit.cover),
          ),
        );
      }

      return Center(
        child: AspectRatio(
          key: _videoKey,
          aspectRatio: isInitialized.value ? _controller.value.aspectRatio : 16 / 9,
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && isInitialized.value) {
                if (event.logicalKey == LogicalKeyboardKey.space) {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: 'video-hero-${widget.videoUrl}',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isInitialized.value)
                        VideoPlayer(_controller)
                      else
                        SizedBox.expand(child: VideoPlayer(_controller)),
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _controller,
                        builder: (context, value, child) {
                          final showLoading = !isInitialized.value;
                          if (showLoading) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildPlaceholder(BoxFit.cover),
                                const Center(child: CircularProgressIndicator()),
                              ],
                            );
                          }
                          return showPlaceholder
                              ? _buildPlaceholder(BoxFit.cover)
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                if (isInitialized.value)
                  Positioned.fill(
                    child: VideoControlsOverlay(
                      controller: _controller,
                      isFullscreen: widget.isFullscreen,
                      onFullScreenTap: widget.onFullScreenTap != null
                          ? () => widget.onFullScreenTap!(_controller)
                          : () async {
                              setState(() => _isFullScreenActive = true);
                              await Sint.to(() => FullScreenVideoPage(controller: _controller),
                                  transition: Transition.zoom);
                              if (mounted) setState(() => _isFullScreenActive = false);
                            },
                      onTap: () {
                         if (NeomVideoPlayer.isGlobalMuted.value) {
                           NeomVideoPlayer.isGlobalMuted.value = false;
                         }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
