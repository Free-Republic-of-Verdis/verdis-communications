import 'package:cached_network_image/cached_network_image.dart';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_svg/svg.dart';
import 'package:verdiscom/widgets/custom_input.dart';
import 'chat.dart';
import 'create_group_chat.dart';
import '../util/util.dart';

late Widget profile;
List chatListNames = [];
List<types.User> chatList = [];
final TextEditingController input = TextEditingController();

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late FocusNode _inputFocusNode;

  @override
  void initState() {
    _inputFocusNode = FocusNode();
    chatListNames = [];
    chatList = [];
    super.initState();
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handlePressed(List userList, BuildContext context) async {
    if (userList.isEmpty) {
      edgeAlert(context,
          title: 'select one or more people',
          description:
              "Select one person to create DM or select multiple people to create a group chat!",
          duration: 2,
          gravity: Gravity.top,
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
              }
            }()),
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GCPage(chatList: chatList, chatListNames: chatListNames)
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
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _handlePressed(chatList, context);
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.check),
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

          return ListView.builder(
            itemCount: snapshot.data!.length + 3,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const SizedBox(
                  height: 20,
                );
              } else if (index == 1) {
                return CustomInput(
                  focusNode: _inputFocusNode,
                  autoFillController: input,
                  onChanged: (string) {},
                  hintText: 'Enter Username',
                  onSubmitted: (string) {
                    input.clear();
                    setState(() {
                      chatListNames.add(string.toLowerCase());
                    });
                    Future.delayed(const Duration(milliseconds: 100), () { _inputFocusNode.requestFocus(); });
                  },
                );
              } else if (index == 2) {
                return const SizedBox(
                  height: 20,
                );
              }

              index -= 3;

              final user = snapshot.data![index];

              if (chatListNames.contains(user.firstName?.toLowerCase())) {
                chatList.add(user);
                chatList = chatList.toSet().toList();
                chatListNames = chatListNames.toSet().toList();
                return InkWell(
                  onTap: () {
                    setState(() {
                      chatListNames.remove(user.firstName?.toLowerCase());
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
              } else if (chatList.contains(user)) {
                chatList.remove(user);
                return const SizedBox();
              } else {
                return const SizedBox();
              }
            },
          );
        },
      ),
    );
  }
}
