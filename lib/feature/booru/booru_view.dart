import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/extension/snack_bar_extension.dart';
import 'package:otraku/feature/booru/booru_provider.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/cached_image.dart';
import 'package:otraku/widget/dialogs.dart';
import 'package:otraku/widget/layout/adaptive_scaffold.dart';
import 'package:otraku/widget/layout/top_bar.dart';
import 'package:otraku/widget/loaders.dart';

class BooruView extends ConsumerWidget {
  const BooruView(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(booruProvider(tag));

    final refreshButton = IconButton(
      tooltip: 'Random',
      icon: const Icon(Ionicons.shuffle_outline),
      onPressed: () => ref.read(booruProvider(tag).notifier).refresh(),
    );

    return AdaptiveScaffold(
      topBar: TopBar(title: tag.replaceAll('_', ' '), trailing: [refreshButton]),
      child: state.when(
        loading: () => const Center(child: Loader()),
        error: (error, _) => _ErrorView(
          error: error.toString(),
          onRetry: () => ref.read(booruProvider(tag).notifier).refresh(),
        ),
        data: (post) => _PostView(post: post, tag: tag),
      ),
    );
  }
}

class _PostView extends StatelessWidget {
  const _PostView({required this.post, required this.tag});

  final BooruPost post;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      physics: Theming.bouncyPhysics,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(top: topPadding + Theming.offset),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Theming.offset),
              child: _ImageCard(post: post),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: Theming.offset,
              right: Theming.offset,
              top: Theming.offset,
              bottom: bottomPadding + Theming.offset,
            ),
            child: _MetaInfo(post: post),
          ),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.post});

  final BooruPost post;

  bool get _isVideo {
    final url = post.imageUrl.toLowerCase();
    return url.endsWith('.mp4') || url.endsWith('.webm') || url.endsWith('.zip');
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      return _VideoPlaceholder(post: post);
    }

    final aspectRatio = post.width > 0 && post.height > 0 ? post.width / post.height : 1.0;

    return ClipRRect(
      borderRadius: Theming.borderRadiusSmall,
      child: AspectRatio(
        aspectRatio: aspectRatio.clamp(0.33, 3.0),
        child: GestureDetector(
          onTap: () => showDialog(context: context, builder: (_) => ImageDialog(post.imageUrl)),
          child: CachedImage(post.imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.post});

  final BooruPost post;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: Theming.borderRadiusSmall,
      child: Container(
        height: 200,
        color: ColorScheme.of(context).surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Theming.offset,
            children: [
              Icon(
                Ionicons.videocam_outline,
                size: 48,
                color: ColorScheme.of(context).onSurfaceVariant,
              ),
              Text('Video content — open in browser', style: TextTheme.of(context).labelMedium),
              TextButton.icon(
                icon: const Icon(Ionicons.open_outline),
                label: const Text('Open Link'),
                onPressed: () => SnackBarExtension.launch(context, post.imageUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaInfo extends StatefulWidget {
  const _MetaInfo({required this.post});

  final BooruPost post;

  @override
  State<_MetaInfo> createState() => _MetaInfoState();
}

class _MetaInfoState extends State<_MetaInfo> {
  bool _tagsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final colorScheme = ColorScheme.of(context);
    final post = widget.post;

    final tags = post.tagString.split(' ').where((t) => t.isNotEmpty).toList();
    final displayedTags = _tagsExpanded ? tags : tags.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Theming.offset,
      children: [
        // Post ID and rating badge
        Row(
          spacing: Theming.offset / 2,
          children: [
            Text('Post #${post.id}', style: textTheme.labelSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _ratingColor(post.rating, colorScheme),
                borderRadius: Theming.borderRadiusSmall,
              ),
              child: Text(
                _ratingLabel(post.rating),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (post.width > 0 && post.height > 0)
              Text('${post.width}×${post.height}', style: textTheme.labelSmall),
            const Spacer(),
            IconButton(
              tooltip: 'Open on Danbooru',
              icon: const Icon(Ionicons.open_outline, size: Theming.iconSmall),
              onPressed: () =>
                  SnackBarExtension.launch(context, 'https://danbooru.donmai.us/posts/${post.id}'),
            ),
          ],
        ),

        if (post.source.isNotEmpty)
          GestureDetector(
            onTap: () => SnackBarExtension.launch(context, post.source),
            child: Text(
              'Source: ${post.source}',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // Tags
        if (tags.isNotEmpty) ...[
          Text('Tags', style: textTheme.labelMedium),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              ...displayedTags.map(
                (tag) => ActionChip(
                  label: Text(tag.replaceAll('_', ' ')),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => SnackBarExtension.copy(context, tag),
                ),
              ),
              if (tags.length > 10)
                ActionChip(
                  label: Text(_tagsExpanded ? 'Show less' : '+${tags.length - 10} more'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _tagsExpanded = !_tagsExpanded),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Color _ratingColor(String rating, ColorScheme scheme) => switch (rating) {
    'g' => Colors.green.shade600,
    's' => Colors.blue.shade600,
    'q' => Colors.orange.shade600,
    'e' => scheme.error,
    _ => Colors.grey.shade600,
  };

  String _ratingLabel(String rating) => switch (rating) {
    'g' => 'General',
    's' => 'Sensitive',
    'q' => 'Questionable',
    'e' => 'Explicit',
    _ => rating.toUpperCase(),
  };
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: Theming.paddingAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Theming.offset,
          children: [
            Icon(Ionicons.alert_circle_outline, size: 48, color: ColorScheme.of(context).error),
            Text('Failed to load image', style: TextTheme.of(context).bodyMedium),
            Text(error, style: TextTheme.of(context).labelSmall, textAlign: TextAlign.center),
            FilledButton.icon(
              icon: const Icon(Ionicons.refresh_outline),
              label: const Text('Try Again'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
