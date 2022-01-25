import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';
import '../model/confrence.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfrenceService {
  late Confrence details;
  ConfrenceService({required Confrence instance}) {
    details = instance;
  }
  Map<FeatureFlag, bool> feature = {
    FeatureFlag.isInviteEnabled: false,
    FeatureFlag.isPipEnabled: true,
    FeatureFlag.isHelpButtonEnabled: false,
    FeatureFlag.isIosScreensharingEnabled: true,
    FeatureFlag.isAndroidScreensharingEnabled: true,
    FeatureFlag.isRecordingEnabled: true,
    FeatureFlag.isCloseCaptionsEnabled: true
  };

  connect() async {
    JitsiMeetingOptions options = JitsiMeetingOptions(
        serverUrl: "https://meet.vrdgov.org",
        userAvatarUrl: details.avatarUrl,
        roomNameOrUrl: details.room,
        userEmail: details.emailID,
        userDisplayName: details.displayName,
        featureFlags: feature,
        subject: details.subject);
    await JitsiMeetWrapper.joinMeeting(options: options);
  }

  urlLaunch() {
    launch('https://meet.vrdgov.org/${details.room}');
  }
}
