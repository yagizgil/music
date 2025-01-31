class CustomAlbum {
  final int id;
  final String name;
  final String? coverPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomAlbum({
    required this.id,
    required this.name,
    this.coverPath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'coverPath': coverPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CustomAlbum.fromMap(Map<String, dynamic> map) {
    return CustomAlbum(
      id: map['id'],
      name: map['name'],
      coverPath: map['coverPath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
