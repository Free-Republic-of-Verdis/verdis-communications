import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:verdiscom/screens/room_settings.dart';
import 'package:verdiscom/screens/user_view.dart';
import 'package:verdiscom/service/confrence_service.dart';
import 'package:verdiscom/model/confrence.dart' as model;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';

import 'home.dart';

CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');
CollectionReference users = FirebaseFirestore.instance.collection('users');

FirebaseDatabase database = FirebaseDatabase.instance;

Future<void> sendNotification(
    String message, List idsTo, String username, String roomID) async {
  HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('sendNotification');
  await callable.call(<String, dynamic>{
    'message': message,
    'idsTo': idsTo,
    'username': username,
    'roomID': roomID
  });
}

class ChatPage extends StatefulWidget {
  const ChatPage(
      {Key? key,
      required this.room,
      required this.avatar,
      required this.backupName})
      : super(key: key);

  final types.Room room;
  final Widget avatar;
  final String backupName;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _isAttachmentUploading = false;

  void _handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 144,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleImageSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Photo'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleFileSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('File'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      _setAttachmentUploading(true);
      final name = result.files.single.name;
      final filePath = result.files.single.path!;
      final file = File(filePath);

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialFile(
          mimeType: lookupMimeType(filePath),
          name: name,
          size: result.files.single.size,
          uri: uri,
        );

        FirebaseChatCore.instance.sendMessage(message, widget.room.id);
        _setAttachmentUploading(false);

        var roomData = rooms.doc(widget.room.id).get();
        var roomMap = (await roomData).data()! as Map;
        roomMap['updatedAt'] = Timestamp.now();

        // sends notifications
        if (widget.room.type == types.RoomType.direct) {
          print("room is direct");
          List userList = [];
          userList.addAll(roomMap['userIds']);
          userList.remove(FirebaseAuth.instance.currentUser!.uid);

          print("userList is ${userList}");

          DatabaseReference ref = FirebaseDatabase.instance
              .ref("users/${userList[0]}/status");
          DatabaseEvent event = await ref.once();

          if (event.snapshot.value == false) {
            print("sending notification");
            await sendNotification(
                "Sent a file", userList, username, widget.room.id);
          }
        } else if (widget.room.type == types.RoomType.group) {
          print("room is group");
          List userList = [];
          List finalUserList = [];
          userList.addAll(roomMap['userIds']);
          userList = userList.toSet().toList();
          userList.remove(FirebaseAuth.instance.currentUser!.uid);

          for (String userID in userList) {
            DatabaseReference ref = FirebaseDatabase.instance
                .ref("users/$userID/status");
            DatabaseEvent event = await ref.once();

            if (event.snapshot.value == false) {
              finalUserList.add(userID);
            }
          }

          print("userList is $finalUserList");

          if (finalUserList.isNotEmpty) {
            print("sending notification");
            await sendNotification("Sent a file", finalUserList,
                "$username - ${widget.room.name!}", widget.room.id);
          }
        }
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      _setAttachmentUploading(true);
      final file = File(result.path);
      final size = file.lengthSync();
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final name = result.name;

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialImage(
          height: image.height.toDouble(),
          name: name,
          size: size,
          uri: uri,
          width: image.width.toDouble(),
        );

        FirebaseChatCore.instance.sendMessage(
          message,
          widget.room.id,
        );
        _setAttachmentUploading(false);

        CollectionReference rooms =
            FirebaseFirestore.instance.collection('rooms');
        CollectionReference users =
            FirebaseFirestore.instance.collection('users');
        var roomData = rooms.doc(widget.room.id).get();
        var roomMap = (await roomData).data()! as Map;
        roomMap['updatedAt'] = Timestamp.now();

        // sends notifications
        if (widget.room.type == types.RoomType.direct) {
          print("room is direct");
          List userList = [];
          userList.addAll(roomMap['userIds']);
          userList.remove(FirebaseAuth.instance.currentUser!.uid);

          print("userList is ${userList}");

          DatabaseReference ref = FirebaseDatabase.instance
              .ref("users/${userList[0]}/status");
          DatabaseEvent event = await ref.once();

          if (event.snapshot.value == false) {
            print("sending notification");
            await sendNotification(
                "Sent an image", userList, username, widget.room.id);
          }
        } else if (widget.room.type == types.RoomType.group) {
          print("room is group");
          List userList = [];
          List finalUserList = [];
          userList.addAll(roomMap['userIds']);
          userList = userList.toSet().toList();
          userList.remove(FirebaseAuth.instance.currentUser!.uid);

          for (String userID in userList) {
            DatabaseReference ref = FirebaseDatabase.instance
                .ref("users/$userID/status");
            DatabaseEvent event = await ref.once();

            if (event.snapshot.value == false) {
              finalUserList.add(userID);
            }
          }

          print("userList is $finalUserList");

          if (finalUserList.isNotEmpty) {
            print("sending notification");
            await sendNotification("Sent an image", finalUserList,
                "$username - ${widget.room.name!}", widget.room.id);
          }
        }
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        final client = http.Client();
        final request = await client.get(Uri.parse(message.uri));
        final bytes = request.bodyBytes;
        final documentsDir = (await getApplicationDocumentsDirectory()).path;
        localPath = '$documentsDir/${message.name}';

        if (!File(localPath).existsSync()) {
          final file = File(localPath);
          await file.writeAsBytes(bytes);
        }
      }

      await OpenFile.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final updatedMessage = message.copyWith(previewData: previewData);

    FirebaseChatCore.instance.updateMessage(updatedMessage, widget.room.id);
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    FirebaseChatCore.instance.sendMessage(
      message,
      widget.room.id,
    );

    print("message.text is ${message.text}");

    CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    var roomData = rooms.doc(widget.room.id).get();
    var roomMap = (await roomData).data()! as Map;
    roomMap['updatedAt'] = Timestamp.now();

    // sends notifications
    if (widget.room.type == types.RoomType.direct) {
      print("room is direct");
      List userList = [];
      userList.addAll(roomMap['userIds']);
      userList.remove(FirebaseAuth.instance.currentUser!.uid);

      print("userList is ${userList}");

      DatabaseReference ref = FirebaseDatabase.instance
          .ref("users/${userList[0]}/status");
      DatabaseEvent event = await ref.once();

      if (event.snapshot.value == false) {
        print("sending notification");
        await sendNotification(
            message.text, userList, username, widget.room.id);
      }
    } else if (widget.room.type == types.RoomType.group) {
      print("room is group");
      List userList = [];
      List finalUserList = [];
      userList.addAll(roomMap['userIds']);
      print("userList before is $userList");
      userList = userList.toSet().toList();
      print("userList after is $userList");
      userList.remove(FirebaseAuth.instance.currentUser!.uid);

      for (String userID in userList) {
        DatabaseReference ref = FirebaseDatabase.instance
            .ref("users/$userID/status");
        DatabaseEvent event = await ref.once();

        if (event.snapshot.value == false) {
          finalUserList.add(userID);
        }
      }

      print("userList is $finalUserList");

      if (finalUserList.isNotEmpty) {
        print("sending notification");
        await sendNotification(message.text, finalUserList,
            "$username - ${widget.room.name!}", widget.room.id);
      }
    }

    await rooms.doc(widget.room.id).set(
          roomMap,
          SetOptions(merge: true),
        );
  }

  void _setAttachmentUploading(bool uploading) {
    setState(() {
      _isAttachmentUploading = uploading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Theme.of(context).appBarTheme.toolbarTextStyle!.color,
        backgroundColor: (() {
          if (Theme.of(context).brightness == Brightness.light) {
            return Colors.white;
          } else {
            return Colors.grey.shade800;
          }
        }()),
        title: (() {
            if (widget.room.type == types.RoomType.direct) {
              types.User otherUser = widget.room.users.firstWhere(
                (u) => u.id != FirebaseAuth.instance.currentUser!.uid,
              );

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      Map userMap = (await users.doc(otherUser.id).get()).data()! as Map;
                      Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (_) => UserView(profile: widget.avatar, userData: userMap, isAdmin: false, userID: otherUser.id,)));
                    },
                    child: Hero(
                      tag: widget.room.name ?? widget.backupName,
                      child: widget.avatar,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Flexible(
                    child: Text(
                      widget.room.name ?? widget.backupName,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                          color: Theme.of(context).appBarTheme.toolbarTextStyle!.color),
                    ),
                  ),
                  const SizedBox(width: 10),
                  StreamBuilder<DatabaseEvent>(
                    stream: FirebaseDatabase.instance
                        .ref("users/${otherUser.id}")
                        .onValue,
                    builder: (BuildContext context,
                        AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (snapshot.hasError) {
                        return const Text("Something went wrong");
                      }

                      bool status = false;
                      try {
                        if ((snapshot.data?.snapshot.value as Map)['status'] ==
                            true) {
                          status = true;
                        }
                      } catch (e) {
                        status = false;
                      }

                      if (snapshot.connectionState == ConnectionState.active) {
                        if (status == true) {
                          return Container(
                            height: 10,
                            width: 10,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              border: Border(),
                              shape: BoxShape.circle,
                            ),
                          );
                        } else {
                          return Container(
                            height: 10,
                            width: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              border: Border(),
                              shape: BoxShape.circle,
                            ),
                          );
                        }
                      }

                      return const SizedBox(width: 1, height: 1);
                    },
                  ),
                ],
              );
            } else {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: widget.room.name ?? widget.backupName,
                    child: widget.avatar,
                  ),
                  const SizedBox(width: 15),
                  Flexible(
                    child: Text(
                      widget.room.name ?? widget.backupName,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                          color: Theme.of(context).appBarTheme.toolbarTextStyle!.color),
                    ),
                  ),
                ],
              );
            }
          }()),
        actions: [
          (() {
            if (!kIsWeb) {
              return Padding(
                padding: (() {
                  if (widget.room.type != types.RoomType.group) {
                    return const EdgeInsets.only(right: 20.0);
                  } else {
                    return const EdgeInsets.only(right: 5.0);
                  }
                }()),
                child: IconButton(
                  onPressed: () async {
                    await ConfrenceService(
                            instance: model.Confrence(
                                avatarUrl: userData['imageUrl'],
                                subject: widget.room.name ?? widget.backupName,
                                displayName: username,
                                emailID:
                                    FirebaseAuth.instance.currentUser!.email!,
                                room: widget.room.id))
                        .connect();
                  },
                  icon: const Icon(
                    Icons.call,
                    size: 30,
                    color: Colors.green,
                  ),
                ),
              );
            } else {
              return Padding(
                padding: (() {
                  if (widget.room.type != types.RoomType.group) {
                    return const EdgeInsets.only(right: 20.0);
                  } else {
                    return const EdgeInsets.only(right: 5.0);
                  }
                }()),
                child: GestureDetector(
                  onTap: () async {
                    await ConfrenceService(
                            instance: model.Confrence(
                                avatarUrl: userData['imageUrl'],
                                subject: widget.room.name ?? widget.backupName,
                                displayName: username,
                                emailID:
                                    FirebaseAuth.instance.currentUser!.email!,
                                room: widget.room.id))
                        .urlLaunch();
                  },
                  child: const Icon(
                    Icons.call,
                    size: 30,
                    color: Colors.green,
                  ),
                ),
              );
            }
          }()),
          (() {
            if (widget.room.type == types.RoomType.group) {
              return Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: IconButton(
                  onPressed: () async {
                    var roomData = rooms.doc(widget.room.id).get();
                    var roomMap = (await roomData).data()! as Map;
                    List adminList = roomMap['userRoles'].entries.map((e) {
                      if (e.value == "admin") {
                        return e.key;
                      }
                    }).toList();
                    adminList = adminList.where((c) => c != null).toList();

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RoomSettings(
                                isAdmin: adminList.contains(
                                    FirebaseAuth.instance.currentUser!.uid),
                                chatList: widget.room.users,
                                initialImage: Hero(
                                  tag: widget.room.name ?? widget.backupName,
                                  child: widget.avatar,
                                ),
                                initialName: widget.room.name,
                                room: widget.room)));
                  },
                  icon: const Icon(
                    Icons.settings,
                    size: 30,
                  ),
                ),
              );
            } else {
              return const SizedBox();
            }
          }())
        ],
      ),
      body: StreamBuilder<types.Room>(
        initialData: widget.room,
        stream: FirebaseChatCore.instance.room(widget.room.id),
        builder: (context, snapshot) {
          return StreamBuilder<List<types.Message>>(
            initialData: const [],
            stream: FirebaseChatCore.instance.messages(snapshot.data!),
            builder: (context, snapshot) {
              return SafeArea(
                bottom: false,
                child: Chat(
                  showUserAvatars: true,
                  showUserNames: true,
                  theme: (() {
                    if (Theme.of(context).brightness == Brightness.light) {
                      return const DefaultChatTheme();
                    } else {
                      return const DarkChatTheme(
                          inputPadding: EdgeInsets.fromLTRB(24, 20, 24, 20),
                          inputMargin: EdgeInsets.zero);
                    }
                  }()),
                  isAttachmentUploading: _isAttachmentUploading,
                  messages: snapshot.data ?? [],
                  onAttachmentPressed: _handleAtachmentPressed,
                  onMessageTap: _handleMessageTap,
                  onPreviewDataFetched: _handlePreviewDataFetched,
                  onSendPressed: _handleSendPressed,
                  user: types.User(
                    id: FirebaseChatCore.instance.firebaseUser?.uid ?? '',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
