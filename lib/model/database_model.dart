class DocumentModel {
  final int? id;
  final String name;
  final String filePath;
  final String fileType;
  final int fileSize;
  final bool isFavorite;
  final String createdAt;
  final String updatedAt;

  DocumentModel({
    this.id,
    required this.name,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  DocumentModel copyWith({
    int? id,
    String? name,
    String? filePath,
    String? fileType,
    int? fileSize,
    bool? isFavorite,
    String? createdAt,
    String? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? 'Untitled',
      filePath: (map['file_path'] as String?) ?? '',
      fileType: (map['file_type'] as String?) ?? 'file',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      isFavorite: (map['is_favorite'] == 1 || map['is_favorite'] == true),
      createdAt: (map['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      updatedAt: (map['updated_at'] as String?) ??
          (map['created_at'] as String?) ??
          DateTime.now().toIso8601String(),
    );
  }
}
