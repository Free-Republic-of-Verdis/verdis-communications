import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_svg/svg.dart';
import 'package:verdiscom/util/const.dart';
import 'package:flutter/material.dart';
import 'package:verdiscom/screens/home.dart' as home;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:verdiscom/util/util.dart';

CollectionReference rooms = FirebaseFirestore.instance.collection('rooms');

class UserView extends StatefulWidget {
  final Map userData;
  final Widget profile;
  final bool? isAdmin;
  final String userID;
  const UserView(
      {Key? key,
      required this.userData,
      required this.profile,
      required this.userID,
      this.isAdmin})
      : super(key: key);

  @override
  _UserViewState createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  Widget _buildAvatar(types.Room room) {
    var color = Colors.transparent;
    types.User otherUser = room.users.firstWhere(
          (u) => u.id != FirebaseAuth.instance.currentUser!.uid,
    );

    if (room.type == types.RoomType.direct) {
      try {
        color = getUserAvatarNameColor(otherUser);
      } catch (e) {
        // Do nothing if other user is not found
      }
    }

    final hasImage = room.imageUrl != null;
    final name = room.name ?? '';

    return Card(
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: ListTile(
          leading: (() {
            if (room.type == types.RoomType.direct) {
              return SizedBox(
                height: 40,
                width: 40,
                child: Stack(
                  children: [

                    /// Builds main image.
                    /// For example, profile picture.
                    (() {
                      if (hasImage == false) {
                        return  CircleAvatar(
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
                                child: Center(child: SizedBox(width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator()))),
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
                                  name.isEmpty ? '' : name[0].toUpperCase(),
                                  style: TextStyle(color: Theme.of(context).primaryColorLight),
                                )
                                    : null,
                              ),
                          placeholder: (context, url) =>
                          const SizedBox(
                              height: 40,
                              width: 40,
                              child: Center(child: SizedBox(width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator()))),
                          errorWidget: (context, url, error) =>
                          const SizedBox(
                              height: 40,
                              width: 40,
                              child: Icon(Icons.error)),
                        );
                      }
                    }()),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: StreamBuilder<DatabaseEvent>(
                        stream: FirebaseDatabase.instance.ref("users/${otherUser.id}/status").onValue,
                        builder: (BuildContext context,
                            AsyncSnapshot<DatabaseEvent> snapshot) {
                          if (snapshot.hasError) {
                            return const Text("Something went wrong");
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.active) {

                            if (snapshot.data?.snapshot.value == true) {
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

                          return const SizedBox();
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else {
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
                        child: Center(child: SizedBox(width: 30,
                            height: 30,
                            child: CircularProgressIndicator()))),
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
                          name.isEmpty ? '' : name[0].toUpperCase(),
                          style: TextStyle(color: Theme.of(context).primaryColorLight),
                        )
                            : null,
                      ),
                  placeholder: (context, url) =>
                  const SizedBox(
                      height: 40,
                      width: 40,
                      child: Center(child: SizedBox(width: 30,
                          height: 30,
                          child: CircularProgressIndicator()))),
                  errorWidget: (context, url, error) =>
                  const SizedBox(
                      height: 40,
                      width: 40,
                      child: Icon(Icons.error)),
                );
              }
            }
          } ()),
          title: Material(
              color: Colors.transparent,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18.0,
                ),
              )),
        )
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color:
                        Theme.of(context).appBarTheme.toolbarTextStyle!.color)),
            backgroundColor: Theme.of(context).primaryColor),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width / 2 - 120, 53.0, 8.0, 0),
              child: ListTile(
                leading: SizedBox(
                  height: 50,
                  width: 50,
                  child: Transform.translate(
                    offset: const Offset(0, 30),
                    child: Transform.scale(
                      scale: 3,
                      child: Hero(
                        tag: widget.userData['firstName'],
                        child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (() {
                                    if (Theme.of(context).brightness ==
                                        Brightness.dark) {
                                      return Colors.transparent;
                                    } else {
                                      return Colors.black.withOpacity(0.3);
                                    }
                                  }()),
                                  spreadRadius: 2,
                                  blurRadius: 6,
                                  offset: const Offset(
                                      0, 1), // changes position of shadow
                                ),
                              ],
                            ),
                            child: widget.profile),
                      ),
                    ),
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 0, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Hero(
                                tag: widget.userData['firstName'] + " name",
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    widget.userData['firstName'],
                                    style: const TextStyle(
                                      fontSize: 20.0,
                                    ),
                                  ),
                                ))),
                        Hero(
                            tag: widget.userData['firstName'] + " worth",
                            child: Material(
                                color: Colors.transparent,
                                child: Text(widget.userData['email'] ??
                                    'User Has No Email'))),
                      ],
                    ),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.fromLTRB(52, 0, 0, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Material(
                          color: Colors.transparent,
                          child: (() {
                            if (widget.isAdmin == true) {
                              return InkWell(
                                  onTap: () async {
                                    List<types.User> userList =
                                        await FirebaseChatCore.instance
                                            .users()
                                            .first;
                                    final username = await showTextInputDialog(
                                      style: AdaptiveStyle.material,
                                      context: context,
                                      textFields: [
                                        DialogTextField(
                                          hintText: 'username',
                                          validator: (value) {
                                            for (var element in userList) {
                                              if (element.firstName
                                                      ?.toLowerCase() ==
                                                  value?.toLowerCase()) {
                                                return "Sorry! This username is already taken";
                                              }
                                            }

                                            if (value!.isEmpty) {
                                              return "username can't be empty";
                                            } else {
                                              return null;
                                            }
                                          },
                                        ),
                                      ],
                                      title: 'Change Username',
                                      autoSubmit: true,
                                    );

                                    if (username != null) {
                                      await home.users.doc(widget.userID).set(
                                        {
                                          'username': username[0],
                                          'firstName': username[0],
                                        },
                                        SetOptions(merge: true),
                                      );

                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Icon(Icons.edit));
                            } else {
                              return FutureBuilder<
                                      DocumentSnapshot<Map<String, dynamic>>>(
                                  future: FirebaseFirestore.instance
                                      .collection('global')
                                      .doc("private")
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      List adminList = (snapshot.data!.data()
                                          as Map)['admin'];
                                      if (adminList.contains(widget.userID)) {
                                        return const Text("Admin");
                                      } else {
                                        return const Text("User");
                                      }
                                    }

                                    return const CircularProgressIndicator();
                                  });
                            }
                          }()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
                child: StreamBuilder<List<types.Room>>(
                  stream: FirebaseChatCore.instance.rooms(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.active) {
                      List roomList = [];
                      for (var roomData in snapshot.data!) {
                        if (roomData.users.map((e) => e.id).contains(widget.userID) && roomData.type == types.RoomType.group) {
                          roomList.add(roomData);
                        }
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 100),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: roomList.length,
                              itemBuilder: (context, index) {
                                final room = roomList[index];

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: _buildAvatar(room),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                          child: Text(snapshot.error.toString()));
                    }

                    return Transform.translate(offset: const Offset(0, 350),
                    child: const CircularProgressIndicator());
                  }
                )),
          ],
        ));
  }
}
