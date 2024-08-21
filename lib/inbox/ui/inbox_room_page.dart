import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/inbox_message.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/ui/widgets/circle_avatar_routing_image.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'inbox_room_controller.dart';
import 'widgets/inbox_widgets.dart';
import 'widgets/message_tile.dart';

class InboxRoomPage extends StatelessWidget {
  const InboxRoomPage({super.key});


  @override
  Widget build(BuildContext context) {
    //TODO VERIFY ITS WORKING
    Get.delete<InboxRoomController>();

    return GetBuilder<InboxRoomController>(
      id: AppPageIdConstants.inboxRoom,
      init: InboxRoomController(),
      builder: (_) => Obx(() => Scaffold(
        // extendBodyBehindAppBar: true,
        appBar: AppBarChild(preTitle: _.isLoading.value ? null : CircleAvatarRoutingImage(
          mediaUrl: _.mainMate.value.photoUrl,
          toNamed: AppRouteConstants.mateDetails,
          arguments: _.mainMate.value.id,
          height: 20, radius: 20,
          enableRouting: !_.isBot,

        ),
        title: _.mainMate.value.name,),
        backgroundColor: AppColor.main50,
        body: Container(
        decoration: AppTheme.appBoxDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: AppTheme.fullHeight(context),
        width: AppTheme.fullWidth(context),
        child: _.isLoading.value ? const Center(child: CircularProgressIndicator())
            : Column(
            children: [
              AppTheme.heightSpace10,
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  controller: _.scrollController,
                  itemCount: _.messages.length,
                  itemBuilder: (context, index) {
                    InboxMessage message = _.messages.reversed.elementAt(index);
                    return GestureDetector(
                        child: MessageTile(
                        message: message,
                        sendByMe: _.profile.value.id == message.ownerId
                      ),
                      onLongPress: () => Alert(
                        context: context,
                        title: AppTranslationConstants.message.tr,
                        style: AlertStyle(
                            backgroundColor: AppColor.main50,
                            titleStyle: const TextStyle(color: Colors.white)
                        ),
                        content: Column(
                            children: <Widget>[
                              Text(AppUtilities.dateFormat(message.createdTime,
                              dateFormat: AppConstants.yyyyMMddHHmm))
                            ]),
                        buttons: []
                    ).show() ,
                    );
                  }
                ),
              ),
              AppTheme.heightSpace10,
              if(!_.isBot) buildInboxMessageComposer(context, _)
            ]
          ),
        ),
        bottomNavigationBar: null
    ),),
    );
  }

}
