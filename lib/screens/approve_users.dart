import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_svg/svg.dart';
import '../util/util.dart';

late Widget profile;
final TextEditingController input = TextEditingController();

class ApproveUsersPage extends StatefulWidget {
  const ApproveUsersPage({Key? key}) : super(key: key);

  @override
  State<ApproveUsersPage> createState() => _ApproveUsersPageState();
}

class _ApproveUsersPageState extends State<ApproveUsersPage> {
  late FocusNode _inputFocusNode;

  @override
  void initState() {
    _inputFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAvatar(types.User user) {
    final color = getUserAvatarNameColor(user);
    final hasImage = user.imageUrl != null;
    final name = getUserName(user);

    CollectionReference users = FirebaseFirestore.instance.collection('users');

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
                profile = ClipOval(
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

                return profile;
              } else {
                profile = CachedNetworkImage(
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
                            style: const TextStyle(color: Colors.white),
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

                return profile;
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
          StreamBuilder<DocumentSnapshot>(
          stream: users
                  .doc(user.id).snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text("Something went wrong");
            }

            if (snapshot.hasData &&
                !snapshot.data!.exists) {
              return const Text("Document does not exist");
            }

            if (snapshot.connectionState ==
                ConnectionState.active) {

              Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

              if (data['approved'] == true) {
                return IconButton(
                    onPressed: () {
                      setState(() {
                        users.doc(user.id).set(
                          {
                            'approved': false,
                          },
                          SetOptions(merge: true),
                        );
                      });

                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Done!'),
                              content:
                              Text("${user.firstName}'s approval has been revoked"),
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
                    },
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.redAccent,
                    ));
              } else {
                return IconButton(
                    onPressed: () {
                      setState(() {
                        users.doc(user.id).set(
                          {
                            'approved': true,
                          },
                          SetOptions(merge: true),
                        );
                      });

                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Done!'),
                              content:
                              Text('${user.firstName} has been approved'),
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
                    },
                    icon: const Icon(
                      Icons.check,
                      color: Colors.green,
                    ));
              }
            }

            return const CircularProgressIndicator();
          },
        ),
            ],
          ),
        ));
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
        title: const Text('Approve Users'),
      ),
      body: StreamBuilder<List<types.User>>(
        stream: FirebaseChatCore.instance.users(),
        initialData: const [],
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.only(
                bottom: 200,
              ),
              child: const Text('No users'),
            );
          }

          if (snapshot.connectionState == ConnectionState.active) {
            snapshot.data!.sort((object1, object2) {
              return object2.createdAt!.compareTo(object1.createdAt!);
            });

            return Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final user = snapshot.data![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: _buildAvatar(user),
                  );
                },
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
