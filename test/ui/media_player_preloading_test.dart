import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_media_player/ui/media_player_controller.dart';
import 'package:sint/sint.dart';

class FakeLazyPlayerState {
  bool isInitialized = false;

  void initializePlayer() {
    isInitialized = true;
  }
}

void main() {
  group('MediaPlayerController Preloading Tests', () {
    setUp(() {
      Sint.reset();
    });

    test('Lazy player preloading registration and initialization', () {
      final controller = Sint.put(MediaPlayerController());
      final fakePlayer = FakeLazyPlayerState();
      final key = GlobalKey();
      const testUrl = 'https://example.com/video.mp4';

      controller.registerLazyPlayer(testUrl, fakePlayer, key);

      // Verify that calling preloadLazyPlayer triggers initialization
      controller.preloadLazyPlayer(testUrl);
      expect(fakePlayer.isInitialized, isTrue);
    });
  });
}
