final _youtubeVideoId = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Accepts video IDs and URLs from YouTube's own video hosts only.
String? youtubeVideoId(String value) {
  try {
    return _parseYoutubeVideoId(value);
  } on FormatException {
    return null;
  }
}

String? _parseYoutubeVideoId(String value) {
  final input = value.trim();
  if (_youtubeVideoId.hasMatch(input)) return input;

  final uri = Uri.tryParse(input);
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort) {
    return null;
  }

  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments;
  String? id;
  if (host == 'youtu.be' || host == 'www.youtu.be') {
    if (segments.length == 1) id = segments.first;
  } else if (const {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
  }.contains(host)) {
    if (uri.path == '/watch') {
      id = uri.queryParameters['v'];
    } else if (segments.length == 2 &&
        const {'embed', 'shorts', 'live', 'v'}.contains(segments.first)) {
      id = segments.last;
    }
  }

  return id != null && _youtubeVideoId.hasMatch(id) ? id : null;
}

const youtubeEmbedOrigin = 'https://www.youtube-nocookie.com';

Uri youtubeEmbedUri(
  String videoId, {
  required Uri origin,
  required bool muted,
}) {
  if (!_youtubeVideoId.hasMatch(videoId)) {
    throw ArgumentError.value(videoId, 'videoId', 'Invalid YouTube video ID');
  }
  if ((origin.scheme != 'http' && origin.scheme != 'https') ||
      origin.host.isEmpty) {
    throw ArgumentError.value(origin, 'origin', 'Expected an HTTP(S) origin');
  }
  return Uri.https('www.youtube-nocookie.com', '/embed/$videoId', {
    'autoplay': '0',
    'controls': '1',
    'playsinline': '1',
    'enablejsapi': '1',
    'rel': '0',
    'mute': muted ? '1' : '0',
    'origin': origin.origin,
  });
}
