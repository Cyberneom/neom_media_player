import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/app_flavour.dart';
import 'package:neom_commons/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_commons/core/data/firestore/inbox_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/inbox.dart';
import 'package:neom_commons/core/domain/model/inbox_message.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_constants.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/app_file_from.dart';
import 'package:neom_commons/core/utils/enums/app_media_type.dart';
import 'package:neom_commons/core/utils/enums/inbox_room_type.dart';
import 'package:neom_commons/core/utils/enums/push_notification_type.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_posts/posts/ui/add/post_upload_controller.dart';

import '../domain/use_cases/inbox_room_service.dart';

class InboxRoomController extends GetxController implements InboxRoomService {

  final userController = Get.find<UserController>();
  final postUploadController = Get.put(PostUploadController());
  final InboxFirestore inboxFirestore = InboxFirestore();

  final ScrollController scrollController = ScrollController();
  final TextEditingController messageController = TextEditingController();

  Timer? timer;

  final RxBool editStatus = false.obs;
  final RxString location = "".obs;
  final RxString messageText = "".obs;
  final RxBool isLoading = true.obs;
  final RxBool sendingMessage = false.obs;
  final RxList<InboxMessage> messages = <InboxMessage>[].obs;
  final Rx<Inbox> inbox = Inbox().obs;
  final Rx<AppProfile> profile = AppProfile().obs;
  final RxString mainMateId = "".obs;
  final Rx<AppProfile> mainMate = AppProfile().obs;


  String inboxRoomId = "";

  List<String> profileIds = [];
  final RxList<AppProfile> profiles = <AppProfile>[].obs;
  bool isLiked = false;
  bool showHeart = false;
  bool isBot = false;

  int totalMessages = 0;

  @override
  void onInit() async {
    super.onInit();

    try {

      List<dynamic> arguments  = Get.arguments;
      if (Get.arguments[0] is Inbox) {
        inbox.value =  arguments.elementAt(0);
        inboxRoomId = inbox.value.id;
      } else if (Get.arguments[0] is String) {
        inboxRoomId = Get.arguments[0];
      }

      profile.value = userController.profile;
      if(inboxRoomId.contains(AppConstants.appBot)) {
        await loadMessages(inboxRoomId);
        isBot = true;
        mainMate.value.name = AppConstants.appBot.tr;
        mainMate.value.photoUrl = AppFlavour.getAppLogoUrl();
      } else {
        profileIds = inboxRoomId.split("_");
        if(profileIds.isNotEmpty) {
          profileIds.removeWhere((id) => id == profile.value.id);
          if(profileIds.isNotEmpty) {
            mainMateId.value = profileIds.first;
            mainMate.value = await ProfileFirestore().retrieve(mainMateId.value);
          }
        }
        timer = Timer.periodic(const Duration(seconds: 2), (timer) {
          AppUtilities.logger.t("Verifying more Messages");
          loadMessages(inboxRoomId);
        });
      }
    } catch (e) {
       AppUtilities.logger.e(e.toString());
    }
  }

  @override
  void onReady() async {
    super.onReady();
    AppUtilities.logger.t("InboxRoom Controller Ready");
  }

  ///DEPRECATED
  // @override
  // void onDelete() {
  //   super.onDelete();
  //   timer?.cancel();
  // }

  @override
  FutureOr onClose() {
    super.onClose();
    timer?.cancel();
  }

  void clear() {
    profile.value = AppProfile();
    messages.value = [];
  }

  @override
  void setMessageText(text) {
    messageText.value = text;
  }

  ///VERIFY HOW TO USE
  // Stream<List<InboxMessage>> getMessages(String roomId) async* {
  //   while (true) {
  //     yield await _inboxFirestore.retrieveMessages(roomId);
  //     await Future.delayed(const Duration(seconds: 2));
  //   }
  // }

  @override
  Future<void> loadMessages(String roomId) async {
    AppUtilities.logger.t("Retrieving messages for room $inboxRoomId");

    try {
      messages.value = await inboxFirestore.retrieveMessages(roomId);
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    AppUtilities.logger.t("Retrieving ${messages.length} messages");
    isLoading.value = false;
    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
  }


  @override
  Future<void> addMessage({InboxRoomType inboxRoomType = InboxRoomType.profile}) async {
    AppUtilities.logger.t("Adding message to inbox room");
    InboxMessage message;

    sendingMessage.value = true;
    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);

    bool hasImage = postUploadController.mediaFile.value.path.isNotEmpty;

    if (messageText.isNotEmpty || hasImage) {
      message = InboxMessage(
          ownerId: profile.value.id,
          profileName: profile.value.name,
          profileImgUrl: profile.value.photoUrl,
          text: messageText.value.trim(),
          createdTime: DateTime.now().millisecondsSinceEpoch
      );

      try {

        if(hasImage) {
          message.type = AppMediaType.image;
          message.mediaUrl = await postUploadController.handleUploadImage(UploadImageType.message);
        }

        messages.value.add(message);

        if(await inboxFirestore.addMessage(inboxRoomId, message, inboxRoomType: inboxRoomType)) {
          if(inboxRoomType == InboxRoomType.profile) {
            String itemmateId = inboxRoomId.replaceAll(profile.value.id, "");
            itemmateId = itemmateId.replaceAll("_", "");

            FirebaseMessagingCalls.sendPrivatePushNotification(
                toProfileId: itemmateId,
                fromProfile: profile.value,
                notificationType: PushNotificationType.message,
                referenceId: inboxRoomId,
                message: message.text,
                imgUrl: message.mediaUrl
            );
          }
        }
      } catch (e) {
        sendingMessage.value = false;
        AppUtilities.logger.e(e.toString());
      }

      clearMessage();
      sendingMessage.value = false;
      update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
    }
  }

  Future<void> handleImage(AppFileFrom appFileFrom) async {
    await postUploadController.handleImage(appFileFrom: appFileFrom, uploadImageType: UploadImageType.profile, crop: false);
    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
  }

  void clearMessage() {
    messageText.value = "";
    messageController.clear();
    postUploadController.clearMedia();
    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
  }

  void clearImage() {
    postUploadController.clearMedia();
    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
  }

  bool isLikedMessage(InboxMessage message) {
    return message.likedProfiles.contains(profile.value.id);
  }

  Future<void> handleLikeMessage(InboxMessage message) async {

    isLiked = isLikedMessage(message);

    if (await inboxFirestore.handleLikeMessage(profile.value.id, message.id, isLiked)) {

      isLiked ? message.likedProfiles.remove(profile.value.id)
          : message.likedProfiles.add(profile.value.id);
    }

    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
  }

}
