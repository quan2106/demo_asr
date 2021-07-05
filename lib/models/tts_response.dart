class Tts {
  String paragraph;
  List<String> sentences;

  Tts({this.paragraph, this.sentences});

  factory Tts.fromJson(Map<String, dynamic> json) {
    return Tts(
      paragraph: json['paragraph'],
      sentences: List<String>.from(json['sentences']),
    );
  }
}

class TtsResponse {
  int errorCode;
  String message;
  Tts data;

  TtsResponse({this.errorCode, this.message, this.data});

  factory TtsResponse.fromJson(Map<String, dynamic> json) {
    return TtsResponse(
      errorCode: json['error_code'],
      message: json['message'],
      data: Tts.fromJson(json['data']),
    );
  }
}
