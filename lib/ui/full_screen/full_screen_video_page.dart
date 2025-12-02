import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_commons/ui/widgets/app_circular_progress_indicator.dart';
import 'package:neom_commons/ui/widgets/buttons/video_play_button.dart';
import 'package:neom_commons/ui/widgets/header_intro.dart';
import 'package:neom_commons/utils/datetime_utilities.dart';
import 'package:neom_core/domain/use_cases/audio_handler_service.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:video_player/video_player.dart';

import '../../utils/constants/media_player_translation_constants.dart';

class FullScreenVideoPage extends StatefulWidget {

  final String? mediaUrl;
  final VideoPlayerController? controller;
  final bool showPlaybackSpeed;

  const FullScreenVideoPage({this.mediaUrl, this.controller, this.showPlaybackSpeed = false, super.key});

  @override
  FullScreenVideoPageState createState() => FullScreenVideoPageState();
}

class FullScreenVideoPageState extends State<FullScreenVideoPage> with SingleTickerProviderStateMixin {

  late VideoPlayerController controller;
  late Stream<Duration> durationStream;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  DeviceOrientation currentOrientation = DeviceOrientation.portraitUp;
  bool isLoading = true;
  bool isPlaying = false;
  bool showPlaybackSpeed = false;
  double aspectRatio = 1;
  double adsVisibleRatio = 0.75;

  String currentClipPhrase = '';

  AudioHandlerService audioHandler = Get.find<AudioHandlerService>();

  @override
  void initState() {
    super.initState();

    if(audioHandler.isPlaying) {
      audioHandler.stop();
      audioHandler.stoppedByVideo = true;
    }

    currentClipPhrase = getRandomClipPhrase();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    if(widget.controller != null) {
      controller = widget.controller!;
    } else {
      controller = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl ?? ''));
    }

    controller.initialize().then((_) {
        DeviceOrientation orientation = DeviceOrientation.portraitUp;

        if (mounted && controller.value.isInitialized) {
          controller.play().then((_) {
            setState(() {
              isLoading = false;
              isPlaying = true;
              aspectRatio = controller.value.aspectRatio;
              currentOrientation = orientation;
            });
          });
        }
      });

    durationStream = Stream<Duration>.periodic(const Duration(seconds: 1), (data) {
      return controller.value.position;
    });

  }

  @override
  void dispose() {
    super.dispose();
    // Ensure disposing of the VideoPlayerController to free up resources.
    if(widget.controller == null) controller.dispose();
    _animationController.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);

    if(audioHandler.stoppedByVideo) {
      audioHandler.play();
    }
  }



  @override
  Widget build(BuildContext context) {

    double aspectRatio = controller.value.aspectRatio; // por ejemplo, 16/9 = 1.77
    double screenWidth = AppTheme.fullWidth(context);
    double videoHeight = screenWidth / aspectRatio;

    double screenHeight = AppTheme.fullHeight(context);
    double screenCenter = screenHeight / 2;

    return Scaffold(
      // extendBodyBehindAppBar: true,
      backgroundColor: AppFlavour.getBackgroundColor(),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: !isLoading ?
        Stack(
          children: [
            // Widgets arriba del centro
            if(aspectRatio >= adsVisibleRatio
                && currentOrientation == DeviceOrientation.portraitUp)
              Positioned(
              bottom: screenCenter + (videoHeight / 2),
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  HeaderIntro(title: 'Clips', showPreLogo: false,),
                  AppTheme.heightSpace30,
                ],
              ),
            ),
            // Widgets debajo del centro
            if(aspectRatio >= adsVisibleRatio
                && currentOrientation == DeviceOrientation.portraitUp)
              Positioned(
              top: screenCenter + (videoHeight / 2),
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTheme.heightSpace30,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        currentClipPhrase.tr,
                        textAlign: TextAlign.center,
                        style: AppTheme.headerSubtitleStyle,
                      ),
                    ),
                  ),
                ],
              )
            ),

            // Placeholder central del video
            if(aspectRatio >= adsVisibleRatio
                && currentOrientation == DeviceOrientation.portraitUp)
            Positioned(
              top: screenCenter - (videoHeight / 2),
              left: 0, right: 0,
              child: SizedBox(height: videoHeight),
            ),
            if(isPlaying) Container(color: Colors.black.withOpacity(0.6),),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if(controller.value.isInitialized) Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Stack(
                      children: [
                        VideoPlayer(controller),
                        buildControlsOverlay(),
                        Positioned(bottom: 0, right: 0, left: 0,
                          child: VideoProgressIndicator(controller,
                              allowScrubbing: true,
                              padding: const EdgeInsets.symmetric(vertical: 10)
                          ),
                        ),
                      ],
                    )
                ),
              ),
            ),
        ],): AppCircularProgressIndicator(),
      ),
    );
  }

  Widget buildControlsOverlay() {
    return Stack(
      children: <Widget>[
        if(!isPlaying) const VideoPlayButton(),
        GestureDetector(
          onTap: () {
            setState(() {
              isPlaying ? controller.pause() : controller.play();
              isPlaying = !isPlaying;
            });
          },
          onDoubleTap: () => Navigator.pop(context),
        ),
        StreamBuilder<Duration>(
          stream: durationStream,
          builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
            if (snapshot.hasData) {
              return Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15,),
                  child: Text('${DateTimeUtilities.getDurationInMinutes(snapshot.data!.inMilliseconds)} / ${DateTimeUtilities.getDurationInMinutes(controller.value.duration.inMilliseconds)}',),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        ///WAITING FOR FULLSCREEN TO WORK
        // if(aspectRatio > 1) Align(
        //   alignment: Alignment.bottomRight,
        //   child: Container(
        //     padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15,),
        //     child: IconButton(
        //       icon: const Icon(Icons.fullscreen),
        //       onPressed: _onFullscreenIconButtonTap,
        //     ),
        //   ),
        // ),
        if(showPlaybackSpeed) Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            color: AppColor.getMain(),
            tooltip: MediaPlayerTranslationConstants.playbackSpeed,
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
              setState(() {});
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in CoreConstants.playbackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15,),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }

  void _onFullscreenIconButtonTap() {
    setState(() {
      if (currentOrientation == DeviceOrientation.portraitUp) {
        currentOrientation = DeviceOrientation.landscapeLeft;
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
        ]);
      } else {
        currentOrientation = DeviceOrientation.portraitUp;
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    });
  }

  String getRandomClipPhrase() {
    final random = Random();
    return clipPhraseKeys.elementAt(random.nextInt(clipPhraseKeys.length));
  }

  final List<String> clipPhraseKeys = [
    'clipPhrase1',
    'clipPhrase2',
    'clipPhrase3',
    'clipPhrase4',
    'clipPhrase5',
    'clipPhrase6',
    'clipPhrase7',
    'clipPhrase8',
    'clipPhrase9',
    'clipPhrase10',
    'clipPhrase11',
    'clipPhrase12',
    'clipPhrase13',
    'clipPhrase14',
    'clipPhrase15',
    'clipPhrase16',
    'clipPhrase17',
    'clipPhrase18',
    'clipPhrase19',
    'clipPhrase20',
    'clipPhrase21',
    'clipPhrase22',
    'clipPhrase23',
    'clipPhrase24',
    'clipPhrase25',
    'clipPhrase26',
    'clipPhrase27',
    'clipPhrase28',
    'clipPhrase29',
    'clipPhrase30',
  ];


}
