/*import 'package:jitsi_meet/jitsi_meet.dart';
import '../model/confrence.dart';
import 'package:url_launcher/url_launcher.dart';*/

/*

class ConfrenceService {
  late Confrence details;
  ConfrenceService({required Confrence instance}) {
    details = instance;
  }
  Map<FeatureFlagEnum, bool> feature = {
    FeatureFlagEnum.INVITE_ENABLED: false,
    FeatureFlagEnum.PIP_ENABLED: true,
    FeatureFlagEnum.RECORDING_ENABLED: true,
  };

  connect() async {
    JitsiMeetingOptions options = JitsiMeetingOptions(room: details.room)
      ..userEmail = details.emailID
      ..userDisplayName = details.displayName
      ..featureFlags.addAll(feature)
      ..subject = details.subject
      ..userAvatarURL = details.avatarUrl
      ..webOptions = {
        "interfaceConfigOverwrite": { "SHOW_CHROME_EXTENSION_BANNER": false },
        "roomName": details.subject,
        "width": "100%",
        "height": "100%",
        "enableWelcomePage": false,
        "chromeExtensionBanner": null,
        "configOverwrite":
        {
          "chromeExtensionBanner": null,
          "disableInviteFunctions": true,
          "prejoinPageEnabled": false,
        },
        "userInfo": {"displayName": details.displayName}
      };

    await JitsiMeet.joinMeeting(options);
  }

  urlLaunch() {
    launch('https://meet.jit.si/${details.room}');
  }
}

Navigator.push(
context, MaterialPageRoute(builder: (_) => SizedBox(
width: width,
height: height,
child: Scaffold(
appBar: AppBar(
title: Row(children: [
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
]),
leading: InkWell(
onTap: () {
Navigator.pop(context);
},
child: Icon(Icons.arrow_back_ios_new_rounded,
color:
Theme.of(context).appBarTheme.toolbarTextStyle!.color)),
backgroundColor: Theme.of(context).primaryColor),
body: JitsiMeetConferencing(
extraJS: const [ // extraJs setup example
'<script>function echo(){console.log("echo!!!")};}</script>',
'<script src="https://code.jquery.com/jquery-3.5.1.slim.js" integrity="sha256-DrT5NfxfbHvMHux31Lkhxg42LY6of8TaYyK50jnxRnM=" crossorigin="anonymous"></script>'
],
),
),
)));

Future.delayed(const Duration(milliseconds: 500), () async {
await web.ConfrenceService(
instance: model.Confrence(
avatarUrl: userData['imageUrl'],
subject: widget.room.name ?? widget.backupName,
displayName: username,
emailID: FirebaseAuth.instance.currentUser!.email!,
room: widget.room.id))
    .connect();
});

*/
