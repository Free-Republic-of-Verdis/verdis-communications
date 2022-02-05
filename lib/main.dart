import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:verdiscom/screens/landing_page.dart';
import 'package:verdiscom/util/const.dart';
import 'package:statusbarz/statusbarz.dart';
import 'firebase_options.dart';
import 'themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();

    if (kDebugMode) {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(false);
    } else {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(true);

      if (await FirebaseCrashlytics.instance.checkForUnsentReports()) {
        await FirebaseCrashlytics.instance.sendUnsentReports();
      }
    }
  }

  runApp(
    StatusbarzCapturer(
      child: EasyDynamicThemeWidget(
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: isDark ? Constants.darkPrimary : Constants.lightPrimary,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: Constants.appName,
        theme: lightThemeData,
        darkTheme: darkThemeData,
        themeMode: EasyDynamicTheme.of(context).themeMode,
        home: LandingPage());
  }
}
