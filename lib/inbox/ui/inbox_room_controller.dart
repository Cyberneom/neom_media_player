import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:neom_commons/core/data/api_services/push_notification/firebase_messaging_calls.dart';
import 'package:neom_commons/core/data/firestore/inbox_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/inbox.dart';
import 'package:neom_commons/core/domain/model/inbox_message.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/enums/app_file_from.dart';
import 'package:neom_commons/core/utils/enums/app_media_type.dart';
import 'package:neom_commons/core/utils/enums/inbox_room_type.dart';
import 'package:neom_commons/core/utils/enums/push_notification_type.dart';
import 'package:neom_commons/core/utils/enums/upload_image_type.dart';
import 'package:neom_posts/posts/ui/add/post_upload_controller.dart';

import '../domain/use_cases/inbox_room_service.dart';

class InboxRoomController extends GetxController implements InboxRoomService {

  var logger = AppUtilities.logger;

  ScrollController scrollController = ScrollController();
  final userController = Get.find<UserController>();
  final postUploadController = Get.put(PostUploadController());
  final TextEditingController messageController = TextEditingController();
  final InboxFirestore _inboxFirestore = InboxFirestore();

  late Timer timer;

  final RxBool _editStatus = false.obs;
  bool get editStatus => _editStatus.value;
  set editStatus(bool editStatus) => _editStatus.value = editStatus;

  final RxString _location = "".obs;
  String get location => _location.value;
  set location(String location) => _location.value = location;

  final RxString _messageText = "".obs;
  String get messageText => _messageText.value;
  set messageText(String message) => _messageText.value = message;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxBool _sendingMessage = false.obs;
  bool get sendingMessage => _sendingMessage.value;
  set sendingMessage(bool sendingMessage) => _sendingMessage.value = sendingMessage;

  final RxList<InboxMessage> _messages = <InboxMessage>[].obs;
  List<InboxMessage> get messages => _messages;
  set messages(List<InboxMessage> messages) => _messages.value = messages;

  final Rx<Inbox> _inbox = Inbox().obs;
  Inbox get inbox => _inbox.value;
  set inbox(Inbox inbox) => _inbox.value = inbox;

  final Rx<AppProfile> _profile = AppProfile().obs;
  AppProfile get profile => _profile.value;
  set profile(AppProfile profile) => _profile.value = profile;

  String inboxRoomId = "";

  String profileIds = "";

  final RxList<AppProfile> _profiles = <AppProfile>[].obs;
  List<AppProfile> get profiles => _profiles;
  set profiles(List<AppProfile> profiles) => _profiles.value = profiles;

  bool isLiked = false;
  bool showHeart = false;

  int totalMessages = 0;
  @override
  void onInit() async {
    super.onInit();

    try {

      List<dynamic> arguments  = Get.arguments;
      if (Get.arguments[0] is Inbox) {
        inbox =  arguments.elementAt(0);
        inboxRoomId = inbox.id;
      } else if (Get.arguments[0] is String) {
        inboxRoomId = Get.arguments[0];
      }

      profile = userController.profile;
      timer = Timer.periodic(const Duration(seconds: 2), (timer) {
        logger.d("Verifying more Messages");
        loadMessages(inboxRoomId);
      });
    } catch (e) {
       logger.e(e.toString());
    }
  }

  @override
  void onReady() async {
    super.onReady();
    logger.d("InboxRoom Controller Ready");
  }



  @override
  FutureOr onClose() {
    timer.cancel();
  }


  void clear() {
    profile = AppProfile();
    messages = [];
  }


  @override
  void setMessageText(text) {
    messageText = text;
  }


  @override
  Future<void> loadMessages(String roomId) async {
    logger.d("$inboxRoomId Retrieving messages");

    try {
      messages = await _inboxFirestore.retrieveMessages(roomId);
    } catch (e) {
      logger.e(e.toString());
    }

    logger.d("Retrieving ${messages.length} messages");
    isLoading = false;
    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
  }


  @override
  Future<void> addMessage({InboxRoomType inboxRoomType = InboxRoomType.profile}) async {
    logger.d("Adding message to inbox room");
    InboxMessage message;

    sendingMessage = true;
    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);

    if (messageText.isNotEmpty || postUploadController.imageFile.path.isNotEmpty) {
      message = InboxMessage(
          ownerId: profile.id,
          profileName: profile.name,
          profileImgUrl: profile.photoUrl,
          text: messageText,
          createdTime: DateTime.now().millisecondsSinceEpoch
      );

      try {
        if(postUploadController.imageFile.path.isNotEmpty) {
          message.type = AppMediaType.image;
          message.mediaUrl = await postUploadController.handleUploadImage(UploadImageType.message);
        }

        if(await _inboxFirestore.addMessage(inboxRoomId, message, inboxRoomType: inboxRoomType)) {
          if(inboxRoomType == InboxRoomType.profile) {
            String itemmateId = inboxRoomId.replaceAll(profile.id, "");
            itemmateId = itemmateId.replaceAll("_", "");
            sendPushNotificationToFcm(
                toProfileId: itemmateId,
                fromProfile: profile,
                notificationType: PushNotificationType.message,
                referenceId: inboxRoomId,
                message: message.text,
                imgUrl: message.mediaUrl
            );
          }
        }
      } catch (e) {
        logger.e(e.toString());
      }

      logger.d("");
      clearMessage();
      sendingMessage = false;
      update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
    }
  }

  Future<void> handleImage(AppFileFrom appFileFrom) async {
    await postUploadController.handleImage(appFileFrom, isProfilePicture: true);
    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
  }

  void clearMessage()  {
    messageText = "";
    messageController.clear();
    postUploadController.clearImage();
    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
  }

  bool isLikedMessage(InboxMessage message) {
    return message.likedProfiles.contains(profile.id);
  }

  Future<void> handleLikeMessage(InboxMessage message) async {

    isLiked = isLikedMessage(message);

    if (await _inboxFirestore.handleLikeMessage(profile.id, message.id, isLiked)) {

      isLiked ? message.likedProfiles.remove(profile.id)
          : message.likedProfiles.add(profile.id);
    }

    update([AppPageIdConstants.inboxRoom, AppPageIdConstants.bandRoom]);
  }

}
