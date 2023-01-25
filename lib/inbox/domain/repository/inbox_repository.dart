import 'dart:async';

import 'package:neom_commons/core/domain/model/app_profile.dart';
import 'package:neom_commons/core/domain/model/inbox.dart';
import 'package:neom_commons/core/domain/model/inbox_message.dart';

abstract class InboxRepository {

  Future<bool> addMessage(String inboxRoomId, InboxMessage message);
  Future<bool> handleLikeMessage(String profileId, String messageId, bool isLiked);

  Future<bool> inboxExists(String inboxId);

  Future<List<InboxMessage>> retrieveMessages(String inboxId);

  void searchInboxByName(String searchField);

  Future<bool> addInbox(Inbox inbox);
  Future<List<Inbox>> getProfileInbox(String profileId);

  Future<Inbox> getOrCreateInboxRoom(AppProfile profile, AppProfile itemmate);

  Stream listenToInboxRealTime(inboxRoomId);
}
