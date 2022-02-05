import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_svg/svg.dart';
import 'chat.dart';
import 'landing_page.dart';
import 'users.dart';
import '../util/util.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';

FirebaseDatabase database = FirebaseDatabase.instance;

class RoomsPage extends StatefulWidget {
  const RoomsPage({Key? key}) : super(key: key);

  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  Map<String, Widget> profileList = {};
  Map<dynamic, dynamic> profile = {};
  Map<dynamic, dynamic> state = {};
  bool _error = false;
  bool _initialized = false;
  User? _user;

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        setState(() {
          _user = user;
        });
      });
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Widget _buildAvatar(types.Room room) {
    var color = Colors.transparent;
    types.User otherUser = room.users.firstWhere(
          (u) => u.id != _user!.uid,
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
    final stream = FirebaseDatabase.instance.ref("users/${otherUser.id}/status").onValue.asBroadcastStream();

    StreamBuilder<DatabaseEvent> getStream() {
      return StreamBuilder<DatabaseEvent>(
        stream: stream,
        builder: (BuildContext context,
            AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return const Text("Something went wrong");
          }

          if (snapshot.connectionState ==
              ConnectionState.active) {

            if (snapshot.data?.snapshot.value == true) {
              state[room.id] = true;
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
              state[room.id] = false;
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

          if (state[room.id] == true) {
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
        },
      );
    }

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
                          profile[room.id] = CircleAvatar(
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
                          return profile[room.id];
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
                          profile[room.id] = CachedNetworkImage(
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
                          return profile[room.id];
                        }
                      }()),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: getStream(),
                      ),
                    ],
                  ),
                );
              } else {
                if (hasImage == false) {
                  profile[room.id] = CircleAvatar(
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
                  return profile[room.id];
                }
                if (room.imageUrl!.split(".").last == 'svg') {
                  profile[room.id] = ClipOval(
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
                  return profile[room.id];
                } else {
                  profile[room.id] = CachedNetworkImage(
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
                  return profile[room.id];
                }
              }
            } ()),
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
    )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container();
    }

    if (!_initialized) {
      return Container();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: _user == null
              ? null
              : () {
            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => const UsersPage(),
              ),
            );
          },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add),
      ),
      body: _user == null
          ? Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(
                bottom: 200,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Not authenticated'),
                  TextButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LandingPage()),
                      );
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            )
          : StreamBuilder<List<types.Room>>(
              stream: FirebaseChatCore.instance.rooms(),
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  //print(snapshot.data!);
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(
                      bottom: 200,
                    ),
                    child: const CircularProgressIndicator(),
                  );
                }

                snapshot.data!.sort((object1, object2) {
                  return object2.updatedAt!.compareTo(object1.updatedAt!);
                });

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final room = snapshot.data![index];

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (c, a1, a2) => ChatPage(
                              backupName: "error",
                              room: room,
                              avatar: profile[room.id],
                            ),
                            transitionsBuilder: (c, anim, a2, child) =>
                                FadeTransition(opacity: anim, child: child),
                            transitionDuration: const Duration(milliseconds: 750),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: _buildAvatar(room),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
