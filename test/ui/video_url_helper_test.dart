import 'package:flutter_test/flutter_test.dart';
import 'package:neom_media_player/ui/video_url_helper_stub.dart'
    if (dart.library.html) 'package:neom_media_player/ui/video_url_helper_web.dart';

void main() {
  group('Video URL Helper Tests', () {
    test('Bypass standard prefixes directly', () async {
      expect(
        await getPlayableVideoUrl('blob:http://localhost/123'),
        equals('blob:http://localhost/123'),
      );
      expect(
        await getPlayableVideoUrl('data:video/mp4;base64,...'),
        equals('data:video/mp4;base64,...'),
      );
      expect(
        await getPlayableVideoUrl('asset:assets/video.mp4'),
        equals('asset:assets/video.mp4'),
      );
      expect(
        await getPlayableVideoUrl('assets/video.mp4'),
        equals('assets/video.mp4'),
      );
      expect(
        await getPlayableVideoUrl('packages/neom_media_player/assets/video.mp4'),
        equals('packages/neom_media_player/assets/video.mp4'),
      );
    });
  });
}
