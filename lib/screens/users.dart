import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:azlistview/azlistview.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_svg/svg.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:verdiscom/util/util.dart';

import 'chat.dart';
import 'create_group_chat.dart';

Widget finalAction = const Icon(Icons.check);

List<types.User> chatList = [];
List chatListNames = [];

void _handlePressed(List userList, BuildContext context) async {
  if (userList.isEmpty) {
    edgeAlert(context,
        title: 'select one or more people',
        description:
        "Select one person to create DM or select multiple people to create a group chat!",
        duration: 2,
        gravity: Gravity.bottom,
        icon: Icons.error_outline_outlined,
        backgroundColor: (() {
          if (Theme.of(context).brightness == Brightness.light) {
            return Colors.grey;
          } else {}
        }()));
  } else if (userList.length == 1) {
    types.User otherUser = userList[0];
    final room = await FirebaseChatCore.instance.createRoom(otherUser);

    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          backupName: otherUser.firstName!,
          room: room,
          avatar: (() {
            if (otherUser.imageUrl!.split(".").last == 'svg') {
              return ClipOval(
                child: SvgPicture.network(
                  otherUser.imageUrl!,
                  width: 40,
                  height: 40,
                  semanticsLabel: 'profile picture',
                  placeholderBuilder: (BuildContext context) =>
                  const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator()),
                ),
              );
            } else {
              final hasImage = otherUser.imageUrl != null;

              var color = Colors.transparent;

              if (room.type == types.RoomType.direct) {
                try {
                  final otherUser = room.users.firstWhere(
                        (u) =>
                    u.id != FirebaseChatCore.instance.firebaseUser?.uid,
                  );

                  color = getUserAvatarNameColor(otherUser);
                } catch (e) {
                  // Do nothing if other user is not found
                }
              }

              return CachedNetworkImage(
                imageUrl: otherUser.imageUrl!,
                fit: BoxFit.fill,
                width: 40,
                height: 40,
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  radius: 20,
                  backgroundImage: imageProvider,
                  backgroundColor: hasImage ? Colors.transparent : color,
                  child: !hasImage
                      ? Text(
                    room.name!.isEmpty
                        ? ''
                        : room.name![0].toUpperCase(),
                    style: TextStyle(color: Theme.of(context).primaryColorLight),
                  )
                      : null,
                ),
                placeholder: (context, url) => const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const SizedBox(
                    height: 40, width: 40, child: Icon(Icons.error)),
              );
            }
          }()),
        ),
      ),
    );
  } else {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => GCPage(chatList: chatList.toSet().toList(), chatListNames: chatListNames.toSet().toList())
      ),
    );
  }
}

class Colours {
  static const Color gray_33 = Color(0xFF333333);
  static const Color gray_66 = Color(0xFF666666);
  static const Color gray_99 = Color(0xFF999999);
}

class Utils {
  static String getImgPath(String name, {String format = 'png'}) {
    return 'assets/images/$name.$format';
  }
}

class UserModel extends ISuspensionBean {
  String name;
  String tagIndex;
  String? avatarUrl;
  types.User user;

  UserModel({
    required this.name,
    required this.tagIndex,
    required this.avatarUrl,
    required this.user,
  });

  UserModel.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        tagIndex = json['tagIndex'],
        avatarUrl = json['avatarUrl'],
        user = json['user'];

  Map<String, dynamic> toJson() =>
      {'name': name, 'tagIndex': tagIndex, 'avatarUrl': avatarUrl, 'user': user};

  @override
  String getSuspensionTag() => tagIndex;

  @override
  String toString() => json.encode(this);
}

class UsersPage extends StatefulWidget {
  const UsersPage({
    Key? key,
    this.fromType,
    this.initialIDList,
    this.isOptionsPage,
    this.roomID
  }) : super(key: key);
  final int? fromType;
  final List? initialIDList;
  final bool? isOptionsPage;
  final String? roomID;

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  /// Controller to scroll or jump to a particular item.
  final ItemScrollController itemScrollController = ItemScrollController();

  final CollectionReference _collectionRef =
  FirebaseFirestore.instance.collection('users');

  List<UserModel> originList = [];
  List<UserModel> dataList = [];
  Map boolMap = {};

  late TextEditingController textEditingController;

  @override
  void initState() {
    if (widget.initialIDList != null) {
      for (var element in widget.initialIDList!) {
        boolMap[element] = const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          child: Icon(Icons.done),
        );
      }
    }

    super.initState();
    chatListNames = [];
    chatList = [];
    textEditingController = TextEditingController();
    loadData();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl!.split(".").last == 'svg') {
      return ClipOval(
        child: SvgPicture.network(
          avatarUrl,
          width: 40,
          height: 40,
          semanticsLabel: 'profile picture',
          placeholderBuilder: (BuildContext context) => const SizedBox(
              height: 40, width: 40, child: CircularProgressIndicator()),
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.fill,
        width: 40,
        height: 40,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: 20,
          backgroundImage: imageProvider,
          backgroundColor: Colors.transparent,
        ),
        placeholder: (context, url) => const SizedBox(
            height: 40, width: 40, child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
        const SizedBox(height: 40, width: 40, child: Icon(Icons.error)),
      );
    }
  }

  void loadData() async {
    // Get docs from collection reference
    QuerySnapshot querySnapshot = await _collectionRef.get();

    // Get data from docs and convert map to List
    originList = querySnapshot.docs
        .map((doc) {
      Map<String, dynamic> userMap = doc.data() as Map<String, dynamic>;
      userMap['createdAt'] = userMap['createdAt']?.millisecondsSinceEpoch;
      userMap['id'] = doc.id;
      userMap['lastSeen'] = userMap['lastSeen']?.millisecondsSinceEpoch;
      userMap['updatedAt'] = userMap['updatedAt']?.millisecondsSinceEpoch;

      return UserModel(
        name: userMap['firstName'],
        tagIndex: userMap['role'] ?? "user",
        avatarUrl: userMap['imageUrl'],
        user: types.User.fromJson(userMap),
      );
    })
        .toList();

    originList.remove(originList.firstWhere((element) => element.user.id == FirebaseAuth.instance.currentUser!.uid));

    _handleList(originList);
  }

  void _handleList(List<UserModel> list) {
    dataList.clear();
    if (list.isEmpty) {
      setState(() {});
      return;
    }
    dataList.addAll(list);

    // A-Z sort.
    SuspensionUtil.sortListBySuspensionTag(dataList);

    // show sus tag.
    SuspensionUtil.setShowSuspensionStatus(dataList);

    setState(() {});

    if (itemScrollController.isAttached) {
      itemScrollController.jumpTo(index: 0);
    }
  }

  Widget getSusItem(BuildContext context, String tag, {double susHeight = 40}) {
    return Container(
      height: susHeight,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(left: 16.0),
      color: const Color.fromARGB(40, 197, 203, 209),
      alignment: Alignment.centerLeft,
      child: Text(
        tag,
        softWrap: false,
        style: const TextStyle(
          fontSize: 14.0,
          color: Color(0xFF666666),
        ),
      ),
    );
  }

  Widget getListItem(BuildContext context, UserModel model,
      {double susHeight = 40}) {
    return ListTile(
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOutQuart,
        switchOutCurve: Curves.easeInOutQuart,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(child: child, opacity: animation);
        },
        child: boolMap[model.user.id] ?? _buildAvatar(model.avatarUrl),
      ),
      title: Text(model.name),
      onTap: () {
        setState(() {

          if (boolMap[model.user.id] == null) {
            boolMap[model.user.id] = const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.done),
            );
            chatListNames.add(model.name);
            chatList.add(model.user);
            chatListNames = chatListNames.toSet().toList();
            chatList = chatList.toSet().toList();
          } else {
            boolMap[model.user.id] = null;
            chatListNames.remove(model.name);
            chatList.remove(model.user);
            chatListNames = chatListNames.toSet().toList();
            chatList = chatList.toSet().toList();
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (widget.isOptionsPage == true) {
            setState(() {
              finalAction = const CircularProgressIndicator(color: Colors.white,);
            });
            List returnList = boolMap.entries.map((e) {
              if (e.value != null) {
                return e.key;
              }
            }).toList();
            returnList.add(FirebaseAuth.instance.currentUser!.uid);
            returnList = returnList.where((c) => c != null).toList();

            await FirebaseFirestore.instance.collection('rooms').doc(widget.roomID).set(
              {
                'userIds': returnList.toSet().toList(),
              },
              SetOptions(merge: true),
            );
            setState(() {
              finalAction = const Icon(Icons.check);
            });
            Navigator.pop(context);
            Navigator.pop(context);
            Navigator.pop(context);
          } else {
            _handlePressed(chatList, context);
          }
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: finalAction,
      ),
      appBar: AppBar(
        foregroundColor: Theme.of(context).appBarTheme.toolbarTextStyle!.color,
        backgroundColor: (() {
          if (Theme.of(context).brightness == Brightness.light) {
            return Colors.white;
          } else {
            return Colors.grey.shade800;
          }
        }()),
        title: const Text('Create Chat'),
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color.fromARGB(255, 225, 226, 230),
                      width: 0.33),
                  color: const Color.fromARGB(255, 239, 240, 244),
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                autofocus: false,
                onChanged: (text) {
                  if (text.isEmpty) {
                    _handleList(originList);
                  } else {
                    List<UserModel> list = originList.where((v) {
                      return v.name.toLowerCase().contains(text.toLowerCase());
                    }).toList();
                    _handleList(list);
                  };
                },
                controller: textEditingController,
                decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colours.gray_33,
                    ),
                    suffixIcon: Offstage(
                      offstage: textEditingController.text.isEmpty,
                      child: InkWell(
                        onTap: () {
                          textEditingController.clear();
                          _handleList(originList);
                        },
                        child: const Icon(
                          Icons.cancel,
                          color: Colours.gray_99,
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    hintText: 'Search Users',
                    hintStyle: const TextStyle(color: Colours.gray_99)),
              ),
            ),
            Expanded(
              child: AzListView(
                data: dataList,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: dataList.length,
                itemBuilder: (BuildContext context, int index) {
                  UserModel model = dataList[index];
                  return getListItem(context, model);
                },
                itemScrollController: itemScrollController,
                susItemBuilder: (BuildContext context, int index) {
                  UserModel model = dataList[index];
                  return getSusItem(context, model.getSuspensionTag());
                },
                indexBarOptions: IndexBarOptions(
                  needRebuild: true,
                  selectTextStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                  selectItemDecoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF333333)),
                  indexHintWidth: 96,
                  indexHintHeight: 97,
                  indexHintDecoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          Utils.getImgPath('ic_index_bar_bubble_white')),
                      fit: BoxFit.contain,
                    ),
                  ),
                  indexHintAlignment: Alignment.centerRight,
                  indexHintTextStyle:
                  const TextStyle(fontSize: 24.0, color: Colors.black87),
                  indexHintOffset: const Offset(-30, 0),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
