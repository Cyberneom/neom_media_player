import 'package:get/get.dart';

import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'ui/inbox_page.dart';
import 'ui/inbox_room_page.dart';

class InboxRoutes {

  static final List<GetPage<dynamic>> routes = [
    GetPage(
        name: AppRouteConstants.inbox,
        page: () => const InboxPage(),
        transition: Transition.rightToLeft
    ),
    GetPage(
        name: AppRouteConstants.inboxRoom,
        page: () => const InboxRoomPage(),
        transition: Transition.zoom
    ),
  ];

}
