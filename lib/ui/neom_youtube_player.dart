import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
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
    super.key,
  });

  @override
  State<NeomYoutubePlayer> createState() => _NeomYoutubePlayerState();
}

class _NeomYoutubePlayerState extends State<NeomYoutubePlayer> {
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
        ),
      );
      _registerMediaController();
    }
    NeomYoutubePlayer._players
        .putIfAbsent(widget.youtubeUrl, () => [])
        .add(this);
  }

  void _registerMediaController() {
    if (controller != null && Sint.isRegistered<MediaPlayerController>()) {
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
    if (oldWidget.youtubeUrl != widget.youtubeUrl) {
      _releasePlayer(oldWidget.youtubeUrl);
      _initializePlayer();
    } else if (oldWidget.youtubeKey != widget.youtubeKey) {
      _registerMediaController();
    }
  }

  @override
  void dispose() {
    _muteSubscription?.cancel();
    _releasePlayer(widget.youtubeUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (videoId.isEmpty) return const SizedBox.shrink();
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
          : YoutubePlayer(
              key: ObjectKey(controller),
              controller: controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.blueAccent,
              topActions: <Widget>[
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    controller!.metadata.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18.0),
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
              onReady: () => _mediaController?.visibleVideoAction(),
            ),
    );
  }
}
