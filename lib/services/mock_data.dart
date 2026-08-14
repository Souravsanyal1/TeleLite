import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/telegram_controller.dart';
import '../models/models.dart';

class TelegramDataService extends ChangeNotifier {
  TelegramController get _controller => TelegramController.to;

  ThemeMode get themeMode => _controller.themeMode.value;
  bool get isPremium => _controller.isPremium.value;

  void setPremium(bool value) {
    _controller.setPremium(value);
    notifyListeners();
  }

  void toggleTheme() {
    _controller.toggleTheme();
    notifyListeners();
  }

  List<Chat> get chats => _controller.chats;
  List<GroupMember> getMembersForChat(String chatId) => _controller.getMembersForChat(chatId);
  List<Message> getMessagesForChat(String chatId) => _controller.getMessagesForChat(chatId);

  void markChatAsRead(String chatId) {
    _controller.markChatAsRead(chatId);
    notifyListeners();
  }

  void ensureChatExists(Chat chat) {
    _controller.ensureChatExists(chat);
    notifyListeners();
  }

  Chat getOrCreateChatForContact(Contact contact) {
    final res = _controller.getOrCreateChatForContact(contact);
    notifyListeners();
    return res;
  }

  void sendMessage(String chatId, String text, {String? mediaUrl, Chat? fallbackChat}) {
    _controller.sendMessage(chatId, text, mediaUrl: mediaUrl, fallbackChat: fallbackChat);
    notifyListeners();
  }

  void clearChatMessages(String chatId) {
    _controller.clearChatMessages(chatId);
    notifyListeners();
  }

  Chat createGroupChat({
    required String name,
    required String avatarUrl,
    String? description,
    List<Contact> members = const [],
  }) {
    final res = _controller.createGroupChat(
      name: name,
      avatarUrl: avatarUrl,
      description: description,
      members: members,
    );
    notifyListeners();
    return res;
  }

  Chat createChannelChat({
    required String name,
    required String description,
    String? username,
    String avatarUrl = '',
  }) {
    final res = _controller.createChannelChat(
      name: name,
      description: description,
      username: username,
      avatarUrl: avatarUrl,
    );
    notifyListeners();
    return res;
  }

  void updateGroupInfo(
    String chatId, {
    String? name,
    String? avatarUrl,
    String? username,
    String? description,
  }) {
    _controller.updateGroupInfo(
      chatId,
      name: name,
      avatarUrl: avatarUrl,
      username: username,
      description: description,
    );
    notifyListeners();
  }

  void addMembersToGroup(String chatId, List<Contact> newMembers) {
    _controller.addMembersToGroup(chatId, newMembers);
    notifyListeners();
  }

  void removeMemberFromGroup(String chatId, String memberId) {
    _controller.removeMemberFromGroup(chatId, memberId);
    notifyListeners();
  }

  void promoteToAdmin(String chatId, String memberId, {AdminRights? rights}) {
    _controller.promoteToAdmin(chatId, memberId, rights: rights);
    notifyListeners();
  }

  void updateAdminRights(String chatId, String memberId, AdminRights rights) {
    _controller.updateAdminRights(chatId, memberId, rights);
    notifyListeners();
  }

  void dismissAdmin(String chatId, String memberId) {
    _controller.dismissAdmin(chatId, memberId);
    notifyListeners();
  }

  Chat createSecretChat({required String name, required String avatarUrl}) {
    final res = _controller.createSecretChat(name: name, avatarUrl: avatarUrl);
    notifyListeners();
    return res;
  }

  void addContact(Contact contact) {
    _controller.addContact(contact);
    notifyListeners();
  }

  List<Contact> get contacts => _controller.contacts;
  List<CallItem> get calls => _controller.calls;
}

