import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';

import 'package:neom_commons/core/domain/model/inbox_message.dart';
import 'package:neom_commons/core/ui/widgets/custom_image.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_route_constants.dart';

class MessageTile extends StatelessWidget {

  final InboxMessage message;
  final bool sendByMe;

  const MessageTile({
    required this.message,
    required this.sendByMe,
    Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return sendByMe ? Container(
      padding: const EdgeInsets.only(
          top: 5, bottom: 5, left: 0, right: 20),
      alignment: Alignment.centerRight,
      child: Container(
        width: AppTheme.fullWidth(context)*0.75,
        margin: const EdgeInsets.only(left: 30),
        padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15),
        decoration: AppTheme.messageBoxDecoration,
        child: Column(
            children: [
              message.mediaUrl.isEmpty ? Container()
              : Column(children: [
                  Container(child: customCachedNetworkImage(message.mediaUrl)),
                  AppTheme.heightSpace5
              ],),
              Text(message.text,
                textAlign: TextAlign.start,
                style: AppTheme.messageStyle
              ),
            ],
          ),
      ),
    ) : Stack(
    children: [
      GestureDetector(child: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(message.profileImgUrl.isEmpty
            ? AppFlavour.getNoImageUrl() : message.profileImgUrl),
        radius: 25.0,
      ),
        onTap: () => message.ownerId != AppConstants.appBot
            ? Get.toNamed(AppRouteConstants.mateDetails, arguments: message.ownerId) : {},
      ),
      Container(
        width: AppTheme.fullWidth(context)*0.75,
        padding: const EdgeInsets.only(
          top: 5, bottom: 5, left: 55, right: 0),
        child: Container(
          margin: const EdgeInsets.only(right: 20),
          padding: const EdgeInsets.only(
            top: 15, bottom: 15, left: 20, right: 20),
          decoration: AppTheme.messageBoxDecoration,
          child: Column(
            children: [
              message.mediaUrl.isEmpty ? Container()
                  : Column(children: [
                Container(child: customCachedNetworkHeroImage(message.mediaUrl)),
                AppTheme.heightSpace5
              ],),
              Text(message.text,
                  textAlign: TextAlign.start,
                  style: AppTheme.messageStyle
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
