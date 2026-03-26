import 'package:decidish/models/feed_models.dart';
import 'package:decidish/models/meal_model.dart';
import 'package:decidish/services/api_service.dart';
import 'package:decidish/services/decision_list_service.dart';
import 'package:decidish/services/favorites_api_service.dart';
import 'package:decidish/services/feed_api_service.dart';
import 'package:decidish/services/meal_api_service.dart';
import 'package:decidish/services/post_service.dart';
import 'package:decidish/utils/app_colors.dart';
import 'package:decidish/widgets/meal_network_image.dart';
import 'package:flutter/material.dart';

enum _FeedFilter { all, meals, social }

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  FeedPayload? _feed;
  bool _loading = true;
  String? _error;
  _FeedFilter _filter = _FeedFilter.all;
  final Map<String, int> _ratings = {};
  Set<String> _decisionIds = {};
  Set<String> _favoriteIds = {};
  final Set<String> _ratingSaving = {};

  @override
  void initState() {
    super.initState();
    _loadDecisionIds();
    _loadFeed();
  }

  Future<void> _loadDecisionIds() async {
    final ids = await DecisionListService.getIds();
    if (mounted) setState(() => _decisionIds = ids);
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await FeedApiService.getFeed();
      final favs = await FavoritesApiService.getFavorites();
      if (!mounted) return;
      setState(() {
        _feed = payload;
        _ratings.addAll(payload.myRatings);
        _favoriteIds = favs.map((m) => m.id).toSet();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : e.toString().replaceAll('ApiException: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(MealModel meal) async {
    final id = meal.id;
    final isFav = _favoriteIds.contains(id);
    try {
      if (isFav) {
        final ok = await FavoritesApiService.removeFavoriteByMealId(id);
        if (ok && mounted) setState(() => _favoriteIds.remove(id));
      } else {
        final ok = await FavoritesApiService.addFavorite(id);
        if (ok && mounted) setState(() => _favoriteIds.add(id));
      }
    } catch (_) {}
  }

  Future<void> _toggleDecision(MealModel meal) async {
    await DecisionListService.toggle(meal.id);
    await _loadDecisionIds();
  }

  Future<void> _setRating(MealModel meal, int stars) async {
    final id = meal.id;
    if (_ratingSaving.contains(id)) return;
    setState(() {
      _ratingSaving.add(id);
      _ratings[id] = stars;
    });
    try {
      await MealApiService.rateMeal(id, stars);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not save rating')));
      }
    } finally {
      if (mounted) {
        setState(() => _ratingSaving.remove(id));
      }
    }
  }

  Future<void> _togglePostLike(FeedPostModel post) async {
    try {
      final res = post.likedByMe
          ? await PostService.unlikePost(post.id)
          : await PostService.likePost(post.id);
      if (!mounted) return;
      final liked = res['likedByMe'] == true;
      final count = (res['likesCount'] as num?)?.toInt() ?? post.likesCount;
      setState(() {
        if (_feed == null) return;
        _feed = _replacePostInFeed(_feed!, post.id, liked, count);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not update like')));
      }
    }
  }

  FeedPayload _replacePostInFeed(
    FeedPayload feed,
    String postId,
    bool liked,
    int count,
  ) {
    final sections = feed.sections.map((s) {
      final posts = s.posts.map((p) {
        if (p.id != postId) return p;
        return FeedPostModel(
          id: p.id,
          content: p.content,
          createdAt: p.createdAt,
          likesCount: count,
          likedByMe: liked,
          user: p.user,
        );
      }).toList();
      return FeedSectionModel(
        id: s.id,
        title: s.title,
        subtitle: s.subtitle,
        meals: s.meals,
        posts: posts,
      );
    }).toList();
    return FeedPayload(
      mealType: feed.mealType,
      sections: sections,
      quickDecide: feed.quickDecide,
      streakHint: feed.streakHint,
      myRatings: feed.myRatings,
    );
  }

  bool _showMeals(_FeedFilter f) =>
      f == _FeedFilter.all || f == _FeedFilter.meals;
  bool _showSocial(_FeedFilter f) =>
      f == _FeedFilter.all || f == _FeedFilter.social;

  Future<void> _surpriseMe() async {
    try {
      final meal = await MealApiService.getRecommendation(saveHistory: true);
      if (!mounted) return;
      if (meal != null) {
        Navigator.pushNamed(context, '/recommendation', arguments: meal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Could not get recommendation',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openNewPost() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _NewPostDialog(),
    );
    if (created == true) {
      await _loadFeed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Posted to the community')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feed',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Discover, decide, connect',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_feed != null && _feed!.streakHint > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        avatar: const Icon(
                          Icons.local_fire_department,
                          size: 18,
                        ),
                        label: Text('${_feed!.streakHint} streak'),
                        backgroundColor: AppColors.secondary,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    color: AppColors.primary,
                    onPressed: _showFilterSheet,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                    onPressed: _openNewPost,
                    tooltip: 'New post',
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == _FeedFilter.all,
                    onTap: () => setState(() => _filter = _FeedFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Meals',
                    selected: _filter == _FeedFilter.meals,
                    onTap: () => setState(() => _filter = _FeedFilter.meals),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Social',
                    selected: _filter == _FeedFilter.social,
                    onTap: () => setState(() => _filter = _FeedFilter.social),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadFeed,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFeed,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (_feed != null && _showMeals(_filter)) ...[
                            SliverToBoxAdapter(
                              child: _QuickDecide(
                                meals: _feed!.quickDecide,
                                onPick: (m) {
                                  Navigator.pushNamed(
                                    context,
                                    '/recommendation',
                                    arguments: m,
                                  );
                                },
                                onShuffle: _loadFeed,
                                onSurprise: _surpriseMe,
                              ),
                            ),
                          ],
                          if (_feed != null) ..._buildSectionSlivers(),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSectionSlivers() {
    final feed = _feed!;
    final out = <Widget>[];

    for (final section in feed.sections) {
      final isMeals = section.meals.isNotEmpty;
      final isPosts = section.posts.isNotEmpty;

      if (isMeals && !_showMeals(_filter)) continue;
      if (isPosts && !_showSocial(_filter)) continue;
      if (!isMeals && !isPosts) continue;

      out.add(
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: section.title,
            subtitle: section.subtitle,
          ),
        ),
      );

      if (isMeals) {
        out.add(
          SliverToBoxAdapter(
            child: SizedBox(
              height: 340,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: section.meals.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final meal = section.meals[i];
                  return SizedBox(
                    width: 280,
                    child: _MealFeedCard(
                      meal: meal,
                      rating: _ratings[meal.id],
                      isFavorite: _favoriteIds.contains(meal.id),
                      inDecisionList: _decisionIds.contains(meal.id),
                      onOpen: () => Navigator.pushNamed(
                        context,
                        '/recommendation',
                        arguments: meal,
                      ),
                      onFavorite: () => _toggleFavorite(meal),
                      onDecisionTap: () => _toggleDecision(meal),
                      onRate: (s) => _setRating(meal, s),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }

      if (isPosts) {
        out.add(
          SliverList(
            delegate: SliverChildBuilderDelegate((context, i) {
              final post = section.posts[i];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: _PostCard(
                  post: post,
                  onLike: () => _togglePostLike(post),
                ),
              );
            }, childCount: section.posts.length),
          ),
        );
      }
    }

    return out;
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Show',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Everything'),
              subtitle: const Text('Meals, trending, friends & community'),
              onTap: () {
                setState(() => _filter = _FeedFilter.all);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Meals only'),
              onTap: () {
                setState(() => _filter = _FeedFilter.meals);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('Social only'),
              onTap: () {
                setState(() => _filter = _FeedFilter.social);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
        ],
      ),
    );
  }
}

class _QuickDecide extends StatelessWidget {
  const _QuickDecide({
    required this.meals,
    required this.onPick,
    required this.onShuffle,
    required this.onSurprise,
  });

  final List<MealModel> meals;
  final ValueChanged<MealModel> onPick;
  final VoidCallback onShuffle;
  final VoidCallback onSurprise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick decide',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick one or let the app choose for you',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          if (meals.length >= 2)
            Row(
              children: [
                Expanded(
                  child: _QuickTile(
                    meal: meals[0],
                    label: 'A',
                    onTap: () => onPick(meals[0]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickTile(
                    meal: meals[1],
                    label: 'B',
                    onTap: () => onPick(meals[1]),
                  ),
                ),
              ],
            )
          else if (meals.length == 1)
            _QuickTile(
              meal: meals[0],
              label: 'Pick',
              onTap: () => onPick(meals[0]),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: onShuffle,
                icon: const Icon(Icons.shuffle, size: 18),
                label: const Text('Shuffle options'),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: onSurprise,
                child: const Text('Surprise me'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.meal,
    required this.label,
    required this.onTap,
  });

  final MealModel meal;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meal.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (meal.cuisine != null)
                Text(
                  meal.cuisine!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealFeedCard extends StatelessWidget {
  const _MealFeedCard({
    required this.meal,
    required this.onOpen,
    required this.onFavorite,
    required this.onDecisionTap,
    required this.onRate,
    this.rating,
    this.isFavorite = false,
    this.inDecisionList = false,
  });

  final MealModel meal;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onDecisionTap;
  final void Function(int) onRate;
  final int? rating;
  final bool isFavorite;
  final bool inDecisionList;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: MealNetworkImage(
                    imageUrl: meal.imageUrl,
                    height: 120,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                    iconSize: 40,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.redAccent
                          : AppColors.textLight,
                      size: 22,
                    ),
                    onPressed: onFavorite,
                  ),
                ],
              ),
              if (meal.cuisine != null)
                Text(
                  meal.cuisine!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    '${meal.preparationTime ?? 0} min',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  if (meal.estimatedCost != null) ...[
                    const Text(
                      ' · ',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                    Text(
                      '\$${meal.estimatedCost!}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 2,
                      runSpacing: 0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        final r = rating;
                        final filled = r != null && star <= r;
                        return GestureDetector(
                          onTap: () => onRate(star),
                          child: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 18,
                            color: filled ? Colors.amber : AppColors.textLight,
                          ),
                        );
                      }),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Icon(
                      inDecisionList ? Icons.bookmark : Icons.bookmark_border,
                      color: inDecisionList
                          ? AppColors.primary
                          : AppColors.textLight,
                    ),
                    onPressed: onDecisionTap,
                    tooltip: 'Decision list',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onLike});

  final FeedPostModel post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final name = post.user?.name ?? post.user?.email ?? 'Someone';
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
                  color: post.likedByMe
                      ? Colors.redAccent
                      : AppColors.textLight,
                ),
                onPressed: onLike,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.content),
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

class _NewPostDialog extends StatefulWidget {
  const _NewPostDialog();

  @override
  State<_NewPostDialog> createState() => _NewPostDialogState();
}

class _NewPostDialogState extends State<_NewPostDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await PostService.createPost(text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share with the community'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Quick review, tip, or dish you loved…',
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: const Text('Post'),
        ),
      ],
    );
  }
}
