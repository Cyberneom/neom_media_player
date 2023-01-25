import 'dart:async';

abstract class InboxRoomService {

  void setMessageText(text);
  Future<void> loadMessages(String inboxRoomId);
  Future<void> addMessage();

}
