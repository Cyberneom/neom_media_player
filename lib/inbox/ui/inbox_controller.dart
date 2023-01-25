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

  var logger = AppUtilities.logger;
  final userController = Get.find<UserController>();

  final RxString _location = "".obs;
  String get location => _location.value;
  set location(String location) => _location.value = location;

  final RxString _messageText = "".obs;
  String get message => _messageText.value;
  set message(String message) => _messageText.value = message;

  final RxList<Inbox> _inboxs = <Inbox>[].obs;
  List<Inbox> get inboxs => _inboxs;
  set inboxs(List<Inbox> inboxs) => _inboxs.value = inboxs;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;

  final RxList<InboxMessage> _inboxMessages = <InboxMessage>[].obs;
  List<InboxMessage> get inboxMessages => _inboxMessages;
  set inboxMessages(List<InboxMessage> inboxMessages) => _inboxMessages.value = inboxMessages;

  final Rx<AppProfile> _profile = AppProfile().obs;
  AppProfile get profile => _profile.value;
  set profile(AppProfile profile) => _profile.value = profile;

  String profileIds = "";

  final RxList<AppProfile> _profiles = <AppProfile>[].obs;
  List<AppProfile> get profiles => _profiles;
  set profiles(List<AppProfile> profiles) => _profiles.value = profiles;

  final Rx<SplayTreeMap<int, Inbox>> _sortedInbox = SplayTreeMap<int, Inbox>().obs;
  SplayTreeMap<int, Inbox> get sortedInbox => _sortedInbox.value;
  set sortedInbox(SplayTreeMap<int, Inbox> sortedInbox) => this.sortedInbox = sortedInbox;


  @override
  void onInit() async {
    super.onInit();
    profile = userController.profile;
  }


  @override
  void onReady() async {
    super.onReady();
    logger.d("Inbox Controller Ready");
    await loadInbox();
    isLoading = false;
    update([AppPageIdConstants.inbox]);

  }


  Future<void> loadItemmateDetails() async {

    try {
      for (var inbox in sortedInbox.values) {
        for (var itemmateId in inbox.profileIds) {
          if(itemmateId != profile.id) {
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
      logger.e(e.toString());
    }

    update([AppPageIdConstants.inbox]);
  }


  void clear() {
    profile = AppProfile();
    inboxs = [];
  }

  @override
  Future<void> loadInbox() async {
    logger.d("");
    try {
      inboxs = await InboxFirestore().getProfileInbox(profile.id);

      for (var inbox in inboxs) {
        sortedInbox[inbox.lastMessage!.createdTime] = inbox;
      }
      loadItemmateDetails();
    } catch (e) {
      logger.e(e.toString());
    }
  }

}
