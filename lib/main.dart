//import 'package:family_ages/screens/Login.dart';
//import 'package:flutter/material.dart';
//
//void main() => runApp(MyApp());
//
//class MyApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: 'Family Ages',
//      theme: ThemeData(
//        primarySwatch: Colors.blue,
//        accentColor: Colors.blue[300],
//      ),
//      home: Login(),
//      debugShowCheckedModeBanner: false,
//    );
//  }
//}

import 'package:family_ages/screens/Login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Family Ages',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Splash Screen Flutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return _introScreen();
  }
}

Widget _introScreen() {
  return Stack(
    children: <Widget>[
      SplashScreen(
        seconds: 5,
        gradientBackground: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.blue,
            Colors.blue[400]
          ],
        ),
        navigateAfterSeconds: Login(),
        loaderColor: Colors.transparent,
      ),
      Center(
        child: Container(
          width: 120,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/splash-logo.png"),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      ),
    ],
  );
}