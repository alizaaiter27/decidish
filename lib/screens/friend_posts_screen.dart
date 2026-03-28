import 'package:decidish/models/feed_models.dart';
import 'package:decidish/services/api_service.dart';
import 'package:decidish/services/meal_api_service.dart';
import 'package:decidish/services/post_service.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/widgets/meal_network_image.dart';
import 'package:flutter/material.dart';

class FriendPostsScreen extends StatefulWidget {
  const FriendPostsScreen({super.key});

  @override
  State<FriendPostsScreen> createState() => _FriendPostsScreenState();
}

class _FriendPostsScreenState extends State<FriendPostsScreen> {
  String _friendId = '';
  String _friendName = '';
  List<FeedPostModel> _posts = [];
  bool _loading = true;
  String? _error;
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _friendId = args['userId']?.toString() ?? '';
      _friendName = args['name']?.toString() ?? 'Friend';
    }
    if (_friendId.isEmpty) {
      setState(() => _loading = false);
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await PostService.getPostsForFriend(_friendId);
      if (!mounted) return;
      final list = raw
          .map(
            (e) => FeedPostModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      setState(() {
        _posts = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike(FeedPostModel post) async {
    try {
      final res = post.likedByMe
          ? await PostService.unlikePost(post.id)
          : await PostService.likePost(post.id);
      if (!mounted) return;
      final liked = res['likedByMe'] == true;
      final count = (res['likesCount'] as num?)?.toInt() ?? post.likesCount;
      setState(() {
        _posts = _posts.map((p) {
          if (p.id != post.id) return p;
          return FeedPostModel(
            id: p.id,
            content: p.content,
            createdAt: p.createdAt,
            likesCount: count,
            likedByMe: liked,
            user: p.user,
            meal: p.meal,
          );
        }).toList();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update like')),
        );
      }
    }
  }

  Future<void> _openAttachedMeal(FeedPostMeal m) async {
    final full = await MealApiService.getMealById(m.id);
    if (!mounted) return;
    if (full != null) {
      Navigator.pushNamed(context, '/recommendation', arguments: full);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load meal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_friendName.isNotEmpty ? _friendName : 'Posts'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _friendId.isEmpty
          ? const Center(child: Text('Missing friend'))
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _posts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No posts yet',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FriendPostTile(
                            post: post,
                            onLike: () => _toggleLike(post),
                            onOpenMeal: post.meal != null
                                ? () => _openAttachedMeal(post.meal!)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _FriendPostTile extends StatelessWidget {
  const _FriendPostTile({
    required this.post,
    required this.onLike,
    this.onOpenMeal,
  });

  final FeedPostModel post;
  final VoidCallback onLike;
  final VoidCallback? onOpenMeal;

  @override
  Widget build(BuildContext context) {
    final name = post.user?.name ?? post.user?.email ?? 'Friend';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondary,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: Icon(
                  post.likedByMe ? Icons.favorite : Icons.favorite_border,
                  color: post.likedByMe ? Colors.redAccent : AppColors.textLight,
                ),
                onPressed: onLike,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.content),
          if (post.meal != null && onOpenMeal != null) ...[
            const SizedBox(height: 10),
            Material(
              color: AppColors.secondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onOpenMeal,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: MealNetworkImage(
                            imageUrl: post.meal!.imageUrl,
                            height: 52,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                            iconSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recipe',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                            Text(
                              post.meal!.name ?? 'Meal',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${post.likesCount} likes',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
