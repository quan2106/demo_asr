class ChatbotAnswer {
  String type;
  String value;

  ChatbotAnswer({this.type, this.value});

  factory ChatbotAnswer.fromJson(Map<String, dynamic> json) {
    return ChatbotAnswer(
      type: json['type'],
      value: json['value'],
    );
  }
}

class BotAnswerResponse {
  int errorCode;
  String message;
  List<ChatbotAnswer> answers;

  BotAnswerResponse({this.errorCode, this.message, this.answers});

  String getFirstTextAnswer() {
    try {
      final answer = answers.firstWhere((element) => element.type == 'text');
      return answer.value;
    } catch (e) {
      return null;
    }
  }

  factory BotAnswerResponse.fromJson(Map<String, dynamic> json) {
    int errorCode = json['error_code'];
    String message = json['message'];
    Map<String, dynamic> data = json['data'];
    List<Map<String, dynamic>> messages =
        List<Map<String, dynamic>>.from(data['bot_message']);
    List<ChatbotAnswer> answers =
        messages.map((e) => ChatbotAnswer.fromJson(e)).toList();

    return BotAnswerResponse(
      errorCode: errorCode,
      message: message,
      answers: answers,
    );
  }
}
