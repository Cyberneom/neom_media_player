import 'package:flutter_test/flutter_test.dart';
import 'package:neom_media_player/utils/youtube_url.dart';

void main() {
  const id = 'sExubGCaFOI';

  test('parses supported YouTube video URL forms', () {
    for (final input in [
      id,
      ' $id ',
      'https://www.youtube.com/watch?v=$id&list=example',
      'https://m.youtube.com/watch?v=$id',
      'https://music.youtube.com/watch?v=$id',
      'https://youtu.be/$id?t=60',
      'https://www.youtube.com/shorts/$id',
      'https://youtube.com/live/$id',
      'https://www.youtube.com/embed/$id',
      'https://www.youtube-nocookie.com/embed/$id',
    ]) {
      expect(youtubeVideoId(input), id, reason: input);
    }
  });

  test('rejects foreign hosts, nonvideo URLs, and malformed IDs', () {
    for (final input in [
      '',
      'short',
      'https://example.com/watch?v=$id',
      'https://youtube.com.example.com/watch?v=$id',
      'https://youtube.com@evil.example/watch?v=$id',
      'https://evil.example@youtube.com/watch?v=$id',
      'javascript:alert(1)',
      'https://youtube.com/playlist?list=$id',
      'https://youtube.com/channel/$id',
      'https://youtube.com/watch?v=<script>',
      'https://youtu.be/$id/extra',
      'https://youtu.be/%FF',
      'https://youtube.com/watch?v=%FF',
      'https://youtube.com:8080/watch?v=$id',
    ]) {
      expect(youtubeVideoId(input), isNull, reason: input);
    }
  });

  test('embed keeps an HTTP localhost origin and requires user playback', () {
    final uri = youtubeEmbedUri(
      id,
      origin: Uri.parse('http://localhost:7358/feed?private=discarded'),
      muted: true,
    );
    expect(uri.origin, youtubeEmbedOrigin);
    expect(uri.path, '/embed/$id');
    expect(uri.queryParameters['origin'], 'http://localhost:7358');
    expect(uri.queryParameters['autoplay'], '0');
    expect(uri.queryParameters['controls'], '1');
    expect(uri.queryParameters['mute'], '1');
    expect(uri.queryParameters['enablejsapi'], '1');
    expect(uri.toString(), isNot(contains('private')));
  });

  test('embed validates its inputs and permits unmuted manual playback', () {
    expect(
      youtubeEmbedUri(
        id,
        origin: Uri.parse('https://gigmeout.com'),
        muted: false,
      ).queryParameters['autoplay'],
      '0',
    );
    expect(
      () => youtubeEmbedUri(
        '../evil',
        origin: Uri.parse('https://gigmeout.com'),
        muted: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => youtubeEmbedUri(
        id,
        origin: Uri.parse('file:///tmp/page'),
        muted: true,
      ),
      throwsArgumentError,
    );
  });
}
