import 'package:sint/sint.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import 'ui/full_screen/full_screen_image_page.dart';
import 'ui/full_screen/full_screen_video_page.dart';

class MediaPlayerRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
        name: AppRouteConstants.imageFullScreen,
        page: () => const FullScreenImagePage(),
        transition: Transition.zoom
    ),
    SintPage(
      name: AppRouteConstants.videoFullScreen,
      page: () => const FullScreenVideoPage(),
      transition: Transition.zoom,
    ),
  ];

}
