import 'package:get/get.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import 'ui/full_screen_video.dart';
import 'ui/media_fullscreen_page.dart';

class MediaPlayerRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.mediaFullScreen,
        page: () => const MediaFullScreenPage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.videoFullScreen,
      page: () => const FullScreenVideo(),
      transition: Transition.zoom,
    ),
  ];

}
