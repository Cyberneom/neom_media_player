import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_core/domain/use_cases/audio_handler_service.dart';
import 'package:video_player/video_player.dart';

import 'full_screen/full_screen_video_page.dart';
import 'media_player_controller.dart';

class NeomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;
  final bool showProgress;
  final GlobalKey videoKey; // ✅ Nuevo parámetro para la clave única

  const NeomVideoPlayer({required this.videoUrl, required this.videoKey, this.showProgress = false, this.thumbnailUrl = '', super.key});

  @override
  State<NeomVideoPlayer> createState() => _NeomVideoPlayerState();
}

class _NeomVideoPlayerState extends State<NeomVideoPlayer> {
  late VideoPlayerController _controller;
  final isInitialized = false.obs;
  final isMuted = true.obs; // 🔇 Mute por defecto

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        isInitialized.value = true;
        _controller.setVolume(0); // 🔇 Establecer el volumen en cero por defecto

        if (Get.isRegistered<MediaPlayerController>()) {
          final mediaPlayerController = Get.find<MediaPlayerController>();
          mediaPlayerController.registerVideoKeyController(widget.videoUrl, widget.videoKey, _controller);
        } else {
          _controller.play(); // ▶️ Reproducir automáticamente                // setState(() {});
        }
      });

    _controller.addListener(() {
      // setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => isInitialized.value
        ? AspectRatio(
        key: widget.videoKey,
        aspectRatio: _controller.value.aspectRatio,
        child: GestureDetector(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              if(widget.showProgress) VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey,
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    isMuted.toggle();
                    _controller.setVolume(isMuted.value ? 0 : 1);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 15,
                    child: Icon(
                      isMuted.value ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Obx(()=> (Get.find<AudioHandlerService>().isPlaying) ?
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0x36FFFFFF).withOpacity(0.1),
                          const Color(0x0FFFFFFF).withOpacity(0.1)
                        ],
                        begin: FractionalOffset.topLeft,
                        end: FractionalOffset.bottomRight
                      ),
                      borderRadius: BorderRadius.circular(50)
                    ),
                    child: Icon(Icons.play_arrow, size: 60,),
                  ),
                ) : SizedBox.shrink()
              ),
            ],
          ),
          onTap: () {
            if(isMuted.value) {
              _controller.setVolume(1);
              isMuted.value = false;
            }
            Get.to(() => FullScreenVideoPage(controller: _controller),
                transition: Transition.zoom);
          },
        )
      ) : Stack(
      alignment: Alignment.center,
      children: [
        HandledCachedNetworkImage(widget.thumbnailUrl),
        const Center(child: CircularProgressIndicator()),
      ],)
    );
  }


}
