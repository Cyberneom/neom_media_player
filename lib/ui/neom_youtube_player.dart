import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'media_player_controller.dart';

class NeomYoutubePlayer extends StatefulWidget {
  final String youtubeUrl;
  final GlobalKey youtubeKey; // ✅ Nuevo parámetro para la clave única

  const NeomYoutubePlayer({required this.youtubeUrl, required this.youtubeKey, super.key});

  @override
  State<NeomYoutubePlayer> createState() => _NeomYoutubePlayerState();
}

class _NeomYoutubePlayerState extends State<NeomYoutubePlayer> {
  YoutubePlayerController? controller;
  String videoId = '';

  @override
  void initState() {
    super.initState();

    videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl) ?? '';
    if(videoId.isNotEmpty) {
      controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false),
      );

      // Registrar el controlador en el TimelineController
      if (Get.isRegistered<MediaPlayerController>() && controller != null) {
        final mediaPlayerController = Get.find<MediaPlayerController>();
        mediaPlayerController.registerYouTubeKeyController(widget.youtubeUrl, widget.youtubeKey, controller!);
      } else {
        controller?.play();
      }
    }
  }

  @override
  void didUpdateWidget(covariant NeomYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.youtubeUrl != widget.youtubeUrl) {
      controller?.load(YoutubePlayer.convertUrlToId(widget.youtubeUrl) ?? '');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return videoId.isNotEmpty && controller != null ? YoutubePlayer(
      key: widget.key,
      // key: ValueKey(widget.youtubeUrl), // Esto es esencial para reconstruir solo al cambiar URL
      controller: controller!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.blueAccent,
      topActions: <Widget>[
        const SizedBox(width: 10.0),
        Expanded(
          child: Text(
            controller!.metadata.title,
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
      bottomActions: const [
        SizedBox(width: 10),
        CurrentPosition(),
        ProgressBar(isExpanded: true,),
        RemainingDuration(),
        SizedBox(width: 10),
      ],
      onReady: () {},
    ) : const SizedBox.shrink();
  }
}
