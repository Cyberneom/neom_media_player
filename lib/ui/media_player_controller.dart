import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/media_player_service.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MediaPlayerController extends GetxController implements MediaPlayerService {

  VideoPlayerController? videoPlayerController;

  double _aspectRatio = 1;
  String mediaUrl = "";
  bool isInitialized = false;
  RxBool isPlaying = false.obs;

  double videoThreshold = 0.65; // 30% del widget visible para activar el video

  final Map<String, GlobalKey> _videoKeys = {}; // Nuevo mapa para almacenar claves de video
  final Map<String, String> _spotifyTrackImgUrls = {};
  final Map<String, GlobalKey> _youtubeKeys = {}; // Nuevo mapa para almacenar claves de video

  final Map<String, YoutubePlayerController> _youtubeControllers = {}; // Nuevo mapa para almacenar claves de video
  final Map<String, VideoPlayerController> _videoControllers = {}; // Nuevo mapa para almacenar claves de video

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.i("MediaPlayer Controller Init");

    try {

    } catch (e) {
      AppConfig.logger.e(e.toString());
    }

  }

  @override
  Future<void> initializeVideoPlayerController(File file) async {
    AppConfig.logger.d("initializeVideoPlayerController");

    try {
      videoPlayerController = VideoPlayerController.file(file);
      await videoPlayerController?.initialize();

      if(videoPlayerController?.value.isInitialized ?? false) {
        isInitialized = true;
        final videoSize = videoPlayerController!.value.size;
        _aspectRatio = videoSize.width / videoSize.height;
      }
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  @override
  Future<void> playPauseVideo() async {
    AppConfig.logger.d("playPauseVideo");
    (videoPlayerController?.value.isPlaying ?? false) ? await videoPlayerController?.pause() : videoPlayerController?.play();
    AppConfig.logger.t("isPlaying ${videoPlayerController?.value.isPlaying}");

    isPlaying.value = !isPlaying.value;
    AppConfig.logger.d("isPlaying: $isPlaying");
    update();
  }

  @override
  void setIsPlaying({bool value = true}) {
    if(isPlaying.value != value) {
      isPlaying.value = value;
      update();
    }
  }

  @override
  void disposeVideoPlayer() {
    if(videoPlayerController?.value.isInitialized ?? false) {
      if(videoPlayerController?.value.isPlaying ?? false) videoPlayerController?.pause();
      videoPlayerController = VideoPlayerController.networkUrl(Uri());
      videoPlayerController?.dispose();
    }

  }

  Widget getVideoPlayer() {
    AppConfig.logger.d("getVideoPlayer");
    return VideoPlayer(videoPlayerController!);
  }

  @override
  Widget getVideoPlayerContainer({required double height, required double width}) {
    return isInitialized ? Container(
      color: AppColor.appBlack,
      height: height/(aspectRatio > 1 ? aspectRatio : 1),
      width: width*(aspectRatio <= 1 ? aspectRatio : 1),
      child: Stack(
          children: [
            VideoPlayer(videoPlayerController!),
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
                child: IconButton(
                  icon: Icon(isPlaying.value ? Icons.pause : Icons.play_arrow,),
                  iconSize: 30,
                  color: Colors.white70.withOpacity(0.5),
                  onPressed: () => playPauseVideo(),
                ),
              ),
            ),
          ]),
    ) : SizedBox.shrink();
  }

  @override
  bool get isVideoPlayerInitialized => isInitialized;

  @override
  bool get isVideoPlayerPlaying => isPlaying.value;

  @override
  double get aspectRatio => _aspectRatio;


  void registerVideoKeyController(String ytUrl, GlobalKey ytKey, VideoPlayerController ytController) {
    _videoKeys[ytUrl] = ytKey;
    _videoControllers[ytUrl] = ytController;
  }

  void registerYouTubeKeyController(String ytUrl, GlobalKey ytKey, YoutubePlayerController ytController) {
    _youtubeKeys[ytUrl] = ytKey;
    _youtubeControllers[ytUrl] = ytController;
  }

  @override
  void visibleVideoAction() {
    try {
      _handleVideoVisibility(_videoKeys, _videoControllers);
      _handleVideoVisibility(_youtubeKeys, _youtubeControllers);
    } catch (e) {
      AppConfig.logger.e(e.toString());
    }
  }

  void _handleVideoVisibility<T>(Map<String, GlobalKey> keys, Map<String, T> controllers) {
    for (int i = 0; i < keys.length; i++) {
      final entry = keys.values.elementAt(i);

      final context = entry.currentContext;
      if (context == null) continue;

      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);

      final videoHeight = renderBox.size.height;
      final screenHeight = MediaQuery.of(Get.context!).size.height;

      // Calcular el centro del video
      final videoCenter = position.dy + (videoHeight / 2);

      // Definir un margen de tolerancia (por ejemplo, 75% arriba/abajo del centro)
      final visibilityMargin = screenHeight * videoThreshold;

      // Verifica si el centro del video está dentro del área de visibilidad
      final isVisible = videoCenter > (screenHeight / 2) - visibilityMargin &&
          videoCenter < (screenHeight / 2) + visibilityMargin;


      final controller = controllers[keys.keys.elementAt(i)];

      if (controller == null) continue;

      if (controller is VideoPlayerController) {
        if (isVisible && !controller.value.isPlaying) {
          controller.play();
        } else if (!isVisible && controller.value.isPlaying) {
          controller.pause();
        }
      } else if (controller is YoutubePlayerController) {
        if (isVisible && !controller.value.isPlaying) {
          controller.play();
        } else if (!isVisible && controller.value.isPlaying) {
          controller.pause();
        }
      }
    }
  }

  @override
  Map<String, String> get spotifyTrackImgUrls => _spotifyTrackImgUrls;

  @override
  Map<String, GlobalKey<State<StatefulWidget>>> get videoKeys => _videoKeys;

  @override
  Map<String, GlobalKey<State<StatefulWidget>>> get youtubeKeys => _youtubeKeys;

}
