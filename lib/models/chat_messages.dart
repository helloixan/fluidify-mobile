class ChatMessage {
  final String text;
  final bool isBot;
  final String? imageRef;

  ChatMessage({
    required this.text,
    required this.isBot,
    this.imageRef,
  });

  // Convert Object ke JSON (Map) untuk disimpan ke database
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isBot': isBot,
      'imageRef': imageRef,
    };
  }

  // Convert JSON (Map) dari database kembali menjadi Object
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isBot: map['isBot'] ?? true,
      imageRef: map['imageRef'],
    );
  }
}
