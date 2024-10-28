import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import 'package:neom_commons/core/domain/model/inbox_message.dart';
import 'package:neom_commons/core/ui/widgets/custom_image.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_file_from.dart';
import 'package:neom_commons/core/utils/enums/inbox_room_type.dart';
import '../inbox_room_controller.dart';

Widget buildInboxMessageComposer(BuildContext context, InboxRoomController _,
    {InboxRoomType inboxRoomType = InboxRoomType.profile}) {
  return Container(
    child: Row(
      children: [
        SizedBox(
          child: (_.postUploadController.mediaFile.value.path.isEmpty || _.sendingMessage.value) ?
          IconButton(
              icon: const Icon(Icons.photo),
              iconSize: 25.0,
              color: Theme.of(context).primaryColorLight,
              onPressed: () async => await _.handleImage(AppFileFrom.gallery)
          ) :
          Stack(
              children: [
                Container(
                    width: 40.0, height: 40.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(52), // Add rounded corners here
                    ),
                    child: fileImage(_.postUploadController.mediaFile.value.path)
                ),
                Positioned(
                  width: 20, height: 20,
                  top: 30, left: 30,
                  child: FloatingActionButton(
                      backgroundColor: Theme.of(context).primaryColorLight,
                      child: const Icon(Icons.close, color: Colors.white70, size: 15),
                      onPressed: () => _.clearImage()
                  ),
                ),
              ]
          ),
        ),
        if(_.postUploadController.mediaFile.value.path.isNotEmpty) AppTheme.widthSpace10,
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: AppColor.main50,
              borderRadius: BorderRadius.circular(12), // Add rounded corners here
            ),
            child: TextField(
              controller: !_.sendingMessage.value ? _.messageController : TextEditingController(),
              minLines: 1,
              maxLines: 20,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: AppTranslationConstants.writeMessage.tr,
                border: InputBorder.none,
              ),
              onChanged: (text) {
                _.setMessageText(text);
              },
            ),
          ),
        ),
        if(_.sendingMessage.value) AppTheme.widthSpace5,
        Container(
          child: _.sendingMessage.value ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator())
              : IconButton(
            icon: const Icon(Icons.send),
            iconSize: 25.0,
            color: Theme.of(context).primaryColorLight,

            onPressed: () => _.sendingMessage.value || _.messageController.text.isEmpty ? {} : _.addMessage(inboxRoomType: inboxRoomType),
          ),
        )
      ],
    )
  );
}

Widget othersMessage(BuildContext context, InboxRoomController _, InboxMessage message) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      CircleAvatar(
          backgroundColor: Colors.grey,
          radius: 15,
          child: ClipOval(child: Image.network(_.inbox.value.profiles!.first.photoUrl))),
      AppTheme.widthSpace10,
      Expanded(
          child: Container(
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(
                    style: BorderStyle.solid, color: Colors.grey, width: 0.5)),
            child: Card(
              color: AppColor.getContextCardColor(context),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    AppTheme.heightSpace5,
                    message.mediaUrl.isEmpty ? Container() :
                    Column(children: [
                      SizedBox(height: 250, width: 250,
                          child: customCachedNetworkHeroImage(message.mediaUrl)),
                      AppTheme.heightSpace5,
                    ],),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        message.text.isEmpty ? Container() :
                        Expanded(child: Text(message.text, maxLines: 10, overflow: TextOverflow.ellipsis,
                        ),),
                        GestureDetector(
                          // child: Icon(
                          //   FontAwesomeIcons.heart,
                          //   size: 14, color: Colors.white,
                          // ),
                          child: Icon(_.isLikedMessage(message) ? FontAwesomeIcons.solidHeart
                              :  FontAwesomeIcons.heart, size: AppTheme.postIconSize),
                          onTap: () => _.handleLikeMessage(message),
                        ),
                      ],
                    ),
                    AppTheme.heightSpace5,
                    //TODO
                    //Divider(thickness: 1),
                    //menuReply(gigComment),
                  ],
                ),
              ),
            ),
          )
        //commentReply(context, FeedBloc().feedList[2]),
      )
    ],
  );
}
