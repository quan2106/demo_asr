import 'dart:async';

import 'package:demo_asr/models/asr_response.dart';
import 'package:demo_asr/vinchatbot_manager.dart';
import 'package:flutter/material.dart';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

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
  FlutterSoundRecorder recorder = FlutterSoundRecorder();
  var _recordingFoodController = StreamController<Food>();
  VinChatBotManager _chatbotManager;
  bool _isRecording = false;
  bool _isForceStopRecording = false;
  String error;
  AsrResponse asr;
  String text;
  bool isSocketConnect;

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

    await recorder.closeAudioSession();
    await recorder.openAudioSession();

    _recordingFoodController.stream.listen((buffer) {
      if (buffer is FoodData) {
        _chatbotManager.addAudioData(buffer.data);
      }
    });
  }

  Future _startRecorder() async {
    if (_isForceStopRecording) {
      return;
    }

    PermissionStatus status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        error = "Microphone permission not granted";
      });
      return;
    }
    await recorder.startRecorder(
      codec: Codec.pcm16,
      toStream: _recordingFoodController.sink,
    );

    setState(() {
      _isRecording = true;
    });
  }

  Future _pauseRecorder() async {
    if (recorder.isRecording) {
      await recorder.pauseRecorder();
    }

    setState(() {
      _isRecording = false;
    });
  }

  Future _resumeRecorder() async {
    if (_isForceStopRecording) {
      return;
    }
    if (recorder.isPaused) {
      await recorder.resumeRecorder();
    }

    setState(() {
      _isRecording = true;
    });
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
        onTapUp: (_) async {
          print("stop_recoder");
          await _pauseRecorder();
        },
        onTapDown: (_) async {
          print("start_recoder");
          if (recorder.isPaused) {
            await _resumeRecorder();
          }

          if (recorder.isStopped) {
            await _startRecorder();
          }
        },
        child: FloatingActionButton(
          child: Icon((!_isRecording) ? Icons.mic : Icons.mic_off),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
