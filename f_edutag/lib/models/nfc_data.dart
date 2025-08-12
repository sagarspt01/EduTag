class NFCData {
  final String id;
  final String content;

  NFCData({required this.id, required this.content});

  factory NFCData.fromJson(Map<String, dynamic> json) {
    return NFCData(id: json['id'] ?? '', content: json['content'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'content': content};
  }

  @override
  String toString() => 'NFCData(id: $id, content: $content)';
}
