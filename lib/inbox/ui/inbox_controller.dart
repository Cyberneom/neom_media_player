import 'dart:collection';

import 'package:get/get.dart';
import 'package:neom_commons/core/data/firestore/inbox_firestore.dart';
import 'package:neom_commons/core/data/firestore/profile_firestore.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/inbox.dart';
import 'package:neom_commons/core/domain/model/inbox_message.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';

import '../domain/use_cases/inbox_service.dart';

class InboxController extends GetxController implements InboxService {

  final userController = Get.find<UserController>();

  String profileIds = "";

  final RxString location = "".obs;
  final RxString messageText = "".obs;
  final RxList<Inbox> inboxs = <Inbox>[].obs;
  final RxBool isLoading = true.obs;
  final RxList<InboxMessage> inboxMessages = <InboxMessage>[].obs;
  final Rx<AppProfile> profile = AppProfile().obs;
  final RxList<AppProfile> profiles = <AppProfile>[].obs;
  final Rx<SplayTreeMap<int, Inbox>> sortedInbox = SplayTreeMap<int, Inbox>().obs;


  @override
  void onInit() async {
    super.onInit();
    profile.value = userController.profile;
  }


  @override
  void onReady() async {
    super.onReady();
    AppUtilities.logger.t("Inbox Controller Ready");
    await loadInbox();
    isLoading.value = false;
    update([AppPageIdConstants.inbox]);

  }


  Future<void> loadItemmateDetails() async {

    try {
      for (var inbox in sortedInbox.value.values) {
        for (var itemmateId in inbox.profileIds) {
          if(itemmateId != profile.value.id) {
            for (var profile in inbox.profiles!) {
              if(profile.id.isEmpty) {
                AppProfile itemmate =  await ProfileFirestore().retrieveSimple(itemmateId);
                int currentIndex = inbox.profiles!.indexOf(profile);
                inbox.profiles![currentIndex] = itemmate;
              }
            }
          }
        }
      }
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }

    update([AppPageIdConstants.inbox]);
  }


  void clear() {
    profile.value = AppProfile();
    inboxs.value = [];
  }

  @override
  Future<void> loadInbox() async {
    AppUtilities.logger.t("Load Inbox");
    try {
      inboxs.value = await InboxFirestore().getProfileInbox(profile.value.id);

      for (var inbox in inboxs) {
        sortedInbox.value[inbox.lastMessage!.createdTime] = inbox;
      }
      loadItemmateDetails();
    } catch (e) {
      AppUtilities.logger.e(e.toString());
    }
  }

}
