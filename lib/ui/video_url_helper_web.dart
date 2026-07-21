import 'dart:html' as html;
import 'package:http/http.dart' as http;

Future<String> getPlayableVideoUrl(String url) async {
  // Return direct URL by default for progressive streaming
  return url;
}

Future<String> getBlobFallbackUrl(String url) async {
  if (url.startsWith('blob:') ||
      url.startsWith('data:') ||
      url.startsWith('asset:') ||
      url.startsWith('assets/') ||
      url.startsWith('packages/')) {
    return url;
  }
  try {
    final response = await http.get(Uri.parse(url));
    final blob = html.Blob([response.bodyBytes], 'video/mp4');
    return html.Url.createObjectUrlFromBlob(blob);
  } catch (e) {
    print('NeomVideoPlayer: Error creating Blob URL fallback: $e');
    return url;
  }
}
