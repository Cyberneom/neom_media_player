import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/domain/model/inbox_message.dart';
import 'package:neom_commons/core/ui/widgets/appbar_child.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import 'inbox_room_controller.dart';
import 'widgets/inbox_widgets.dart';
import 'widgets/message_tile.dart';

class InboxRoomPage extends StatelessWidget {
  const InboxRoomPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    //TODO VERIFY ITS WORKING
    Get.delete<InboxRoomController>();

    return GetBuilder<InboxRoomController>(
      id: AppPageIdConstants.inboxRoom,
      init: InboxRoomController(),
      builder: (_) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarChild(color: Colors.transparent),
        backgroundColor: AppColor.main50,
        body: Container(
          decoration: AppTheme.appBoxDecoration,
          child: Stack(
            children: [
              Column(
                children: [
                  AppTheme.heightSpace20,
                  Expanded(
                    child: Obx(() => _.isLoading ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      reverse: true,
                      controller: _.scrollController,
                      itemCount: _.messages.length,
                      itemBuilder: (context, index){
                        InboxMessage message = _.messages.reversed.elementAt(index);
                        return GestureDetector(
                            child: MessageTile(
                            message: message,
                            sendByMe: _.profile.id == message.ownerId ? true : false
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
                                  dateFormat: "yyyy-MM-dd HH:mm"))
                                ]),
                            buttons: []
                        ).show() ,
                        );
                      }
                    ),
                    ),
                  ),
                  if(!_.isBot) buildInboxMessageComposer(context, _),
              ]
            ),
          ],
        ),
      ),
    ),
    );
  }

  TextStyle simpleTextStyle() {
    return const TextStyle(color: Colors.white, fontSize: 16);
  }

  TextStyle biggerTextStyle() {
    return const TextStyle(color: Colors.white, fontSize: 17);
  }
}
