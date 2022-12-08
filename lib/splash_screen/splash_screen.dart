import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  startTime() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // connected
        var duration = const Duration(seconds: 2);
        return Timer(duration, navigationPage);
      } else {
        // not connected
        var duration = const Duration(seconds: 2);
        return Timer(duration, noInternetPage);
      }
    } on SocketException catch (_) {
      // print('not connected');
      var duration = const Duration(seconds: 2);
      return Timer(duration, noInternetPage);
    }
  }

  void navigationPage() {
    Navigator.of(context).pushReplacementNamed('/HomeScreen');
  }

  void noInternetPage() {
    Navigator.of(context).pushReplacementNamed('/NoInternetPage');
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    super.initState();
    startTime();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SplashView(),
    );
  }
}

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  SplashViewState createState() => SplashViewState();
}

class SplashViewState extends State<SplashView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded(
        //     flex: 1,
        //     child: Container(
        //         padding: const EdgeInsets.symmetric(horizontal: 16),
        //         child: const AnimatedCrossFade(
        //           duration: Duration(milliseconds: 200),
        //           firstChild: Center(
        //             child: Image(image: AssetImage('images/bdhousing_logo_big.png'),color: Colors.grey,),
        //           ),
        //           secondChild: Center(
        //             child: Image(image: AssetImage('images/bdhousing_logo_big.png')),
        //           ), crossFadeState: CrossFadeState.showSecond,
        //         )
        //     )
        // ),
        Expanded(
          flex: 1,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Center(
                  child: Image(
                image: AssetImage("images/dukaletu_logo2.png"),
                height: 150,
              )
              )
          ),
        ),
      ],
    );
  }
}
