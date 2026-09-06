import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_media_player/ui/media_player_controller.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  testWidgets(
    'removing an old card preserves the newer controller for its URL',
    (tester) async {
      const url = 'https://youtu.be/sExubGCaFOI';
      final media = MediaPlayerController();
      final first = YoutubePlayerController(initialVideoId: 'sExubGCaFOI');
      final second = YoutubePlayerController(initialVideoId: 'sExubGCaFOI');
      final firstKey = GlobalKey();
      final secondKey = GlobalKey();

      media.registerYouTubeKeyController(url, firstKey, first);
      media.registerYouTubeKeyController(url, secondKey, second);
      media.unregisterYouTubeKeyController(url, first);
      expect(media.youtubeKeys[url], same(secondKey));

      media.unregisterYouTubeKeyController(url, second);
      expect(media.youtubeKeys, isEmpty);
      first.dispose();
      second.dispose();
      await tester.pump();
      expect(tester.takeException(), isNull);
      media.onClose();
    },
  );
}
