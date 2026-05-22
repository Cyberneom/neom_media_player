import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/ui/deferred_loader.dart';
import 'package:sint/sint.dart';

import 'ui/full_screen/full_screen_image_page.dart' deferred as fsImage;
import 'ui/full_screen/full_screen_video_page.dart' deferred as fsVideo;

class MediaPlayerRoutes {

  static final List<SintPage<dynamic>> routes = [
    SintPage(
        name: AppRouteConstants.imageFullScreen,
        page: () => DeferredLoader(fsImage.loadLibrary, () => fsImage.FullScreenImagePage()),
        transition: Transition.zoom
    ),
    SintPage(
      name: AppRouteConstants.videoFullScreen,
      page: () => DeferredLoader(fsVideo.loadLibrary, () => fsVideo.FullScreenVideoPage()),
      transition: Transition.zoom,
    ),
  ];

}
