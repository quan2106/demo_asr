import 'dart:async';
import 'dart:typed_data';

import 'package:demo_asr/models/asr_response.dart';
import 'package:demo_asr/vinchatbot_manager.dart';
import 'package:flutter/material.dart';
import 'package:holding_gesture/holding_gesture.dart';

import 'package:sound_stream/sound_stream.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final recorder = RecorderStream();
  VinChatBotManager _chatbotManager;
  bool _isRecording = false;
  bool _isForceStopRecording = false;
  String error;
  AsrResponse asr;
  String text;
  bool isSocketConnect;
  int blockSize = 8192;
  Uint8List tempBuffer;

  @override
  void initState() {
    _init();
    super.initState();
  }

  Future _init() async {
    _chatbotManager = VinChatBotManager('1234567');
    _chatbotManager.socketConnectChange = (isConnect) {
      setState(() {
        isSocketConnect = isConnect;
      });
    };
    _chatbotManager.gotAsrs = (asr) {
      setState(() {
        this.asr = asr;
        if (asr != null && asr.text != null) text = asr.text;
      });
    };
    _chatbotManager.initSocketChannel();

    recorder.status.listen((status) {
      setState(() {
        _isRecording = status == SoundStreamStatus.Playing;
      });
    });
    recorder.audioStream.listen((buffer) {
      if (_isRecording) {
        _chatbotManager.addAudioData(buffer);
      }
    });
    await recorder.initialize(showLogs: true);
  }

  Future _startRecorder() async {
    if (_isForceStopRecording) {
      return;
    }

    await recorder.start();
  }

  Future _pauseRecorder() async {
    await recorder.stop();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> asrWidget = [];
    if (asr != null) {
      asrWidget = [
        Text('partials: ' + (asr.partial ?? "")),
        Text('text: ' + (text ?? "")),
      ];
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
                (error != null)
                    ? Text(
                        'error: ' + error,
                        style: TextStyle(color: Colors.red),
                      )
                    : Container(),
                Text(
                  'This is socket response:',
                ),
              ] +
              asrWidget,
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) async {
          await _startRecorder();
        },
        onTapUp: (_) {
          _pauseRecorder();
        },
        onTapCancel: () {
          _pauseRecorder();
        },
        child: FloatingActionButton(
          child: Icon((!_isRecording) ? Icons.mic : Icons.mic_off),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
