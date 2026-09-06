import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sint/sint.dart';
import 'package:web/web.dart' as web;

import '../../utils/youtube_url.dart';
import 'youtube_web_controller.dart';

Widget buildYoutubeWebPlayer({
  required String videoId,
  required bool muted,
  required YoutubeWebController controller,
}) => _YoutubeWebPlayer(
  key: ObjectKey(controller),
  videoId: videoId,
  muted: muted,
  controller: controller,
);

class _YoutubeWebPlayer extends StatefulWidget {
  const _YoutubeWebPlayer({
    required this.videoId,
    required this.muted,
    required this.controller,
    super.key,
  });

  final String videoId;
  final bool muted;
  final YoutubeWebController controller;

  @override
  State<_YoutubeWebPlayer> createState() => _YoutubeWebPlayerState();
}

class _YoutubeWebPlayerState extends State<_YoutubeWebPlayer> {
  static int _nextFrameId = 0;
  final String _frameId = 'neom-youtube-${_nextFrameId++}';
  web.HTMLIFrameElement? _iframe;
  StreamSubscription<web.Event>? _loadSubscription;
  StreamSubscription<web.MessageEvent>? _messageSubscription;
  Timer? _readyTimer;

  @override
  void initState() {
    super.initState();
    _messageSubscription = web.window.onMessage.listen(_handleMessage);
  }

  void _handleMessage(web.MessageEvent event) {
    final iframe = _iframe;
    if (!mounted ||
        iframe == null ||
        event.origin != youtubeEmbedOrigin ||
        // Dart's generic equality dispatch can inspect properties of Window,
        // which is forbidden across origins in the release JS compiler.
        // Compare the two JS references directly without opening the frame.
        !event.source.strictEquals(iframe.contentWindow).toDart) {
      return;
    }
    if (!event.data.typeofEquals('string')) return;
    final raw = (event.data as JSString).toDart;
    Object? data;
    try {
      data = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (data is Map && data['event'] == 'onReady') {
      _readyTimer?.cancel();
      widget.controller.markReady();
    }
  }

  void _post(Map<String, Object> message) {
    _iframe?.contentWindow?.postMessage(
      jsonEncode(message).toJS,
      youtubeEmbedOrigin.toJS,
    );
  }

  void _listenForReady() {
    if (!mounted || _iframe == null) return;
    _readyTimer?.cancel();
    void listen() => _post({'event': 'listening', 'id': _frameId});
    listen();
    // Native controls remain usable even when the optional hover bridge fails.
    _readyTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (timer.tick >= 40) {
        timer.cancel();
      } else {
        listen();
      }
    });
  }

  void _createIframe(Object element) {
    final iframe = element as web.HTMLIFrameElement;
    // Platform-view creation may finish after its scrolling card is disposed.
    if (!mounted) {
      iframe.src = 'about:blank';
      iframe.remove();
      return;
    }
    _iframe = iframe;
    iframe
      ..id = _frameId
      ..title = '${AppTranslationConstants.player.tr} — YouTube'
      ..allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen'
      ..allowFullscreen = true
      ..referrerPolicy = 'strict-origin-when-cross-origin'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    widget.controller.attach((command) {
      _post({'event': 'command', 'func': command, 'args': <Object>[]});
    });
    _loadSubscription = iframe.onLoad.listen((_) => _listenForReady());
    iframe.src = youtubeEmbedUri(
      widget.videoId,
      origin: Uri.parse(web.window.location.origin),
      muted: widget.muted,
    ).toString();
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    _loadSubscription?.cancel();
    _messageSubscription?.cancel();
    widget.controller.detach();
    // Stop playback immediately when a route/card is removed.
    _iframe?.src = 'about:blank';
    _iframe?.remove();
    _iframe = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: _createIframe,
  );
}
