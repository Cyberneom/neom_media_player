import 'package:get/get.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';

import 'ui/full_screen_video.dart';

class NeomMediaPlayerRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
      name: AppRouteConstants.videoFullScreen,
      page: () => const FullScreenVideo(),
      transition: Transition.zoom,
    ),
  ];

}
