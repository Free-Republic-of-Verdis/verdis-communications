import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:verdiscom/screens/register_page.dart';
import 'package:verdiscom/util/const.dart';
import 'package:verdiscom/screens/home.dart';
import 'package:verdiscom/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

CollectionReference global = FirebaseFirestore.instance.collection('global');

class LandingPage extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // If Firebase App init, snapshot has error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Error: ${snapshot.error}"),
            ),
          );
        }

        // Connection Initialized - Firebase App is running
        if (snapshot.connectionState == ConnectionState.done) {
          // StreamBuilder can check the login state live
          return StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, streamSnapshot) {
              // If Stream Snapshot has error
              if (streamSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text("Error: ${streamSnapshot.error}"),
                  ),
                );
              }

              // Connection state active - Do the user login check inside the
              // if statement
              if (streamSnapshot.connectionState == ConnectionState.active) {
                // Get the user
                Object? _user = streamSnapshot.data;

                // If the user is null, we're not logged in
                if (_user == null) {
                  // user not logged in, head to login
                  return LoginPage();
                } else {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: global
                        .doc("private")
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return const Text("Something went wrong");
                      }

                      if (snapshot.hasData && !snapshot.data!.exists) {
                        return const RegisterPage();
                      }

                      if (snapshot.connectionState == ConnectionState.active) {
                        Map<String, dynamic> data =
                            snapshot.data!.data() as Map<String, dynamic>;

                        if (data['approved'].contains(FirebaseAuth.instance.currentUser!.uid)) {
                          return const Home();
                        } else {
                          return Container(
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                  Color(0xFF404e8f),
                                  Color(0xFF011569)
                                ])),
                            child: const Scaffold(
                              backgroundColor: Colors.transparent,
                              body: SafeArea(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(60.0),
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                        ),
                                        elevation: 10,
                                        child: Padding(
                                          padding: EdgeInsets.all(24.0),
                                          child: Text(
                                            "Please wait for your account to be approved by an administrator",
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      return Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                              Color(0xFF404e8f),
                              Color(0xFF011569)
                            ])),
                        child: const Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    },
                  );
                  // The user is logged in, head to homepage
                }
              }

              // Checking the auth state - Loading
              return Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF404e8f), Color(0xFF011569)])),
                child: const Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            },
          );
        }

        // Connecting to Firebase - Loading
        return const Scaffold(
          body: Center(
            child: Text(
              "Initialization App...",
              style: Constants.regularHeading,
            ),
          ),
        );
      },
    );
  }
}
