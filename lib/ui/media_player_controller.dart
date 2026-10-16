import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/audio_handler_service.dart';
import 'package:neom_core/domain/use_cases/media_player_service.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:sint/sint.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'neom_video_player.dart';
import 'neom_youtube_player.dart';

class MediaPlayerController extends SintController implements MediaPlayerService {

  VideoPlayerController? videoPlayerController;
  Completer<void>? _videoInitializationCancelled;

  double _aspectRatio = 1;
  String mediaUrl = "";
  bool isInitialized = false;
  RxBool isPlaying = false.obs;

  double videoThreshold = 0.65; // 30% del widget visible para activar el video

  final Map<String, GlobalKey> _videoKeys = {}; // Nuevo mapa para almacenar claves de video
  final Map<String, String> _spotifyTrackImgUrls = {};
  final Map<String, GlobalKey> _youtubeKeys = {}; // Nuevo mapa para almacenar claves de video

  final Map<String, YoutubePlayerController> _youtubeControllers = {}; // Nuevo mapa para almacenar claves de video
  final Map<String, VideoPlayerController> _videoControllers = {}; // Nuevo mapa para almacenar claves de video

  final Map<String, dynamic> _lazyPlayers = {}; // Mapa para almacenar estados lazy
  final Map<String, GlobalKey> _lazyKeys = {}; // Mapa para almacenar claves lazy
  Timer? _visibleVideoTimer;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.d("MediaPlayer Controller Init");

    try {

    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_media_player', operation: 'onInit');
    }

  }

  @override
  Future<void> initializeVideoPlayerController(File file) async {
    AppConfig.logger.d("initializeVideoPlayerController");
    final previous = videoPlayerController;
    _videoInitializationCancelled?.complete();
    final cancelled = Completer<void>();
    _videoInitializationCancelled = cancelled;
    final next = VideoPlayerController.file(file as dynamic);
    // Publish ownership before awaiting disposal/initialization. An older open
    // may finish after a new selection or after this preview has been closed.
    videoPlayerController = next;
    isInitialized = false;
    isPlaying.value = false;
    _aspectRatio = 1;
    if (previous != null) {
      await Future.any<void>([_disposeVideoController(previous), cancelled.future]);
    }
    if (!identical(videoPlayerController, next)) return;
    try {
      await Future.any<void>([next.initialize(), cancelled.future]);
      if (!identical(videoPlayerController, next)) return;
      isInitialized = next.value.isInitialized;
      if (isInitialized) {
        final size = next.value.size;
        _aspectRatio = size.height > 0 ? size.width / size.height : 1;
        isPlaying.value = next.value.isPlaying;
      }
    } catch (e, st) {
      if (identical(videoPlayerController, next)) {
        videoPlayerController = null;
        isInitialized = false;
        isPlaying.value = false;
        _aspectRatio = 1;
        await _disposeVideoController(next);
      }
      NeomErrorLogger.recordError(e, st, module: 'neom_media_player', operation: 'initializeVideoPlayerController');
    }
  }

  Future<void> _disposeVideoController(VideoPlayerController controller) async {
    try {
      print("DISPOSE_START ${controller.playerId}");
      await controller.dispose();
      print("DISPOSE_END ${controller.playerId}");
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_media_player', operation: 'disposeVideoPlayer');
    }
  }

  @override
  Future<void> playPauseVideo() async {
    final controller = videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (!identical(videoPlayerController, controller)) return;
    isPlaying.value = controller.value.isPlaying;
    update();
  }

  ///DEPRECATED
  // @override
  // void setIsPlaying({bool value = true}) {
  //   if(isPlaying.value != value) {
  //     isPlaying.value = value;
  //     update();
  //   }
  // }

  @override
  void disposeVideoPlayer() {
    final previous = videoPlayerController;
    _videoInitializationCancelled?.complete();
    _videoInitializationCancelled = null;
    videoPlayerController = null;
    isInitialized = false;
    isPlaying.value = false;
    _aspectRatio = 1;
    // Uninitialized controllers can still own a pending native player. Release
    // them too; VideoPlayerController handles its own creation completion.
    if (previous != null) unawaited(_disposeVideoController(previous));
  }

  ///DEPRECATED
  // Widget getVideoPlayer() {
  //   AppConfig.logger.d("getVideoPlayer");
  //   return VideoPlayer(videoPlayerController!);
  // }

  @override
  Widget getVideoPlayerAspectRatio() {
    final controller = videoPlayerController;
    return isInitialized && controller != null && controller.value.isInitialized ? AspectRatio(
    aspectRatio: controller.value.aspectRatio,
    child: Stack(
          children: [
            VideoPlayer(controller),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26, // Sutil oscurecimiento para contraste
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isPlaying.value ? Icons.pause : Icons.play_arrow,
                    size: 50, // Icono más grande para mejor UX
                  ),
                  color: Colors.white.withValues(alpha: 0.8),
                  onPressed: () => playPauseVideo(),
                ),
              ),
            ),
          ]),
    ) : SizedBox.shrink();
  }

  @override
  bool get isVideoPlayerInitialized => isInitialized;

  @override
  bool get isVideoPlayerPlaying => isPlaying.value;

  @override
  double get aspectRatio => _aspectRatio;


  void registerLazyPlayer(String url, dynamic state, GlobalKey key) {
    _lazyPlayers[url] = state;
    _lazyKeys[url] = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      visibleVideoAction();
    });
  }

  void unregisterLazyPlayer(String url) {
    _lazyPlayers.remove(url);
    _lazyKeys.remove(url);
  }

  void preloadLazyPlayer(String url) {
    final playerState = _lazyPlayers[url];
    if (playerState != null) {
      try {
        (playerState as dynamic).initializePlayer();
      } catch (e) {
        AppConfig.logger.w("MediaPlayerController: Failed to call initializePlayer on lazy player: $e");
      }
    }
  }

  void registerVideoKeyController(String ytUrl, GlobalKey ytKey, VideoPlayerController ytController) {
    _lazyPlayers.remove(ytUrl);
    _lazyKeys.remove(ytUrl);
    _videoKeys[ytUrl] = ytKey;
    _videoControllers[ytUrl] = ytController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      visibleVideoAction();
    });
  }

  void unregisterVideoKeyController(String ytUrl) {
    _videoKeys.remove(ytUrl);
    _videoControllers.remove(ytUrl);
  }

  void registerYouTubeKeyController(String ytUrl, GlobalKey ytKey, YoutubePlayerController ytController) {
    _youtubeKeys[ytUrl] = ytKey;
    _youtubeControllers[ytUrl] = ytController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (identical(_youtubeControllers[ytUrl], ytController)) {
        visibleVideoAction();
      }
    });
  }

  void unregisterYouTubeKeyController(String url, YoutubePlayerController controller) {
    // A second card/modal can own a newer controller for the same URL.
    if (!identical(_youtubeControllers[url], controller)) return;
    _youtubeKeys.remove(url);
    _youtubeControllers.remove(url);
  }

  @override
  void onClose() {
    _visibleVideoTimer?.cancel();
    super.onClose();
  }

  @override
  void visibleVideoAction() {
    _visibleVideoTimer?.cancel();
    _visibleVideoTimer = Timer(const Duration(milliseconds: 150), () {
      _executeVisibleVideoAction();
    });
  }

  void _executeVisibleVideoAction() {
    try {
      final isMusicPlaying = Sint.find<AudioHandlerService>().isPlaying;
      if (!isMusicPlaying && _lazyKeys.isNotEmpty) {
        final lazyUrls = _lazyKeys.keys.toList();
        for (final keyUrl in lazyUrls) {
          final entry = _lazyKeys[keyUrl];
          if (entry == null) continue;

          final context = entry.currentContext;
          if (context == null) continue;

          final renderObject = context.findRenderObject();
          if (renderObject == null || !renderObject.attached || renderObject is! RenderBox) continue;

          final RenderBox renderBox = renderObject;
          final position = renderBox.localToGlobal(Offset.zero);
          final videoSize = renderBox.size;

          final screenHeight = MediaQuery.of(Sint.context!).size.height;
          final screenWidth = MediaQuery.of(Sint.context!).size.width;

          // Eagerly initialize lazy videos that are on screen or near viewport (buffer of 400px)
          final isNearY = position.dy + videoSize.height > -400 && position.dy < screenHeight + 400;
          final isNearX = position.dx + videoSize.width > -400 && position.dx < screenWidth + 400;

          if (isNearY && isNearX) {
            final playerState = _lazyPlayers[keyUrl];
            if (playerState != null) {
              AppConfig.logger.t('NeomVideoPlayer: Lazy initializing visible video: $keyUrl');
              playerState.initializePlayer();
            }
          }
        }
      }

      _handleVideoVisibility(_videoKeys, _videoControllers);
      _handleVideoVisibility(_youtubeKeys, _youtubeControllers);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st, module: 'neom_media_player', operation: 'visibleVideoAction');
    }
  }

  void _handleVideoVisibility<T>(Map<String, GlobalKey> keys, Map<String, T> controllers) {
    final isMusicPlaying = Sint.isRegistered<AudioHandlerService>() &&
        Sint.find<AudioHandlerService>().isPlaying;
    if (isMusicPlaying) {
      pauseAllVideos();
      return;
    }

    final screenHeight = MediaQuery.of(Sint.context!).size.height;
    final screenWidth = MediaQuery.of(Sint.context!).size.width;

    String? bestKeyUrl;
    double minDistanceSq = double.infinity;

    // Step 1: Find the single video closest to the center of the viewport
    for (int i = 0; i < keys.length; i++) {
      final keyUrl = keys.keys.elementAt(i);
      final entry = keys.values.elementAt(i);

      final context = entry.currentContext;
      if (context == null) continue;

      final renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.attached || renderObject is! RenderBox) continue;

      final RenderBox renderBox = renderObject;
      final position = renderBox.localToGlobal(Offset.zero);
      final videoSize = renderBox.size;

      final videoCenterY = position.dy + (videoSize.height / 2);
      final videoCenterX = position.dx + (videoSize.width / 2);

      final dy = videoCenterY - (screenHeight / 2);
      final dx = videoCenterX - (screenWidth / 2);

      final isVisibleY = dy.abs() < (screenHeight * 0.45);
      final isVisibleX = dx.abs() < (screenWidth * 0.45);

      if (isVisibleY && isVisibleX) {
        final distSq = (dx * dx) + (dy * dy);
        if (distSq < minDistanceSq) {
          minDistanceSq = distSq;
          bestKeyUrl = keyUrl;
        }
      }
    }

    // Step 2: Play ONLY the best video, pause all other videos to prevent contention & audio clashes
    for (int i = 0; i < keys.length; i++) {
      final keyUrl = keys.keys.elementAt(i);
      final controller = controllers[keyUrl];
      if (controller == null) continue;

      final shouldPlay = (keyUrl == bestKeyUrl);

      if (controller is VideoPlayerController) {
        if (shouldPlay && !controller.value.isPlaying) {
          AppConfig.logger.d('NeomVideoPlayer: Play single active video for keyUrl=$keyUrl');
          controller.play();
        } else if (!shouldPlay && controller.value.isPlaying) {
          AppConfig.logger.d('NeomVideoPlayer: Pause inactive video for keyUrl=$keyUrl');
          controller.pause();
        }
      } else if (controller is YoutubePlayerController) {
        if (shouldPlay && !controller.value.isPlaying) {
          AppConfig.logger.d('NeomVideoPlayer: Play single active YouTube for keyUrl=$keyUrl');
          controller.play();
        } else if (!shouldPlay && controller.value.isPlaying) {
          AppConfig.logger.d('NeomVideoPlayer: Pause inactive YouTube for keyUrl=$keyUrl');
          controller.pause();
        }
      }
    }
  }

  @override
  Map<String, String> get spotifyTrackImgUrls => _spotifyTrackImgUrls;

  @override
  Map<String, GlobalKey<State<StatefulWidget>>> get videoKeys => _videoKeys;

  @override
  Map<String, GlobalKey<State<StatefulWidget>>> get youtubeKeys => _youtubeKeys;

  @override
  void muteVideoPlayer() {
    NeomVideoPlayer.isGlobalMuted.value = true;
  }

  @override
  void pauseAllVideos({dynamic except}) {
    AppConfig.logger.d("MediaPlayerController: pauseAllVideos");
    for (final controller in _videoControllers.values) {
      if (controller != except && controller.value.isInitialized && controller.value.isPlaying) {
        controller.pause();
      }
    }
    for (final ytController in _youtubeControllers.values) {
      if (ytController != except && ytController.value.isPlaying) {
        ytController.pause();
      }
    }
    NeomYoutubePlayer.pauseAll();
    if (videoPlayerController != null && videoPlayerController != except) {
      if (videoPlayerController!.value.isInitialized && videoPlayerController!.value.isPlaying) {
        videoPlayerController!.pause();
      }
    }
    NeomVideoPlayer.pauseAllExcept(except is VideoPlayerController ? except : null);
    isPlaying.value = false;
  }
}
