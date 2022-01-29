import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edge_alerts/edge_alerts.dart';
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

class GCPage extends StatefulWidget {
  const GCPage({Key? key, required this.chatList, required this.chatListNames}) : super(key: key);

  final List<types.User> chatList;
  final List chatListNames;

  @override
  State<GCPage> createState() => _GCPageState();
}

class _GCPageState extends State<GCPage> {
  @override
  void initState() {
    super.initState();
  }

  Uint8List ?_profilePicFile;

  // A simple usage of EditableImage.
// This method gets called when trying to change an image.
  void _directUpdateImage(Uint8List file) async {
    _profilePicFile = file;

    setState(() {});
  }

  void _handlePressed(List userList, BuildContext context) async {
    userList = userList.toSet().toList();

    if (input.text == "") {
      edgeAlert(context,
          title: 'please enter a name',
          description:
          "Names are mandatory, images are not!",
          duration: 2,
          gravity: Gravity.top,
          icon: Icons.error_outline_outlined,
          backgroundColor: (() {
            if (Theme.of(context).brightness == Brightness.light) {
              return Colors.grey;
            } else {}
          }()));
    } else if (input.text.length > 28) {
      edgeAlert(context,
          title: 'group chat name is too long',
          description:
          "There is a character limit of 28 for group chat names!",
          duration: 2,
          gravity: Gravity.top,
          icon: Icons.error_outline_outlined,
          backgroundColor: (() {
            if (Theme.of(context).brightness == Brightness.light) {
              return Colors.grey;
            } else {}
          }()));
    } else {
      setState(() {
        finalAction = const CircularProgressIndicator(color: Colors.white,);
      });

      late types.Room room;

      if (_profilePicFile != null) {
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

        room = await FirebaseChatCore.instance.createGroupRoom(
            users: widget.chatList, name: input.text, imageUrl: downloadUrl);
      } else {
        room = await FirebaseChatCore.instance.createGroupRoom(
            users: widget.chatList, name: input.text);
      }

      FirebaseFirestore.instance.collection('rooms').doc(room.id).set(
        {
          'userRoles': {
            FirebaseAuth.instance.currentUser!.uid: "admin"
          }
        },
        SetOptions(merge: true),
      );

      setState(() {
        finalAction = const Icon(Icons.check);
      });

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              ChatPage(
                backupName: "error",
                room: room,
                avatar: (() {
                  var color = Colors.transparent;

                  if (room.type == types.RoomType.direct) {
                    try {
                      final otherUser = room.users.firstWhere(
                            (u) => u.id != FirebaseAuth.instance.currentUser!.uid,
                      );

                      color = getUserAvatarNameColor(otherUser);
                    } catch (e) {
                      // Do nothing if other user is not found
                    }
                  }

                  final hasImage = room.imageUrl != null;
                  final name = room.name ?? '';

                  if (hasImage == false) {
                    return CircleAvatar(
                      backgroundColor: color,
                      backgroundImage: null,
                      radius: 20,
                      child: !hasImage
                          ? Text(
                        name.isEmpty ? '' : name[0].toUpperCase(),
                        style: TextStyle(color: Theme.of(context).primaryColorLight),
                      )
                          : null,
                    );
                  }
                  if (room.imageUrl!.split(".").last == 'svg') {
                    return ClipOval(
                      child: SvgPicture.network(
                        room.imageUrl!,
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
                      imageUrl: room.imageUrl!,
                      fit: BoxFit.fill,
                      width: 40,
                      height: 40,
                      imageBuilder: (context, imageProvider) =>
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: imageProvider,
                            backgroundColor: hasImage
                                ? Colors.transparent
                                : color,
                            child: !hasImage
                                ? Text(
                              room.name!.isEmpty
                                  ? ''
                                  : room.name![0].toUpperCase(),
                              style: TextStyle(color: Theme.of(context).primaryColorLight),
                            )
                                : null,
                          ),
                      placeholder: (context, url) =>
                      const SizedBox(
                          height: 40,
                          width: 40,
                          child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                      const SizedBox(
                          height: 40, width: 40, child: Icon(Icons.error)),
                    );
                  }
                }()),
              ),
        ),
      );
    }
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
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _handlePressed(widget.chatList, context);
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
        title: const Text('Group Chat Options'),
      ),
      body: ListView.builder(
        itemCount: widget.chatList.length + 6,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(40, 50, 40, 0),
              child: EditableImage(
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
            return CustomInput(
              autoFillController: input,
              onChanged: (string) {},
              hintText: 'Enter Chat Name',
              onSubmitted: (string) {},
            );
          } else if (index == 3) {
            return const SizedBox(
              height: 40,
            );
          } else if (index == 4) {
            return const Center(
                child: Text(
                  "Members:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ));
          } else if (index == 5) {
            return const SizedBox(
              height: 20,
            );
          }

          index -= 6;

          final user = widget.chatList[index];

          return InkWell(
            onTap: () {
              setState(() {
                widget.chatListNames.remove(user.firstName?.toLowerCase());
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
        },
      ),
    );
  }
}
