import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/extension/snack_bar_extension.dart';
import 'package:otraku/feature/booru/booru_provider.dart';
import 'package:otraku/util/theming.dart';
import 'package:otraku/widget/cached_image.dart';
import 'package:otraku/widget/dialogs.dart';
import 'package:otraku/widget/layout/adaptive_scaffold.dart';
import 'package:otraku/widget/layout/hiding_floating_action_button.dart';
import 'package:otraku/widget/layout/top_bar.dart';
import 'package:otraku/widget/loaders.dart';

class BooruView extends ConsumerStatefulWidget {
  final String tag;
  const BooruView({required this.tag, super.key});

  @override
  ConsumerState<BooruView> createState() => _BooruViewState();
}

class _BooruViewState extends ConsumerState<BooruView> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(booruProvider(widget.tag));

    return AdaptiveScaffold(
      topBar: const TopBar(title: 'Random Image'),
      floatingAction: HidingFloatingActionButton(
        key: const Key('newImage'),
        scrollCtrl: _scrollCtrl,
        child: FloatingActionButton(
          tooltip: 'New Image',
          onPressed: () => ref.read(booruProvider(widget.tag).notifier).fetchNew(),
          child: const Icon(Ionicons.refresh_outline),
        ),
      ),
      child: post.when(
        loading: () => const Center(child: Loader()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Theming.offset,
            children: [
              Text('Failed to load: $error'),
              FilledButton.tonal(
                onPressed: () => ref.read(booruProvider(widget.tag).notifier).fetchNew(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (post) => CustomScrollView(
          controller: _scrollCtrl,
          physics: Theming.bouncyPhysics,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + Theming.normalTapTarget + Theming.offset,
                bottom: MediaQuery.paddingOf(context).bottom + 80,
                left: Theming.offset,
                right: Theming.offset,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Tap to view fullscreen.
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => ImageDialog(post.imageUrl),
                    ),
                    child: ClipRRect(
                      borderRadius: Theming.borderRadiusSmall,
                      child: AspectRatio(
                        aspectRatio: post.aspectRatio,
                        child: CachedImage(post.imageUrl),
                      ),
                    ),
                  ),
                  const SizedBox(height: Theming.offset),
                  if (post.tags.isNotEmpty) ...[
                    Text('Tags', style: TextTheme.of(context).labelSmall),
                    const SizedBox(height: 4),
                    // Tap tags to copy them.
                    GestureDetector(
                      onTap: () => SnackBarExtension.copy(context, post.tags),
                      child: Text(
                        post.tags,
                        style: TextTheme.of(context).labelMedium,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (post.source.isNotEmpty) ...[
                    const SizedBox(height: Theming.offset),
                    Text('Source', style: TextTheme.of(context).labelSmall),
                    const SizedBox(height: 4),
                    // Tap source to open in browser.
                    GestureDetector(
                      onTap: () => SnackBarExtension.launch(context, post.source),
                      child: Text(
                        post.source,
                        style: TextTheme.of(
                          context,
                        ).labelMedium?.copyWith(color: ColorScheme.of(context).primary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
