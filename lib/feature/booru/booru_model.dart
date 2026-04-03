class BooruPost {
  const BooruPost({
    required this.id,
    required this.imageUrl,
    required this.tags,
    required this.width,
    required this.height,
    required this.source,
  });

  factory BooruPost.fromJson(Map<String, dynamic> map) {
    return BooruPost(
      id: map['id'] ?? 0,
      // Danbooru provides the full URL directly in 'file_url'
      imageUrl: map['file_url'] ?? '',
      // Danbooru uses 'tag_string' for the space-separated list of tags
      tags: (map['tag_string'] as String? ?? '').trim(),
      // Dimensions use 'image_width' and 'image_height'
      width: map['image_width'] ?? 0,
      height: map['image_height'] ?? 0,
      source: (map['source'] as String? ?? '').trim(),
    );
  }
  final int id;
  final String imageUrl;
  final String tags;
  final int width;
  final int height;
  final String source;

  // Falls back to portrait if dimensions are missing.
  double get aspectRatio => (width > 0 && height > 0) ? width / height : 3 / 4;
}
