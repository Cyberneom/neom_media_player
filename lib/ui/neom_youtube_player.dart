import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../utils/youtube_url.dart';
import 'media_player_controller.dart';
import 'neom_video_player.dart';
import 'youtube/youtube_web_controller.dart';
import 'youtube/youtube_web_player_stub.dart'
    if (dart.library.js_interop) 'youtube/youtube_web_player.dart';

class NeomYoutubePlayer extends StatefulWidget {
  final String youtubeUrl;
  final GlobalKey? youtubeKey;

  /// Android composition choice. The default preserves ordinary feed playback.
  /// Texture composition permits transformed/offscreen Flutter surfaces; it
  /// still needs validation on the target Android WebView and GPU backend.
  final bool useHybridComposition;

  /// Standalone surfaces own their playback instead of feed visibility rules.
  final bool registerWithMediaController;

  /// A host can provide its own visible transport controls.
  final bool showControls;

  /// Leaves keyboard focus with the native player's host, for example a VR rig.
  /// The WebView releases focus before [onControllerReady] and after app resume.
  /// This is opt-in and does not affect the browser player.
  final bool passiveFocus;

  /// Called for this native instance, avoiding URL-based controller lookups.
  /// The player retains ownership and disposes the controller on removal.
  final ValueChanged<YoutubePlayerController>? onControllerReady;

  static final Map<String, List<_NeomYoutubePlayerState>> _players = {};

  /// Retained for native callers. Browser controls use [play] and [pause].
  static YoutubePlayerController? getYoutubeController(String url) {
    return _players[url]?.last.controller;
  }

  static void play(String url) => _players[url]?.last._play();

  static void pause(String url) => _players[url]?.last._pause();

  static void pauseAll() {
    for (final list in _players.values) {
      for (final state in list) {
        state._pause();
      }
    }
  }

  const NeomYoutubePlayer({
    required this.youtubeUrl,
    this.youtubeKey,
    this.useHybridComposition = true,
    this.registerWithMediaController = true,
    this.showControls = true,
    this.passiveFocus = false,
    this.onControllerReady,
    super.key,
  });

  @override
  State<NeomYoutubePlayer> createState() => _NeomYoutubePlayerState();
}

class _NeomYoutubePlayerState extends State<NeomYoutubePlayer>
    with WidgetsBindingObserver {
  final GlobalKey _localYoutubeKey = GlobalKey();
  GlobalKey get _youtubeKey => widget.youtubeKey ?? _localYoutubeKey;
  YoutubePlayerController? controller;
  YoutubeWebController? _webController;
  MediaPlayerController? _mediaController;
  String videoId = '';
  StreamSubscription<bool>? _muteSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
    _muteSubscription = NeomVideoPlayer.isGlobalMuted.listen((muted) {
      _webController?.setMuted(muted);
      if (muted) {
        controller?.mute();
      } else {
        controller?.unMute();
      }
    });
  }

  void _initializePlayer() {
    videoId = youtubeVideoId(widget.youtubeUrl) ?? '';
    if (videoId.isEmpty) return;

    if (kIsWeb) {
      _webController = YoutubeWebController(
        muted: NeomVideoPlayer.isGlobalMuted.value,
      );
    } else {
      controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: false,
          mute: NeomVideoPlayer.isGlobalMuted.value,
          useHybridComposition: widget.useHybridComposition,
          hideControls: !widget.showControls,
        ),
      );
      _registerMediaController();
    }
    NeomYoutubePlayer._players
        .putIfAbsent(widget.youtubeUrl, () => [])
        .add(this);
  }

  void _registerMediaController() {
    if (widget.registerWithMediaController &&
        controller != null &&
        Sint.isRegistered<MediaPlayerController>()) {
      _mediaController = Sint.find<MediaPlayerController>();
      _mediaController!.registerYouTubeKeyController(
        widget.youtubeUrl,
        _youtubeKey,
        controller!,
      );
    }
  }

  void _play() {
    NeomVideoPlayer.pauseAllExcept(null);
    for (final list in NeomYoutubePlayer._players.values) {
      for (final state in list) {
        if (!identical(state, this)) {
          state._pause();
        }
      }
    }
    _webController?.playMuted();
    controller?.play();
  }

  void _pause() {
    _webController?.pause();
    controller?.pause();
  }

  bool _isCurrentController(YoutubePlayerController player) =>
      mounted && identical(controller, player);

  /// Returns false if disposal or replacement makes this operation stale.
  Future<bool> _releaseNativeFocus(YoutubePlayerController player) async {
    if (!_isCurrentController(player) || !widget.passiveFocus) return false;
    final webView = player.value.webViewController;
    if (webView == null) return true;

    bool isCurrent() =>
        _isCurrentController(player) &&
        widget.passiveFocus &&
        identical(player.value.webViewController, webView);

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final settings = await webView.getSettings();
        if (!isCurrent()) return false;
        if (settings != null) {
          // Preserve the player's other WebView settings.
          settings.needInitialFocus = false;
          await webView.setSettings(settings: settings);
        }
      } catch (error) {
        debugPrint(
          'NeomYoutubePlayer: could not disable initial focus: $error',
        );
      }
    }
    if (!isCurrent()) return false;
    try {
      // Also resets Android texture composition's input connection to Flutter.
      await webView.clearFocus();
    } catch (error) {
      debugPrint('NeomYoutubePlayer: could not clear native focus: $error');
    }
    return isCurrent();
  }

  Future<void> _onNativeReady(YoutubePlayerController player) async {
    if (!_isCurrentController(player)) return;
    if (widget.passiveFocus && !await _releaseNativeFocus(player)) return;
    if (!_isCurrentController(player)) return;
    _mediaController?.visibleVideoAction();
    widget.onControllerReady?.call(player);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final player = controller;
    if (state == AppLifecycleState.resumed &&
        widget.passiveFocus &&
        player != null) {
      unawaited(_releaseNativeFocus(player));
    }
  }

  void _releasePlayer(String url) {
    final players = NeomYoutubePlayer._players[url];
    final wasActive = players?.lastOrNull == this;
    players?.remove(this);
    if (players?.isEmpty ?? false) NeomYoutubePlayer._players.remove(url);

    final oldController = controller;
    if (oldController != null) {
      _mediaController?.unregisterYouTubeKeyController(url, oldController);
      oldController.dispose();
    }
    controller = null;
    _mediaController = null;
    _webController?.detach();
    _webController = null;
    if (wasActive && players != null && players.isNotEmpty) {
      players.last._registerMediaController();
    }
  }

  @override
  void didUpdateWidget(covariant NeomYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.youtubeUrl != widget.youtubeUrl ||
        oldWidget.useHybridComposition != widget.useHybridComposition ||
        oldWidget.showControls != widget.showControls ||
        oldWidget.passiveFocus != widget.passiveFocus ||
        oldWidget.registerWithMediaController !=
            widget.registerWithMediaController) {
      _releasePlayer(oldWidget.youtubeUrl);
      _initializePlayer();
    } else if (oldWidget.youtubeKey != widget.youtubeKey) {
      _registerMediaController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _muteSubscription?.cancel();
    _releasePlayer(widget.youtubeUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (videoId.isEmpty) return const SizedBox.shrink();
    final player = controller;
    return KeyedSubtree(
      key: _youtubeKey,
      child: kIsWeb
          ? AspectRatio(
              aspectRatio: 16 / 9,
              child: buildYoutubeWebPlayer(
                videoId: videoId,
                muted: NeomVideoPlayer.isGlobalMuted.value,
                controller: _webController!,
              ),
            )
          : ExcludeFocus(
              excluding: widget.passiveFocus,
              child: YoutubePlayer(
                key: ObjectKey(player),
                controller: player!,
                showVideoProgressIndicator: widget.showControls,
                progressIndicatorColor: Colors.blueAccent,
                topActions: <Widget>[
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      player.metadata.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                ],
                bottomActions: [
                  const SizedBox(width: 10),
                  CurrentPosition(),
                  ProgressBar(isExpanded: true),
                  RemainingDuration(),
                  const SizedBox(width: 10),
                ],
                onReady: () => unawaited(_onNativeReady(player)),
              ),
            ),
    );
  }
}
