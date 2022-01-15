import "dart:math";

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:edge_alerts/edge_alerts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:verdiscom/screens/landing_page.dart';
import 'package:verdiscom/screens/register_page.dart';
import 'package:verdiscom/screens/rooms.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:mime/mime.dart';
import 'dart:io' show Platform;
import 'package:file_selector/file_selector.dart';
import 'package:verdiscom/util/buy_me_a_coffee/buy_me_a_coffee_widget.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:verdiscom/util/contactus.dart';
import 'package:uzu_flavored_markdown/uzu_flavored_markdown.dart' as uzu;
import 'package:http/http.dart' as http;

firebase_storage.FirebaseStorage storage =
    firebase_storage.FirebaseStorage.instance;

late Map<String, dynamic> userData;
var fireStoreUserRef = FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser!.uid);

final beforeNonLeadingCapitalLetter = RegExp(r"(?=(?!^)[A-Z])");
List<String> splitPascalCase(String input) =>
    input.split(beforeNonLeadingCapitalLetter);

enum Section { about, home }
Section section = Section.home;

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

http.Client client = http.Client();

String username = 'User';
String email = 'user@example.com';
late User loggedInUser;

/*class MyWidgetFactory extends html.WidgetFactory {
  @override
  void parse(html.BuildMetadata meta) {
    if (meta.element.innerHtml.contains(" | Verdis Communications")) {
      meta.register(html.BuildOp(
        onWidgets: (meta, widgets) => html.listOrNull(
          widgets.first.wrapWith(
                (context, child) => Column(
                  children: [
                    Center(
              child: child,
            ),
                    const SizedBox(height: 20),
                    const Divider(
                      height: 20,
                      thickness: 2,
                      indent: 20,
                      endIndent: 20,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
          ),
        ),
      ));
    }
    return super.parse(meta);
  }
}*/

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  //final html.WidgetFactory widgetFactory = MyWidgetFactory();

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  Widget profile = const SizedBox(
      width: 50,
      height: 50,
      child: Center(
          child: SizedBox(
              width: 25, height: 25, child: CircularProgressIndicator())));

  bool profileSet = false;

  CollectionReference users = FirebaseFirestore.instance.collection('users');
  CollectionReference global = FirebaseFirestore.instance.collection('global');
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  TabController? controller;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    client = http.Client();
    super.initState();
    getCurrentUser();
    controller = TabController(length: 2, vsync: this);
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        setState(() {
          username = loggedInUser.displayName ?? loggedInUser.providerData[0].displayName ?? loggedInUser.providerData[1].displayName!;
          email = loggedInUser.email ?? loggedInUser.providerData[0].email ?? loggedInUser.providerData[1].email!;
        });
      }
    } catch (e) {
      edgeAlert(context,
          title: 'Something Went Wrong',
          description: e.toString(),
          gravity: Gravity.bottom,
          icon: Icons.error,
          backgroundColor: Colors.deepPurple[900]);
    }
  }

  refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    getBlogPage(String url, String title, String author) async {
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
        body: FutureBuilder<Response>(
          future: http.get(Uri.parse(url)),
          builder: (BuildContext context, AsyncSnapshot<Response> snapshot) {
            if (snapshot.hasError) {
              return const Text("Something went wrong");
            }

            if (snapshot.connectionState == ConnectionState.done) {
              String mdToParse = snapshot.data!.body
                  .toString()
                  .split('{% include header.html %}')[1];
              double width = MediaQuery.of(context).size.width;

              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 20, 40, 10),
                    child: Center(
                        child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: (() {
                          if ((width * 0.08) < 54) {
                            return width * 0.08;
                          } else {
                            return 54.0;
                          }
                        }()),
                      ),
                    )),
                  ),
                  const Divider(
                    height: 20,
                    thickness: 2,
                    indent: 50,
                    endIndent: 50,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    author,
                    style: TextStyle(
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.normal, // regular weight
                        color: (() {
                          if (Theme.of(context).brightness ==
                              Brightness.light) {
                            return Colors.grey.shade600;
                          } else {
                            return Colors.white70;
                          }
                        }()),
                        fontSize: 14.0),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(38, 10, 38, 38),
                    child: uzu.UzuMd(body: mdToParse),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: (() {
                      double width = MediaQuery.of(context).size.width;
                      if (width > 140) {
                        width = 140.0;
                      }
                      if (Theme.of(context).brightness == Brightness.light) {
                        return Image.asset(
                            'assets/images/banner.png',
                          width: width - 60,
                        );
                      } else {
                        return Image.asset('assets/images/banner-dark.png', width: width - 60);
                      }
                    }()),
                  )
                ],
              );
            }

            return const Center(
              child: SizedBox(
                height: 25.0,
                width: 25.0,
                child: Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          },
        ),
      );
    }

    Widget blog = Scaffold(
      body: FutureBuilder<Response>(
        future: http.get(Uri.parse(
            'https://free-republic-of-verdis.github.io/verdis-blog/feed.xml')),
        builder: (BuildContext context, AsyncSnapshot<Response> snapshot) {
          if (snapshot.hasError) {
            return const Text("Something went wrong");
          }

          if (snapshot.connectionState == ConnectionState.done) {
            var atomFeed = AtomFeed.parse(snapshot.data!.body.toString());
            double width = MediaQuery.of(context).size.width;
            var inputFormat = DateFormat('dd/MM/yyyy');
            var mdInputFormat = DateFormat('yyyy-MM-dd');

            return Scaffold(
              body: ListView.builder(
                  shrinkWrap: true,
                  cacheExtent: 9999,
                  physics: const AlwaysScrollableScrollPhysics(),
                  primary: false,
                  itemCount: atomFeed.items!.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                            child: Text(
                          atomFeed.title!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: (() {
                              if ((width * 0.08) < 54) {
                                return width * 0.08;
                              } else {
                                return 54.0;
                              }
                            }()),
                          ),
                        )),
                      );
                    }

                    return SizedBox(
                      width: 20.0,
                      height: 240.0,
                      child: Card(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                atomFeed.items![index - 1].title!,
                                style: TextStyle(
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.normal, //
                                  // regular weight
                                  color: (() {
                                    if (Theme.of(context).brightness ==
                                        Brightness.light) {
                                      return Colors.grey.shade800;
                                    } else {
                                      return Colors.white;
                                    }
                                  }()),
                                  fontSize: 18.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "By ${atomFeed.items![index - 1].authors!.first.name!} - ${inputFormat.format(atomFeed.items![index - 1].updated!)}",
                                style: TextStyle(
                                    fontStyle: FontStyle.normal,
                                    fontWeight:
                                        FontWeight.normal, // regular weight
                                    color: (() {
                                      if (Theme.of(context).brightness ==
                                          Brightness.light) {
                                        return Colors.grey.shade600;
                                      } else {
                                        return Colors.white70;
                                      }
                                    }()),
                                    fontSize: 14.0),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                atomFeed.items![index - 1].summary!,
                                style: TextStyle(
                                    fontStyle: FontStyle.normal,
                                    fontWeight:
                                        FontWeight.normal, // regular weight
                                    color: (() {
                                      if (Theme.of(context).brightness ==
                                          Brightness.light) {
                                        return Colors.grey.shade700;
                                      } else {
                                        return Colors.white54;
                                      }
                                    }()),
                                    fontSize: 16.0),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Read More',
                                      style:
                                          const TextStyle(color: Colors.blue),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          //launch(atomFeed.items![index - 1].links!.first.href!);
                                          var blogPost = await getBlogPage(
                                              "https://raw.githubusercontent.com/Free-Republic-of-Verdis/verdis-blog/main/_posts/${mdInputFormat.format(atomFeed.items![index - 1].updated!)}-${atomFeed.items![index - 1].links!.first.href!.split('/').last}.md",
                                              atomFeed.items![index - 1].title!,
                                              "By ${atomFeed.items![index - 1].authors!.first.name!} - ${inputFormat.format(atomFeed.items![index - 1].updated!)}");
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => blogPost));
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
            );
          }

          return const Center(
            child: SizedBox(
              height: 25.0,
              width: 25.0,
              child: Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            ),
          );
        },
      ),
    );

    Widget about = Scaffold(
      appBar: AppBar(
          leading: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color:
                      Theme.of(context).appBarTheme.toolbarTextStyle!.color)),
          backgroundColor: Theme.of(context).primaryColor),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 25, 0, 0),
        child: ContactUs(
          avatarPadding: 30.0,
          cardColor: Colors.white,
          textColor: Colors.black,
          logo: const AssetImage('assets/images/garv.jpg'),
          avatarRadius: 100,
          email: 'gshah.6110@gmail.com',
          companyName: 'Garv Shah',
          companyColor: Theme.of(context).appBarTheme.toolbarTextStyle!.color!,
          dividerThickness: 2,
          dividerColor: Colors.grey,
          website: 'https://garv-shah.github.io',
          githubUserName: 'garv-shah',
          tagLine: 'Developer & Student',
          taglineColor: Theme.of(context).appBarTheme.toolbarTextStyle!.color!,
        ),
      ),
    );

    Widget body;

    Widget home = DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
            leading: InkWell(
                onTap: () {
                  _key.currentState!.openDrawer();
                },
                child: Icon(Icons.menu,
                    color:
                        Theme.of(context).appBarTheme.toolbarTextStyle!.color)),
            actions: const <Widget>[],
            backgroundColor: Theme.of(context).primaryColor),
        key: _key,
        drawer: Theme(
          data: Theme.of(context)
              .copyWith(canvasColor: Theme.of(context).primaryColor),
          child: Drawer(
            // Add a ListView to the drawer. This ensures the user can scroll
            // through the options in the drawer if there isn't enough vertical
            // space to fit everything.
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                SizedBox(
                  child: DrawerHeader(
                    child: Container(
                      child: const Text("Options"),
                      alignment: Alignment.topCenter, // <-- ALIGNMENT
                      height: 10,
                    ),
                    decoration:
                        BoxDecoration(color: Theme.of(context).primaryColor),
                  ),
                  height: 50, // <-- HEIGHT
                ),
                ListTile(
                  title: Text("Theme: " +
                      EasyDynamicTheme.of(context)
                          .themeMode
                          .toString()
                          .split(".")[1]
                          .capitalize()),
                  onTap: () {
                    EasyDynamicTheme.of(context).changeTheme();
                  },
                ),
                ListTile(
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context, MaterialPageRoute(builder: (_) => about));
                  },
                ),
                ListTile(
                  title: const Text('GitHub'),
                  onTap: () {
                    launch('https://github.com/garv-shah');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Logout'),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LandingPage()),
                    );
                  },
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: global.doc('coffee').get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return const Text("Something went wrong");
                          }

                          if (snapshot.hasData && !snapshot.data!.exists) {
                            return const Text("Document does not exist");
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            Map<String, dynamic> data =
                                snapshot.data!.data() as Map<String, dynamic>;

                            if (data['active'] == true) {
                              return BuyMeACoffeeWidget(
                                customText: data['text'],
                                sponsorID: "nova.system",
                                theme: OrangeTheme(),
                              );
                            } else {
                              return const ListTile(
                                title: Text(''),
                              );
                            }
                          }

                          return const ListTile(
                            title: Text('Loading...'),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: false,
                pinned: true,
                backgroundColor: Theme.of(context).backgroundColor,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(15, 0, 30, 0),
                      leading: InkWell(
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        onTap: () async {
                          if (kIsWeb) {
                            final XFile? profileImage = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            var bytes = await profileImage!.readAsBytes();
                            setState(() {
                              profile = CircleAvatar(
                                backgroundImage: MemoryImage(bytes),
                                radius: 25,
                              );
                            });
                            if (userData['profileType'] != "") {
                              await storage
                                  .ref(
                                      'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${userData['profileType'].split('/')[1]}')
                                  .delete();
                            }
                            firebase_storage.Reference ref =
                                firebase_storage.FirebaseStorage.instance.ref(
                                    'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${lookupMimeType('', headerBytes: bytes)!.split('/')[1]}');

                            firebase_storage.SettableMetadata metadata =
                                firebase_storage.SettableMetadata(
                                    contentType:
                                        lookupMimeType('', headerBytes: bytes));

                            await ref.putData(bytes, metadata);
                            await fireStoreUserRef.update({
                              'defaultProfile': false,
                              'profileType':
                                  lookupMimeType('', headerBytes: bytes)
                            });
                            await users
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .set(
                              {
                                'imageUrl': await ref.getDownloadURL(),
                              },
                              SetOptions(merge: true),
                            );
                          } else if (Platform.isMacOS) {
                            XTypeGroup typeGroup;
                            typeGroup = XTypeGroup(
                                label: 'images',
                                extensions: ['jpg', 'png', 'gif', 'jpeg']);

                            final XFile? profileImage =
                                await openFile(acceptedTypeGroups: [typeGroup]);
                            var bytes = await profileImage!.readAsBytes();
                            setState(() {
                              profile = CircleAvatar(
                                backgroundImage: MemoryImage(bytes),
                                radius: 25,
                              );
                            });
                            if (userData['profileType'] != "") {
                              await storage
                                  .ref(
                                      'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${userData['profileType'].split('/')[1]}')
                                  .delete();
                            }
                            firebase_storage.Reference ref =
                                firebase_storage.FirebaseStorage.instance.ref(
                                    'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${lookupMimeType('', headerBytes: bytes)!.split('/')[1]}');

                            firebase_storage.SettableMetadata metadata =
                                firebase_storage.SettableMetadata(
                                    contentType:
                                        lookupMimeType('', headerBytes: bytes));

                            await ref.putData(bytes, metadata);
                            await fireStoreUserRef.update({
                              'defaultProfile': false,
                              'profileType':
                                  lookupMimeType('', headerBytes: bytes)
                            });
                            await users
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .set(
                              {
                                'imageUrl': await ref.getDownloadURL(),
                              },
                              SetOptions(merge: true),
                            );
                          } else {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return SimpleDialog(
                                      title:
                                          const Text("Change Profile Picture"),
                                      children: <Widget>[
                                        SimpleDialogOption(
                                          onPressed: () async {
                                            final XFile? profileImage =
                                                await ImagePicker().pickImage(
                                                    source:
                                                        ImageSource.gallery);
                                            var bytes = await profileImage!
                                                .readAsBytes();
                                            setState(() {
                                              profile = CircleAvatar(
                                                backgroundImage:
                                                    MemoryImage(bytes),
                                                radius: 25,
                                              );
                                            });

                                            Navigator.pop(context);
                                            if (userData['profileType'] != "") {
                                              await storage
                                                  .ref(
                                                      'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${userData['profileType'].split('/')[1]}')
                                                  .delete();
                                            }
                                            firebase_storage.Reference ref =
                                                firebase_storage
                                                    .FirebaseStorage.instance
                                                    .ref(
                                                        'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${lookupMimeType('', headerBytes: bytes)!.split('/')[1]}');

                                            firebase_storage.SettableMetadata
                                                metadata = firebase_storage
                                                    .SettableMetadata(
                                                        contentType:
                                                            lookupMimeType(
                                                                '',
                                                                headerBytes:
                                                                    bytes));

                                            await ref.putData(bytes, metadata);
                                            await fireStoreUserRef.update({
                                              'defaultProfile': false,
                                              'profileType': lookupMimeType('',
                                                  headerBytes: bytes)
                                            });
                                            await users
                                                .doc(FirebaseAuth
                                                    .instance.currentUser!.uid)
                                                .set(
                                              {
                                                'imageUrl':
                                                    await ref.getDownloadURL(),
                                              },
                                              SetOptions(merge: true),
                                            );
                                          },
                                          child:
                                              const Text('Pick From Gallery'),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () async {
                                            final XFile? profileImage =
                                                await ImagePicker().pickImage(
                                                    source: ImageSource.camera);
                                            var bytes = await profileImage!
                                                .readAsBytes();
                                            setState(() {
                                              profile = CircleAvatar(
                                                backgroundImage:
                                                    MemoryImage(bytes),
                                                radius: 25,
                                              );
                                            });

                                            Navigator.pop(context);
                                            if (userData['profileType'] != "") {
                                              await storage
                                                  .ref(
                                                      'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${userData['profileType'].split('/')[1]}')
                                                  .delete();
                                            }
                                            firebase_storage.Reference ref =
                                                firebase_storage
                                                    .FirebaseStorage.instance
                                                    .ref(
                                                        'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${lookupMimeType('', headerBytes: bytes)!.split('/')[1]}');

                                            firebase_storage.SettableMetadata
                                                metadata = firebase_storage
                                                    .SettableMetadata(
                                                        contentType:
                                                            lookupMimeType(
                                                                '',
                                                                headerBytes:
                                                                    bytes));

                                            await ref.putData(bytes, metadata);
                                            await fireStoreUserRef.update({
                                              'defaultProfile': false,
                                              'profileType': lookupMimeType('',
                                                  headerBytes: bytes)
                                            });
                                            await users
                                                .doc(FirebaseAuth
                                                    .instance.currentUser!.uid)
                                                .set(
                                              {
                                                'imageUrl':
                                                    await ref.getDownloadURL(),
                                              },
                                              SetOptions(merge: true),
                                            );
                                          },
                                          child:
                                              const Text('Take A New Picture'),
                                        ),
                                      ]);
                                });
                          }
                        },
                        child: profile,
                      ),
                      title: FutureBuilder<DocumentSnapshot>(
                        future: users
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return const Text("Something went wrong");
                          }

                          if (snapshot.hasData && !snapshot.data!.exists) {
                            return const Text("Document does not exist");
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            Map<String, dynamic> data =
                                snapshot.data!.data() as Map<String, dynamic>;

                            userData = data;

                            WidgetsBinding.instance!.addPostFrameCallback((_) =>
                                Future.delayed(const Duration(milliseconds: 0),
                                    () {
                                  if (profileSet == false) {
                                    if (data['defaultProfile'] == false) {
                                      firebase_storage.Reference ref =
                                          firebase_storage
                                              .FirebaseStorage.instance
                                              .ref(
                                                  'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${data['profileType'].split('/')[1]}');
                                      ref.getDownloadURL().then((value) => {
                                            setState(() {
                                              profile = ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl: value,
                                                  fit: BoxFit.fill,
                                                  width: 50,
                                                  height: 50,
                                                  placeholder: (context, url) =>
                                                      const SizedBox(
                                                          height: 50,
                                                          width: 50,
                                                          child:
                                                              CircularProgressIndicator()),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const SizedBox(
                                                              height: 50,
                                                              width: 50,
                                                              child: Icon(
                                                                  Icons.error)),
                                                ),
                                              );
                                              profileSet = true;
                                            })
                                          });
                                    } else {
                                      setState(() {
                                        profile = ClipOval(
                                            child: SvgPicture.network(
                                          'https://avatars.dicebear.com/api/avataaars/${FirebaseAuth.instance.currentUser!.email!.split("@")[0]}.svg',
                                          width: 50,
                                          height: 50,
                                          semanticsLabel: 'profile picture',
                                          placeholderBuilder: (BuildContext
                                                  context) =>
                                              const SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child:
                                                      CircularProgressIndicator()),
                                        ));
                                        profileSet = true;
                                      });
                                    }
                                  }
                                }));

                            return GestureDetector(
                              onTap: () async {
                                final username = await showTextInputDialog(
                                  style: AdaptiveStyle.material,
                                  context: context,
                                  textFields: [
                                    DialogTextField(
                                      hintText: 'username',
                                      validator: (value) => value!.isEmpty
                                          ? "username can't be empty"
                                          : null,
                                    ),
                                  ],
                                  title: 'Change Username',
                                  autoSubmit: true,
                                );

                                if (username != null) {
                                  await fireStoreUserRef
                                      .update({'username': username[0]});
                                  setState(() {});
                                }
                              },
                              child: Text(data["username"]),
                            );
                          }

                          return const Text("Loading...");
                        },
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Text(
                                  FirebaseAuth.instance.currentUser!.email!)),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: FutureBuilder<DocumentSnapshot>(
                              future: users
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return const Text("Something went wrong");
                                }

                                if (snapshot.hasData &&
                                    !snapshot.data!.exists) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterPage()),
                                  );
                                  return const Text("Document does not exist");
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  Map<String, dynamic> data = snapshot.data!
                                      .data() as Map<String, dynamic>;

                                  userData = data;

                                  WidgetsBinding.instance!.addPostFrameCallback(
                                      (_) => Future.delayed(
                                              const Duration(milliseconds: 0),
                                              () {
                                            if (profileSet == false) {
                                              if (data['defaultProfile'] ==
                                                  false) {
                                                firebase_storage.Reference ref =
                                                    firebase_storage
                                                        .FirebaseStorage
                                                        .instance
                                                        .ref(
                                                            'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${data['profileType'].split('/')[1]}');
                                                ref
                                                    .getDownloadURL()
                                                    .then((value) => {
                                                          setState(() {
                                                            profile = ClipOval(
                                                              child:
                                                                  CachedNetworkImage(
                                                                imageUrl: value,
                                                                fit:
                                                                    BoxFit.fill,
                                                                width: 50,
                                                                height: 50,
                                                                placeholder: (context,
                                                                        url) =>
                                                                    const SizedBox(
                                                                        height:
                                                                            50,
                                                                        width:
                                                                            50,
                                                                        child:
                                                                            CircularProgressIndicator()),
                                                                errorWidget: (context,
                                                                        url,
                                                                        error) =>
                                                                    const SizedBox(
                                                                        height:
                                                                            50,
                                                                        width:
                                                                            50,
                                                                        child: Icon(
                                                                            Icons.error)),
                                                              ),
                                                            );
                                                            profileSet = true;
                                                          })
                                                        });
                                              } else {
                                                setState(() {
                                                  profile = ClipOval(
                                                      child: SvgPicture.network(
                                                    'https://avatars.dicebear.com/api/avataaars/${FirebaseAuth.instance.currentUser!.email!.split("@")[0]}.svg',
                                                    width: 50,
                                                    height: 50,
                                                    semanticsLabel:
                                                        'profile picture',
                                                    placeholderBuilder:
                                                        (BuildContext
                                                                context) =>
                                                            const SizedBox(
                                                                height: 50,
                                                                width: 50,
                                                                child:
                                                                    CircularProgressIndicator()),
                                                  ));
                                                  profileSet = true;
                                                });
                                              }
                                            }
                                          }));

                                  return const SizedBox(
                                    width: 1,
                                    height: 1,
                                  );
                                }

                                return const SizedBox(
                                  width: 1,
                                  height: 1,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                expandedHeight: 70,
                collapsedHeight: 70,
                bottom: TabBar(
                  indicator: MaterialIndicator(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  isScrollable: false,
                  labelColor: Theme.of(context).colorScheme.secondary,
                  unselectedLabelColor:
                      Theme.of(context).textTheme.caption!.color,
                  tabs: const <Widget>[
                    Tab(
                      text: "Posts",
                    ),
                    Tab(
                      text: "Chats",
                    ),
                  ],
                  controller: controller,
                ),
              )
            ];
          },
          body: FutureBuilder<DocumentSnapshot>(
              future: global.doc('api-keys').get(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  /*Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;*/
                  if (kIsWeb) {
                    return TabBarView(
                      controller: controller,
                      children: <Widget>[
                        blog,
                        const RoomsPage(),
                      ],
                    );
                  } else {
                    final _random = Random();

                    return TabBarView(
                      controller: controller,
                      children: <Widget>[
                        blog,
                        const RoomsPage(),
                      ],
                    );
                  }
                } else {
                  return const Center(
                    child: SizedBox(
                      height: 25.0,
                      width: 25.0,
                      child: Align(
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }
              }),
        ),
      ),
    );

    switch (section) {
      case Section.home:
        body = home;
        break;

      case Section.about:
        body = about;
        break;
    }

    return Scaffold(
      body: Container(
        child: body,
      ),
    );
  }
}
