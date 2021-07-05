import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:dio/dio.dart';

import 'models/asr_response.dart';
import 'models/chatbot_answer.dart';
import 'models/tts_response.dart';

class VinAsrError extends Error {
  VinAsrError();
}

class VinChatBotError extends Error {
  VinChatBotError();
}

class VinTtsError extends Error {
  VinTtsError();
}

class VinChatBotManager {
  final String userID;
  IOWebSocketChannel socketChannel;
  Function pauseRecorder;
  Function resumeRecorder;
  Function playAudios;
  Function onErrors;
  Function gotAsrs;
  Function socketConnectChange;
  bool _isDisposed = false;

  bool _isSocketConnect = false;

  DateTime _startTime;
  DateTime _endTime;

  VinChatBotManager(String userID) : this.userID = userID {}

  void initSocketChannel() {
    String token =
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJleHAiOjE2MzAwMjg3MDcsImlhdCI6MTYyNDg0NDcwNywiaXNzIjoiNjBkOTI5YTM5YzkwNmU3YzRhOWZkY2JiIiwicHVibGljX2lkIjoiNjBkOTI5OWRkZjAyNzViNzU1MWJlZTA0IiwibmFtZSI6ImFzciJ9.CS0WzPKPqCuHEQvzPt4D7CCBsFm6jpJxQzOpZlPcmKZs7MthJRXNSG5EzKbvWNY1Kq5lOts25lyaNZPazXBAGef-jl5iidAOqHHJHn3hb9giu8shN80ddJkQbZmxjPDx787WMSuunY5E1Q7TFWgAZT9Y3o1C6hpog-PeHOTfuSecgH9N6Xglw0U6-39E-PZJ5HFj1ou3gRZZFWjg1e0waf-w25ryNjic5U8N3ouzmLdnaZqusa70KjyBYF6CMvEZnQExC_QJGqlBkWz3dcD15OP06XdlV9qNkTCB54PsrE9iGHgkasCxzXzu4EEompDWMvv-nfA5dFm8ot0nsZvzHw';
    String url = 'wss://dev.vinbase.ai/api/v2/asr/stream';
    socketChannel = IOWebSocketChannel.connect(
      Uri.parse(url),
      headers: <String, dynamic>{"token": token},
    );

    _isSocketConnect = true;
    socketConnectChange(_isSocketConnect);

    socketChannel.stream.listen((event) async {
      try {
        final json = jsonDecode(event);
        final asr = AsrResponse.fromJson(json);
        print(asr.text);
        gotAsrs(asr);
      } catch (e) {
        print(e);
      }
    }, onDone: () {
      debugPrint('ws channel closed');
      _endTime = DateTime.now();
      final dif = _endTime.difference(_startTime).inSeconds;
      print('socket_time_log: ${dif}');
      _isSocketConnect = false;
      socketConnectChange(_isSocketConnect);
      if (!_isDisposed) {
        initSocketChannel();
      }
    }, onError: (error) {
      if (!_isDisposed) {
        initSocketChannel();
      }
      _isSocketConnect = false;
      socketConnectChange(_isSocketConnect);
      debugPrint('ws error $error');
    });

    _startTime = DateTime.now();
  }

  void addAudioData(Uint8List data) {
    socketChannel.sink.add(Uint64List.fromList(data));
  }

  Future<String> getBotAnswer(AsrResponse asr) async {
    try {
      final dio = Dio();
      dio.interceptors.add(LogInterceptor());
      String agentId = '600f842b4a15baa18b3f91fa';
      String versionId = '6051cef7b0afa9e82df6e369';
      String token =
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJleHAiOjE5MzEzMzQxMzUsImlhdCI6MTYxNTk3NDEzNSwiaXNzIjoiNjA1MWNlZjdiMDE5YzY0YTVkMTViM2I5IiwicHVibGljX2lkIjoiNjAwZjg0MmI0YTE1YmFhMThiM2Y5MWZhIiwibmFtZSI6ImNoYXRib3QifQ.O0FQpE0uefha2wEwYLWZ-kq1a4Hmveab0SLMsEMmD1b47htvUMp-FQJyyvQFJ7gPeqy1w7MeYgZXzc-3VtpEVVaNQ2gN1vUnLR0hSDL3wuWfhZNa8x0hEwoaj8k5rBdySwxrP0LGyyLKrP2gAvscSAY-xNsz9f2HGDjw_Bqb_UunXkm02u6R6NbGuEgsyugtVGqKbMrV6o6UgwRErQyBiZRGnQbkBA3IhdQdrbi5CfwpkWHrXJe_Wwnkz4ZWsAR1dGHbVnM_vbpOpkInpdP-eDk6Xa68_5Xd1xTyMCU3JqwEKcpgmoA-Nt8DFjM-2Qkkqgv_6pvmNi7gVneqE2YpDw';
      final String url =
          'https://vinbase.ai/api/v1/chatbot_gateway/agents/${agentId}/channels/${versionId}/users/${this.userID}/messages';

      final response = await dio.post(
        url,
        data: {
          'message': asr.text,
        },
        options: Options(headers: {'token': token}),
      );

      final botAnswerResponse = BotAnswerResponse.fromJson(response.data);
      return botAnswerResponse.getFirstTextAnswer();
    } catch (e) {
      throw VinChatBotError();
    }
  }

  Future<TtsResponse> getTtsResponse(String answer) async {
    try {
      final String token =
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJleHAiOjE2Mjc3OTQ0MzIsImlhdCI6MTYyMjYxMDQzMiwiaXNzIjoiNjA1ZDU3ZTI5NTM1ZjQ1Nzc3OWI1ZGJlIiwicHVibGljX2lkIjoiNjA1ZDU3Y2JlZmZlYzZlYTE3YmQ5NTE3IiwibmFtZSI6InNzIn0.S9Ofq2FwnHwAl0swhmEnfHFsgU1vQZtfdlQ45lalbR3SMVflDDzeYWaqRykU7UWE6zE7Hwft7x4b91r2HtUR3yjLHA_p57v_2AH2D1XFo9KsmYwNIb6GHpRS3xq4g6SNgg1nXLPumLw0UBA5tHqw8FgK9S46jkeBW447FLuV50P8AiQoHAw3_ZrnKdjZyWsW03Nu300KOZ1JXgXyAmwbmS61FZJARugNC9D5KMZ-uVmkaysPG0ueePv9N-bv1Ufa0SAd0vFqQhaWsWfTy57WFV9zASPQwwORvKzsLKys5Mgau2DfEgKmI5Yzc7udnTowLtZ6TAoU9p7F-AKsjz7FRw';
      final Dio dio = Dio();
      final data = {
        "output_format": "wav",
        "language_code": "vi_vn",
        "voice_name": "female_south2",
        "generator": "melgan",
        "acoustic_model": "fastspeech2",
        "style": "news",
        "text": answer
      };
      final response = await dio.post(
        'https://dev.vinbase.ai/api/v1/tts/synthesis/',
        data: data,
        options: Options(headers: {"token": token}),
      );

      return TtsResponse.fromJson(response.data);
    } catch (e) {
      throw VinTtsError();
    }
  }

  void dispose() {
    _isDisposed = true;
    socketChannel.sink.close();
  }
}
