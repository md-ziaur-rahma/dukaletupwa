import 'dart:async';
import 'dart:io';

import 'package:dukaletu/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late WebViewController _controller;

  final Completer<WebViewController> _controllerCompleter =
      Completer<WebViewController>();

  //.......................
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        javaScriptEnabled: true,
        verticalScrollBarEnabled: true,
        supportZoom: false,
      ),
      android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
          geolocationEnabled: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          clearSessionCache: true,
          thirdPartyCookiesEnabled: true,
          allowFileAccess: true,
          allowContentAccess: true),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";

  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Common.mainColor, //or set color with: Color(0xFF0000FF)
    ));
    if (Platform.isAndroid) {
      // WebView.platform = SurfaceAndroidWebView();
      // await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
    getPermission();
    super.initState();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Common.mainColor,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  void getPermission() async {
    if (await Permission.location.isGranted) {
      return;
    }
    // else if (await Permission.location.isDenied) {
    //   openAppSettings();
    // }
    else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
      ].request();
    }
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          // ignore: deprecated_member_use
          // print('${message.message}');
        });
  }

  double progressValue = 0;

  Future<bool> _onWillPop(BuildContext context) async {
    if (await webViewController!.canGoBack()) {
      webViewController!.goBack();
      return Future.value(false);
    } else {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Are you sure?'),
              content: const Text('Do you want to exit the App'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          )) ??
          false;
    }
  }

  Future<void> reload() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return _controller.reload();
      }
    } on SocketException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Internet Connection!'),
        ),
      );
      return;
    }
  }

  int isError = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: WillPopScope(
        onWillPop: () => _onWillPop(context),
        child: UpgradeAlert(
          upgrader: Upgrader(
            dialogStyle: Platform.isIOS
                ? UpgradeDialogStyle.cupertino
                : UpgradeDialogStyle.material,
          ),
          child: isError == 0
              ? Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      if (progressValue == 100) {
                        return const SizedBox(
                          height: 0,
                        );
                      } else {
                        return SizedBox(
                          width: double.infinity,
                          height: 3,
                          child: LinearProgressIndicator(
                            value: progressValue / 100,
                            minHeight: 3,
                            backgroundColor: Colors.grey,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.deepOrange,
                            ),
                          ),
                          // return const SizedBox(
                          //   width: 16,
                          //   height: 16,
                          //   child: Center(
                          //     child: CircularProgressIndicator(
                          //       strokeWidth: 2,
                          //       color: Colors.deepOrange,
                          //     ),
                          //   )
                        );
                      }
                    }),
                    Expanded(
                        child: InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                          url: Uri.parse("https://www.dukaletu.co.ke/")),
                      initialOptions: options,
                      pullToRefreshController: pullToRefreshController,
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      onLoadHttpError:
                          (controller, url, statusCode, description) {
                        // print("xxxxxxxxxxxxxxxxxxxx status code $statusCode, description : $description xxxxxxxxxxxxxxxxx");
                      },
                      androidOnGeolocationPermissionsShowPrompt:
                          (InAppWebViewController controller,
                              String origin) async {
                        return GeolocationPermissionShowPromptResponse(
                            origin: origin, allow: true, retain: true);
                      },
                      // androidOnReceivedLoginRequest: ,
                      // iosOnDidReceiveServerRedirectForProvisionalNavigation: ,
                      onLoadStart: (controller, url) {
                        // var facebook = "facebook.com";
                        // var google = "https://accounts.google.com/";
                        // if (url.toString().contains(facebook) || url.toString().contains(google)) {
                        //   // launchURL(context,url.toString());
                        //   openBrowser(url.toString());
                        // }
                        // if ([ "https://www.facebook.com/", "https://accounts.google.com/"].contains(url.toString())) {
                        //   launchURL(context,url.toString());
                        // }
                        setState(() {
                          this.url = url.toString();
                        });
                      },
                      androidOnPermissionRequest:
                          (controller, origin, resources) async {
                        return PermissionRequestResponse(
                            resources: resources,
                            action: PermissionRequestResponseAction.GRANT);
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;
                        // var facebook = "facebook.com";
                        // var google = "https://accounts.google.com/";
                        // if ([ facebook, google].contains(uri.toString())) {
                        //   // launchURL(context,url.toString());
                        //   openBrowser(url.toString());
                        //   return NavigationActionPolicy.CANCEL;
                        // }

                        if (![
                          "http",
                          "https",
                          "file",
                          "chrome",
                          "data",
                          "javascript",
                          "about"
                        ].contains(uri.scheme)) {
                          // launchURL(context,url.toString());
                          openBrowser(url.toString());
                          return NavigationActionPolicy.CANCEL;
                        }

                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStop: (controller, url) async {
                        pullToRefreshController.endRefreshing();
                        setState(() {
                          this.url = url.toString();
                        });
                      },
                      onLoadError: (controller, url, code, message) {
                        pullToRefreshController.endRefreshing();
                        if (code == -2) {
                          setState(() {
                            isError = 1;
                            webViewController = controller;
                          });
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Internet Error"),
                                  content: const Text(
                                      "Please check your internet connection!"),
                                  actions: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3)),
                                          side: const BorderSide(
                                              color: Common.mainColor,
                                              width: 1.0)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(3)),
                                          side: const BorderSide(
                                              color: Common.mainColor,
                                              width: 1.0)),
                                      onPressed: () {
                                        setState(() {
                                          isError = 0;
                                        });
                                        Navigator.of(context).pop();
                                        Future.delayed(
                                                const Duration(seconds: 1))
                                            .then((value) =>
                                                webViewController?.reload());
                                      },
                                      child: const Text("Try Again"),
                                    )
                                  ],
                                );
                              });
                        }
                        print(
                            "xxxxxxxxxxxxxxxxxxxx status code $code, description : $message xxxxxxxxxxxxxxxxx");
                      },
                      onProgressChanged: (controller, progress) {
                        if (progress == 100) {
                          pullToRefreshController.endRefreshing();
                        }
                        setState(() {
                          progressValue = progress.toDouble();
                        });
                      },
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
                        setState(() {
                          this.url = url.toString();
                        });
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        print(consoleMessage);
                      },
                    )
                        // child: WebView(
                        //   javascriptMode: JavascriptMode.unrestricted,
                        //   initialUrl: 'https://dhereye.com/',
                        //   onWebViewCreated: (WebViewController webViewController) {
                        //     _controllerCompleter.future.then((value) => _controller = value);
                        //     _controllerCompleter.complete(webViewController);
                        //   },
                        //   onProgress: (int progress) {
                        //     // print("WebView is loading (progress : $progress%)");
                        //     setState(() {
                        //       progressValue = progress.toDouble();
                        //     });
                        //   },
                        //   javascriptChannels: <JavascriptChannel>{
                        //     _toasterJavascriptChannel(context),
                        //   },
                        //   navigationDelegate: (NavigationRequest request) {
                        //     // ................
                        //     // var uri = Uri.dataFromString(request.url);
                        //     // Map<String, String> params = uri.queryParameters;
                        //     // var transaction = params['billplz%5Btransaction_status%5D'];
                        //     // var paid = params["billplz%5Bpaid%5D"];
                        //     // print('transaction : $transaction');
                        //     // print('paid : $paid');
                        //     // if (transaction == 'completed' || paid == 'true') {
                        //     //   Navigator.push(context, OrderListPage.route());
                        //     //   // Navigator.pop(context);
                        //     //   return NavigationDecision.navigate;
                        //     // } else if (transaction == 'failed' || paid == 'false') {
                        //     //   Common.toastMsg('Payment unsuccessful!');
                        //     //   Navigator.push(context, HomePage.route());
                        //     //   // Navigator.pop(context);
                        //     //   return NavigationDecision.navigate;
                        //     // }
                        //     // ................
                        //     // print('allowing navigation to $request');
                        //     return NavigationDecision.navigate;
                        //   },
                        //   onPageStarted: (String url) {
                        //     // print('Page started loading: $url');
                        //   },
                        //   onPageFinished: (String url) {
                        //     // print('Page finished loading: $url');
                        //   },
                        //   gestureNavigationEnabled: true,
                        // ),
                        ),
                    // LayoutBuilder(
                    //     builder: (context,constraints){
                    //       if (progressValue < 1.0) {
                    //         return LinearProgressIndicator(value: progressValue);
                    //       }  else {
                    //         return SizedBox(
                    //           width: double.infinity,
                    //           height: 3,
                    //           child: LinearProgressIndicator(
                    //             value: progressValue/100,
                    //             minHeight: 3,
                    //             backgroundColor : Colors.grey,
                    //             valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange,),
                    //           ),
                    //           // return const SizedBox(
                    //           //   width: 16,
                    //           //   height: 16,
                    //           //   child: Center(
                    //           //     child: CircularProgressIndicator(
                    //           //       strokeWidth: 2,
                    //           //       color: Colors.deepOrange,
                    //           //     ),
                    //           //   )
                    //         );
                    //       }
                    //     }
                    // ),
                  ],
                )
              : Center(child: buildError()),
        ),
      )),
    );
  }

  Widget buildError() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image(
            // width: double.infinity,
            height: MediaQuery.of(context).orientation == Orientation.portrait
                ? 120
                : 120,
            image: const AssetImage(
              'images/no_internet_con.png',
            ),
            color: Common.mainColor,
          ),
          const SizedBox(
            height: 16,
          ),
          const SizedBox(
            width: double.infinity,
            child: Text(
              'Something went wrong!.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3)),
                side: const BorderSide(color: Common.mainColor, width: 1.0)),
            onPressed: () {
              setState(() {
                isError = 0;
                webViewController?.reload();
              });
            },
            child: const Text("Try Again"),
          )
        ],
      ),
    );
  }

  // void launchURL(BuildContext context,url) async {
  //   try {
  //     await launch(
  //       '$url',
  //       customTabsOption: CustomTabsOption(
  //         toolbarColor: Theme.of(context).primaryColor,
  //         enableDefaultShare: true,
  //         enableUrlBarHiding: true,
  //         showPageTitle: true,
  //         enableInstantApps: true,
  //         animation: CustomTabsSystemAnimation.fade(),
  //         // or user defined animation.
  //         // animation: CustomTabsSystemAnimation(
  //         //   startEnter: 'slide_up',
  //         //   startExit: 'android:anim/fade_out',
  //         //   endEnter: 'android:anim/fade_in',
  //         //   endExit: 'slide_down',
  //         // ),
  //         extraCustomTabs: const <String>[
  //           'org.mozilla.firefox',
  //           'com.microsoft.emmx',
  //           // ref. https://play.google.com/store/apps/details?id=org.mozilla.firefox
  //           // ref. https://play.google.com/store/apps/details?id=com.microsoft.emmx
  //         ],
  //       ),
  //       safariVCOption: SafariViewControllerOption(
  //         preferredBarTintColor: Theme.of(context).primaryColor,
  //         preferredControlTintColor: Colors.white,
  //         barCollapsingEnabled: true,
  //         entersReaderIfAvailable: false,
  //         dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
  //       ),
  //     );
  //   } catch (e) {
  //     // An exception is thrown if browser app is not installed on Android device.
  //     debugPrint(e.toString());
  //   }
  // }

  void openBrowser(url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // await launch(encodedURl,forceWebView: false,forceSafariVC: false);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (kDebugMode) {
        print('Could not launch $uri');
      }
      throw 'Could not launch $uri';
    }
  }
}
