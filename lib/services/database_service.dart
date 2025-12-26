import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/dream.dart';

class DatabaseService {
  Database? _database;

  Future<void> initialize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'dream_tracker.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE dreams (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            transcript TEXT,
            audio_path TEXT,
            generated_image BLOB,
            image_prompt TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertDream(Dream dream) async {
    await _database?.insert(
      'dreams',
      dream.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDream(Dream dream) async {
    await _database?.update(
      'dreams',
      dream.toMap(),
      where: 'id = ?',
      whereArgs: [dream.id],
    );
  }

  Future<void> deleteDream(String id) async {
    await _database?.delete(
      'dreams',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Dream>> getAllDreams() async {
    final maps = await _database?.query(
      'dreams',
      orderBy: 'created_at DESC',
    );

    if (maps == null || maps.isEmpty) {
      return [];
    }

    return maps.map((map) {
      // Handle BLOB conversion
      final imageData = map['generated_image'];
      Uint8List? generatedImage;
      if (imageData != null) {
        if (imageData is Uint8List) {
          generatedImage = imageData;
        } else if (imageData is List<int>) {
          generatedImage = Uint8List.fromList(imageData);
        }
      }

      return Dream(
        id: map['id'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        transcript: map['transcript'] as String? ?? '',
        audioPath: map['audio_path'] as String?,
        generatedImage: generatedImage,
        imagePrompt: map['image_prompt'] as String?,
      );
    }).toList();
  }

  Future<Dream?> getDream(String id) async {
    final maps = await _database?.query(
      'dreams',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps == null || maps.isEmpty) {
      return null;
    }

    return Dream.fromMap(maps.first);
  }
}
