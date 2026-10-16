import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:neom_media_player/ui/media_player_controller.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class PreviewPlatform extends VideoPlayerPlatform {
  final streams = <int, StreamController<VideoEvent>>{};
  final disposals = <int>[];
  final createWaiters = <int, Completer<void>>{};
  bool holdCreation = false;
  @override
  Future<void> init() async {}
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    final id = streams.length;
    streams[id] = StreamController<VideoEvent>();
    if (holdCreation) {
      final pending = createWaiters[id] = Completer<void>();
      await pending.future;
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;
  @override
  Future<void> dispose(int playerId) async {
    disposals.add(playerId);
  }

  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool prevent,
  ) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  void initialized(int id, Size size) => streams[id]!.add(
    VideoEvent(
      eventType: VideoEventType.initialized,
      size: size,
      duration: const Duration(seconds: 3),
    ),
  );
}

void main() {
  late PreviewPlatform platform;
  late VideoPlayerPlatform previous;
  late MediaPlayerController media;
  setUp(() {
    previous = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = platform = PreviewPlatform();
    media = MediaPlayerController();
  });
  tearDown(() async {
    media.disposeVideoPlayer();
    await Future<void>.delayed(Duration.zero);
    VideoPlayerPlatform.instance = previous;
  });

  testWidgets('replacing a playing preview disposes the old native player', (
    tester,
  ) async {
    final first = media.initializeVideoPlayerController(File('/source.mp4'));
    await tester.pump();
    platform.initialized(0, const Size(100, 200));
    await tester.pump();
    await first;
    await media.playPauseVideo();
    expect(media.isVideoPlayerPlaying, isTrue);
    final old = media.videoPlayerController;
    final next = media.initializeVideoPlayerController(File('/render.mp4'));
    expect(media.isInitialized, isFalse);
    expect(media.isVideoPlayerPlaying, isFalse);
    expect(media.videoPlayerController, isNot(same(old)));
    for (var i = 0; i < 20 && !platform.streams.containsKey(1); i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    print("STATE streams=${platform.streams.keys} old=${old?.playerId} current=${media.videoPlayerController?.playerId} listeners=${platform.streams[0]?.hasListener}");
    expect(platform.disposals, [0]);
    platform.initialized(1, const Size(300, 100));
    await tester.pump();
    await next;
    expect(media.isInitialized, isTrue);
    expect(media.aspectRatio, 3);
    media.disposeVideoPlayer();
    expect(media.isInitialized, isFalse);
    expect(media.isVideoPlayerPlaying, isFalse);
    expect(media.videoPlayerController, isNull);
    await tester.pump();
    expect(platform.disposals, [0, 1]);
  });

  testWidgets(
    'closing an uninitialized preview cancels await and releases its eventual native player',
    (tester) async {
      platform.holdCreation = true;
      var finished = false;
      final opening = media
          .initializeVideoPlayerController(File('/slow.mp4'))
          .then((_) {
            finished = true;
          });
      await tester.pump();
      media.disposeVideoPlayer();
      await tester.pump();
      expect(finished, isTrue);
      await opening;
      platform.createWaiters[0]!.complete();
      await tester.pump();
      expect(platform.disposals, [0]);
      expect(media.videoPlayerController, isNull);
      expect(media.isInitialized, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => media.getVideoPlayerAspectRatio(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a stale initialization cannot replace the newer preview state', (
    tester,
  ) async {
    platform.holdCreation = true;
    final first = media.initializeVideoPlayerController(File('/first.mp4'));
    await tester.pump();
    final second = media.initializeVideoPlayerController(File('/second.mp4'));
    final selected = media.videoPlayerController;
    await tester.pump();
    await first;
    platform.createWaiters[0]!.complete();
    await tester.pump();
    platform.createWaiters[1]!.complete();
    await tester.pump();
    platform.initialized(1, const Size(400, 100));
    await tester.pump();
    await second;
    expect(media.videoPlayerController, same(selected));
    expect(media.aspectRatio, 4);
    expect(media.isInitialized, isTrue);
    expect(platform.disposals, [0]);
  });
}
