import 'dart:typed_data';

class Dream {
  final String id;
  final DateTime createdAt;
  String transcript;
  String? audioPath;
  Uint8List? generatedImage;
  String? imagePrompt;

  Dream({
    required this.id,
    required this.createdAt,
    this.transcript = '',
    this.audioPath,
    this.generatedImage,
    this.imagePrompt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'transcript': transcript,
      'audio_path': audioPath,
      'generated_image': generatedImage,
      'image_prompt': imagePrompt,
    };
  }

  factory Dream.fromMap(Map<String, dynamic> map) {
    return Dream(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      transcript: map['transcript'] as String? ?? '',
      audioPath: map['audio_path'] as String?,
      generatedImage: map['generated_image'] as Uint8List?,
      imagePrompt: map['image_prompt'] as String?,
    );
  }

  Dream copyWith({
    String? id,
    DateTime? createdAt,
    String? transcript,
    String? audioPath,
    Uint8List? generatedImage,
    String? imagePrompt,
  }) {
    return Dream(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      transcript: transcript ?? this.transcript,
      audioPath: audioPath ?? this.audioPath,
      generatedImage: generatedImage ?? this.generatedImage,
      imagePrompt: imagePrompt ?? this.imagePrompt,
    );
  }
}
