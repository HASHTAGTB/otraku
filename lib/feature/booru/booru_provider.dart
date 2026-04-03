import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:otraku/feature/booru/booru_model.dart';

// Match your collectionProvider style: .autoDispose.family and passing .new
final booruProvider = AsyncNotifierProvider.autoDispose.family<BooruNotifier, BooruPost, String>(
  BooruNotifier.new,
);

// Extend AsyncNotifier (NOT FamilyAsyncNotifier)
class BooruNotifier extends AsyncNotifier<BooruPost> {
  // 1. Receive the tag argument in the constructor
  BooruNotifier(this.arg);

  final String arg;

  // 2. Build method takes no arguments in this style
  @override
  FutureOr<BooruPost> build() => _fetch();

  Future<void> fetchNew() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<BooruPost> _fetch() async {
    // 3. Add order:random and use Uri.encodeComponent for the tag
    final queryTags = '$arg order:random';
    final url = Uri.parse(
      'https://danbooru.donmai.us/posts.json?limit=1&tags=${Uri.encodeComponent(queryTags)}',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body);
    if (data.isEmpty) throw Exception('No posts found for "$arg"');

    return BooruPost.fromJson(data[0] as Map<String, dynamic>);
  }
}
