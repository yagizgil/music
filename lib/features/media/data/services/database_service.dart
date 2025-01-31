import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'music.db');

    // Eğer veritabanı varsa sil ve yeniden oluştur (geliştirme aşamasında)
    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Albümler tablosu
        await db.execute('''
          CREATE TABLE albums (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            coverPath TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        // Albüm şarkıları tablosu (many-to-many ilişki)
        await db.execute('''
          CREATE TABLE album_songs (
            albumId INTEGER,
            songId INTEGER,
            FOREIGN KEY (albumId) REFERENCES albums (id) ON DELETE CASCADE,
            PRIMARY KEY (albumId, songId)
          )
        ''');

        await db.execute('''
          CREATE TABLE recently_played (
            songId INTEGER PRIMARY KEY,
            playedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
