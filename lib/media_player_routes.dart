import 'package:get/get.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import 'ui/full_screen/full_screen_image_page.dart';
import 'ui/full_screen/full_screen_video_page.dart';

class MediaPlayerRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.imageFullScreen,
        page: () => const FullScreenImagePage(),
        transition: Transition.zoom
    ),
    GetPage(
      name: AppRouteConstants.videoFullScreen,
      page: () => const FullScreenVideoPage(),
      transition: Transition.zoom,
    ),
  ];

}
