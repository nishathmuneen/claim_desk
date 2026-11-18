class PickedDocument {
  final String name;
  final int sizeInBytes;
  final String? extension;
  final String? base64Data;
  final bool isImage;
  final bool isPdf;

  const PickedDocument({
    required this.name,
    required this.sizeInBytes,
    this.extension,
    this.base64Data,
    this.isImage = false,
    this.isPdf = false,
  });

  String get formattedSize {
    if (sizeInBytes <= 0) return '';
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

