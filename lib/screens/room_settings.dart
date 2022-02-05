import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:verdiscom/util/const.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mime/mime.dart';
import 'package:verdiscom/screens/users.dart';
import 'package:verdiscom/widgets/custom_input.dart';
import 'chat.dart';
import '../util/util.dart';
import 'package:verdiscom/util/editable_image.dart';
import 'package:universal_io/io.dart' as uio;
import 'package:uuid/uuid.dart';

final TextEditingController input = TextEditingController();
Widget finalAction = const Icon(Icons.check);

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

class RoomSettings extends StatefulWidget {
  const RoomSettings({Key? key, required this.chatList, required this.initialImage, required this.initialName, required this.room, required this.isAdmin}) : super(key: key);

  final List<types.User> chatList;
  final String? initialName;
  final Widget? initialImage;
  final types.Room room;
  final bool isAdmin;

  @override
  State<RoomSettings> createState() => _RoomSettingsState();
}

class _RoomSettingsState extends State<RoomSettings> {
  CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');

  @override
  initState() {
    super.initState();
  }

  Uint8List? _profilePicFile;
  bool imageChanged = false;

  // A simple usage of EditableImage.
// This method gets called when trying to change an image.
  void _directUpdateImage(Uint8List file) async {
    _profilePicFile = file;
    imageChanged = true;

    setState(() {});
  }

  void _handlePressed(List userList, BuildContext context) async {
    userList = userList.toSet().toList();
    String inputText = '';
    setState(() {
      finalAction = const CircularProgressIndicator(color: Colors.white,);
    });

    if (input.text.isEmpty) {
        inputText = widget.room.name!;
    } else {
      inputText = input.text;
    }

      if (imageChanged) {
        var uuid = const Uuid();
        final _firebaseStorage = FirebaseStorage.instance;

        Reference ref =
        _firebaseStorage.ref(
            'groupChats/${FirebaseAuth.instance.currentUser!.uid}/${uuid.v4()}.${lookupMimeType('', headerBytes: _profilePicFile)!.split('/')[1]}');

        SettableMetadata metadata =
        SettableMetadata(
            contentType: lookupMimeType('',
                headerBytes: _profilePicFile));

        await ref.putData(_profilePicFile!, metadata);

        var downloadUrl = await ref.getDownloadURL();

        await rooms.doc(widget.room.id).set(
          {
            'name': input.text,
            'imageUrl': downloadUrl
          },
          SetOptions(merge: true),
        );
      } else {
        await rooms.doc(widget.room.id).set(
          {
            'name': input.text,
          },
          SetOptions(merge: true),
        );
      }

      setState(() {
        finalAction = const Icon(Icons.check);
      });

      Navigator.of(context).pop();
      Navigator.of(context).pop();
  }

  Widget _buildAvatar(types.User user) {
    final color = getUserAvatarNameColor(user);
    final hasImage = user.imageUrl != null;
    final name = getUserName(user);

    return Card(
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: ListTile(
          leading: Hero(
            tag: name,
            child: (() {
              if (user.imageUrl!.split(".").last == 'svg') {
                return ClipOval(
                  child: SvgPicture.network(
                    user.imageUrl!,
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
                return CachedNetworkImage(
                  imageUrl: user.imageUrl!,
                  fit: BoxFit.fill,
                  width: 40,
                  height: 40,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 20,
                    backgroundImage: imageProvider,
                    backgroundColor: hasImage ? Colors.transparent : color,
                    child: !hasImage
                        ? Text(
                      name.isEmpty ? '' : name[0].toUpperCase(),
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
          title: Hero(
              tag: name + " name",
              child: Material(
                  color: Colors.transparent,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18.0,
                    ),
                  ))),
          trailing: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection("rooms").doc(widget.room.id).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  return Text((() {
                    String? roleText = snapshot.data!.data()!['userRoles'][user
                        .id];
                    return (roleText ?? "user").capitalize();
                  }()));
                } else {
                  return const Text("error data");
                }
              }

              if (!snapshot.hasData) {
                return const SizedBox();
              }

              return const SizedBox();
            },
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: (() {
        if (widget.isAdmin) {
          return FloatingActionButton(
            onPressed: () {
              _handlePressed(widget.chatList, context);
            },
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: finalAction,
          );
        } else {
          return null;
        }
      } ()),
      appBar: AppBar(
        foregroundColor: Theme.of(context).appBarTheme.toolbarTextStyle!.color,
        backgroundColor: (() {
          if (Theme.of(context).brightness == Brightness.light) {
            return Colors.white;
          } else {
            return Colors.grey.shade800;
          }
        }()),
        title: const Text('Group Chat Options'),
      ),
      body: ListView.builder(
        itemCount: widget.chatList.length + 7,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(40, 50, 40, 0),
              child: EditableImage(
                isEditable: widget.isAdmin,
                widgetDefault: widget.initialImage,
// Define the method that will run on the change process of the image.
                onChange: (file) => _directUpdateImage(file),

// Define the source of the image.
                image: (_profilePicFile != null)
                    ? Image.memory(_profilePicFile!, fit: BoxFit.cover)
                    : null,

// Define the size of EditableImage.
                size: 150.0,

// Define the Theme of image picker.
                imagePickerTheme: ThemeData(
                  // Define the default brightness and colors.
                  primaryColor: Colors.white,
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.white70,
                  iconTheme: const IconThemeData(color: Colors.black87),

                  // Define the default font family.
                  fontFamily: 'Georgia',
                ),

// Define the border of the image if needed.
                imageBorder: Border.all(color: Colors.black87, width: 2.0),

// Define the border of the icon if needed.
                editIconBorder: Border.all(color: Colors.black87, width: 2.0),
              ),
            );
          } else if (index == 1) {
            return const SizedBox(
              height: 20,
            );
          } else if (index == 2) {
            if (widget.isAdmin == true) {
              return CustomInput(
                autoFillController: input,
                onChanged: (string) {},
                hintText: widget.initialName ?? 'Enter Chat Name',
                onSubmitted: (string) {},
              );
            } else {
              return Center(child: Text(widget.initialName ?? 'No Chat Name', style: const TextStyle(
                  fontSize: 24.0, fontWeight: FontWeight.w600), textAlign: TextAlign.center,));
            }
          } else if (index == 3) {
            return const SizedBox(
              height: 40,
            );
          } else if (index == 4) {
            return Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (() {
                      if (widget.isAdmin) {
                        return IconButton(onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => UsersPage(initialIDList: widget.chatList.map((e) => e.id).toList(), isOptionsPage: true, roomID: widget.room.id),
                            ),
                          );
                        }, icon: const Icon(Icons.edit));
                      } else {
                        return const SizedBox();
                      }
                    } ()),
                    const Text(
                      "Members:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ));
          } else if (index == 5) {
            return const SizedBox(
              height: 20,
            );
          }

          index -= 6;
          late types.User user;

          try {
            user = widget.chatList[index];
          } catch (e) {
            return Center(
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Are you sure you want to leave?'),
                                  content:
                                  Text('This action cannot be undone'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        var roomData = rooms.doc(widget.room.id).get();
                                        var roomMap = (await roomData).data()! as Map;
                                        List adminList = roomMap['userRoles'].entries.map((e) {
                                          if (e.value == "admin") {
                                            return e.key;
                                          }
                                        }).toList();
                                        adminList = adminList.where((c) => c != null).toList();

                                        if (adminList.length == 1 && adminList.contains(FirebaseAuth.instance.currentUser!.uid)) {
                                          Navigator.pop(context);
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('Error!'),
                                                  content:
                                                  const Text('Please select a new admin before you leave'),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text('OK'),
                                                    ),
                                                  ],
                                                );
                                              });
                                        } else {
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                          Navigator.pop(context);

                                          List returnList = roomMap['userIds'];
                                          returnList.remove(
                                              FirebaseAuth.instance.currentUser!
                                                  .uid);

                                          await rooms.doc(widget.room.id).set(
                                            {
                                              'userIds': returnList,
                                            },
                                            SetOptions(merge: true),
                                          );
                                        }
                                      },
                                      child: const Text('Confirm', style: TextStyle(color: Colors.red),),
                                    ),
                                  ],
                                );
                              });
                        },
                      child: Container(
                        height: 50,
                          width: 150,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            color: Colors.red[400]!
                          ),
                          child: Center(child: Text("Leave Group Chat", textAlign: TextAlign.center, style: TextStyle(color: Colors.white),))
                      ),
            ),
                      (() {
                        if (widget.isAdmin) {
                          return SizedBox(width: 20);
                        } else {
                          return const SizedBox();
                        }
                      } ()),
                      (() {
                        if (widget.isAdmin) {
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Are you sure you want to delete the group chat?'),
                                      content:
                                      Text('This action cannot be undone'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                            await rooms.doc(widget.room.id).delete();
                                          },
                                          child: const Text('Confirm', style: TextStyle(color: Colors.red),),
                                        ),
                                      ],
                                    );
                                  });
                            },
                            child: Container(
                                height: 50,
                                width: 150,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                    color: Colors.red[400]!
                                ),
                                child: Center(child: Text("Delete Group Chat", textAlign: TextAlign.center, style: TextStyle(color: Colors.white),))
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      } ()),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            );
          }

          if (user.id == FirebaseAuth.instance.currentUser!.uid || widget.isAdmin != true) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: _buildAvatar(user),
            );
          } else {
            return InkWell(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return SimpleDialog(
                          title: const Text("Change User Role"),
                          children: <Widget>[
                            SimpleDialogOption(
                              onPressed: () async {
                                await rooms.doc(widget.room.id).set(
                                  {
                                    'userRoles': {
                                      user.id: "admin"
                                    },
                                  },
                                  SetOptions(merge: true),
                                );

                                Navigator.pop(context);
                              },
                              child: const Text('Admin'),
                            ),
                            SimpleDialogOption(
                              onPressed: () async {
                                await rooms.doc(widget.room.id).set(
                                  {
                                    'userRoles': {
                                      user.id: "user"
                                    },
                                  },
                                  SetOptions(merge: true),
                                );

                                Navigator.pop(context);
                              },
                              child: const Text('User'),
                            ),
                          ]);
                    });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                child: _buildAvatar(user),
              ),
            );
          }
        },
      ),
    );
  }
}
