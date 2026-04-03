import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class BooruPost {
  const BooruPost({
    required this.id,
    required this.imageUrl,
    required this.previewUrl,
    required this.tagString,
    required this.source,
    required this.rating,
    required this.width,
    required this.height,
  });

  final int id;
  final String imageUrl;
  final String previewUrl;
  final String tagString;
  final String source;
  final String rating;
  final int width;
  final int height;

  bool get isSafe => rating == 'g' || rating == 's';
}

final booruProvider = AsyncNotifierProvider.autoDispose.family<BooruNotifier, BooruPost, String>(
  BooruNotifier.new,
);

class BooruNotifier extends AsyncNotifier<BooruPost> {
  BooruNotifier(this.tag);

  final String tag;

  @override
  FutureOr<BooruPost> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<BooruPost> _fetch() async {
    final uri = Uri.https('danbooru.donmai.us', '/posts/random.json', {'tags': tag});

    final response = await http
        .get(uri, headers: {'User-Agent': 'Otraku/1.0'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load post (status ${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    // Danbooru may return an error object instead of a post.
    if (data.containsKey('error') || data['success'] == false) {
      throw Exception(data['message'] ?? 'Unknown error');
    }

    final imageUrl = (data['large_file_url'] ?? data['file_url']) as String?;
    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception(
        'No image URL in response — the post may have been deleted or is unavailable',
      );
    }

    final previewUrl =
        (data['preview_file_url'] ?? data['large_file_url'] ?? data['file_url']) as String? ??
        imageUrl;

    return BooruPost(
      id: data['id'] as int,
      imageUrl: imageUrl,
      previewUrl: previewUrl,
      tagString: data['tag_string'] as String? ?? '',
      source: data['source'] as String? ?? '',
      rating: data['rating'] as String? ?? 'q',
      width: (data['image_width'] as num?)?.toInt() ?? 0,
      height: (data['image_height'] as num?)?.toInt() ?? 0,
    );
  }
}
