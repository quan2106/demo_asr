class AsrResponse {
  String partial;
  String text;

  AsrResponse({this.partial, this.text});

  factory AsrResponse.fromJson(Map<String, dynamic> json) {
    return AsrResponse(partial: json['partial'], text: json['text']);
  }
}
