import 'package:flutter/material.dart';

import 'package:neom_commons/core/domain/model/inbox_message.dart';
import 'package:neom_commons/core/ui/widgets/circle_avatar_routing_image.dart';
import 'package:neom_commons/core/ui/widgets/handled_cached_network_image.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

class MessageTile extends StatelessWidget {

  final InboxMessage message;
  final bool sendByMe;
  final double? height;
  final double? width;

  const MessageTile({
    required this.message,
    required this.sendByMe,
    this.height, this.width,
    Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {

    int widthPerCharacter = 12;
    double messageWidth = (message.text.length * widthPerCharacter).toDouble();
    double mediaUrlWidth = AppTheme.fullWidth(context)/3;

    if(messageWidth > AppTheme.fullWidth(context)) {
      messageWidth = AppTheme.fullWidth(context) * 0.8;
    } else if(message.mediaUrl.isNotEmpty && messageWidth < mediaUrlWidth) {
      messageWidth = mediaUrlWidth;
    } else if(message.text.length >= 5 && message.text.length <= 10) {
      messageWidth = (message.text.length * 13).toDouble();
    } else if(message.text.length >= 3 && message.text.length < 5) {
      messageWidth = (message.text.length * 16.5).toDouble();
    } else if(message.text.length == 3) {
      messageWidth = (message.text.length * 22).toDouble();
    } else if(message.text.length < 3) {
      messageWidth = 50;
    }

    AppUtilities.logger.t("Message Width: $messageWidth for text: ${message.text}");
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if(!sendByMe)
              Row(
                children: [
                  CircleAvatarRoutingImage(
                    mediaUrl: message.profileImgUrl,
                    toNamed: AppRouteConstants.mateDetails,
                    arguments: message.ownerId,
                    enableRouting: message.ownerId != AppConstants.appBot,
                    width: 15, radius: 15,
                  ),
                  AppTheme.widthSpace5
                ],
              ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal:  10,),
              width: messageWidth,
              decoration: sendByMe ? AppTheme.messageBoxDecorationSelf : AppTheme.messageBoxDecoration,
              child: Column(
                children: [
                  if(message.mediaUrl.isNotEmpty)
                    Column(
                      children: [
                        Center(
                          child: HandledCachedNetworkImage(
                            message.mediaUrl,
                            width: mediaUrlWidth,
                          ),
                        ),
                        AppTheme.heightSpace5
                      ],
                    ),
                  if(message.text.isNotEmpty) Text(message.text, style: AppTheme.messageStyle),
                  // Text(AppUtilities.dateFormat(message.createdTime, dateFormat: AppConstants.yyyyMMddHHmm), style: TextStyle(fontSize: 12, color: AppColor.lightGrey),)
                ],
              ),
            ),
          ]
      )
    );
  }
}
