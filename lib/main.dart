import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:flutter/services.dart';

void main() => runApp(MyApp(
      initRoute: window.defaultRouteName,
    ));

class MyApp extends StatelessWidget {
  final String initRoute;

  const MyApp({Key key, this.initRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter与Native混合开发',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'Flutter与Native混合开发',
        initRoute: initRoute,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.initRoute}) : super(key: key);

  final String title;
  final String initRoute;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const BasicMessageChannel _basicMessageChannel =
      BasicMessageChannel("BasicMessageChannel", StringCodec());
  static const MethodChannel _methodChannel = MethodChannel("MethodChannel");
  static const EventChannel _eventChannel = EventChannel("EventChannel");
  StreamSubscription _streamSubscription;

  String showMessage;

  @override
  void initState() {
    super.initState();
    //很方便的双向通信渠道
    _basicMessageChannel.setMessageHandler((message) => Future<String>(() {
          setState(() {
            showMessage = message;
          });
          return "Dart端回复：$message"; //向Native回复
        }));
    // 响应Native端调用Dart端方法。一般都是Dart调用Native端的，比如拍照
    _methodChannel.setMethodCallHandler((MethodCall methodCall) {
      if (methodCall.method == "responseToNative") {
        return Future<String>(() {
          return responseToNative();
        });
      }
    });
    _streamSubscription =
        _eventChannel.receiveBroadcastStream().listen((event) {//Sets up a broadcast stream for receiving events on this channel
      setState(() {
        showMessage = event;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          decoration: BoxDecoration(color: Colors.blue),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("send To Native"),
                Row(
                  children: <Widget>[
                    RaisedButton(
                      child: Text("basicChannel"),
                      onPressed: () async {
                        try {
                          String response =
                              await _basicMessageChannel.send("来自Dart的Message");
                          setState(() {
                            showMessage = response;
                          });
                        } on PlatformException catch (e) {}
                      },
                    ),
                    RaisedButton(
                      child: Text("methodChannel"),
                      onPressed: () async {
                        try {
                          String response = await _methodChannel
                              .invokeMethod("getMsgFromNativeByMethodChannel");
                          setState(() {
                            showMessage = response;
                          });
                        } on PlatformException catch (e) {
                          print(e);
                        }
                      },
                    ),
                    RaisedButton(
                      child: Text("eventChannel"),
                      onPressed: () {},
                    ),
                  ],
                ),
                Text("initRoute：${widget.initRoute}"),
                Text("message from native：$showMessage")
              ],
            ),
          ),
        ));
  }

  String responseToNative() {
    return "Dart端回复：_methodChannel msg";
  }
}
