import 'dart:async' show Completer;

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
import 'package:decidish/widgets/meal_review_sheet.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum _FeedTab { all, meals, social }

enum _SocialSub { community, friends }

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  FeedPayload? _feed;
  bool _loading = true;
  String? _error;
  final Map<String, int> _ratings = {};
  final Map<String, String> _reviewTexts = {};
  Set<String> _decisionIds = {};
  Set<String> _favoriteIds = {};
  final Set<String> _ratingSaving = {};
  _FeedTab _feedTab = _FeedTab.all;
  _SocialSub _socialSub = _SocialSub.community;

  /// Synced with [PageView] under Social (0 = Community, 1 = Friends).
  int _socialPageIndex = 0;
  late final PageController _socialPageController;

  @override
  void initState() {
    super.initState();
    _socialPageIndex = _socialSub == _SocialSub.friends ? 1 : 0;
    _socialPageController = PageController(initialPage: _socialPageIndex);
    _loadDecisionIds();
    _loadFeed();
  }

  @override
  void dispose() {
    _socialPageController.dispose();
    super.dispose();
  }

  void _setMainFeedTab(_FeedTab tab) {
    setState(() => _feedTab = tab);
    if (tab == _FeedTab.social) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_socialPageController.hasClients) return;
        final idx = _socialSub == _SocialSub.friends ? 1 : 0;
        _socialPageController.jumpToPage(idx);
        setState(() => _socialPageIndex = idx);
      });
    }
  }

  void _animateSocialPage(int index) {
    if (!_socialPageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _animateSocialPage(index);
      });
      return;
    }
    _socialPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
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
        _reviewTexts
          ..clear()
          ..addAll(payload.myReviewTexts);
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
    final previous = _ratings[id];
    if (previous != null && previous == stars) {
      await _clearMealRating(meal);
      return;
    }
    setState(() {
      _ratingSaving.add(id);
      _ratings[id] = stars;
    });
    try {
      await MealApiService.rateMeal(id, stars, syncReview: false);
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

  Future<void> _clearMealRating(MealModel meal) async {
    final id = meal.id;
    if (_ratingSaving.contains(id)) return;
    setState(() {
      _ratingSaving.add(id);
      _ratings.remove(id);
      _reviewTexts.remove(id);
    });
    try {
      await MealApiService.removeMyLatestMealRating(id);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        // Already removed on server; local state is cleared.
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove rating')),
        );
        await _loadFeed();
      }
    } finally {
      if (mounted) {
        setState(() => _ratingSaving.remove(id));
      }
    }
  }

  Future<void> _openMealReviewEditor(MealModel meal) async {
    final initialStars = _ratings[meal.id] ?? 3;
    final initialText = _reviewTexts[meal.id] ?? '';

    final result = await showModalBottomSheet<(int, String)?>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => MealReviewSheet(
        mealName: meal.name,
        initialStars: initialStars,
        initialText: initialText,
      ),
    );

    if (result == null || !mounted) return;
    final saved = result;
    // Avoid setState while the modal route is still disposing (fixes
    // _dependents.isEmpty / MaterialApp assertion after sheet closes).
    final done = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        done.complete();
        return;
      }
      _saveMealReview(meal, saved.$1, saved.$2).whenComplete(done.complete);
    });
    await done.future;
  }

  Future<void> _saveMealReview(MealModel meal, int stars, String text) async {
    final id = meal.id;
    if (_ratingSaving.contains(id)) return;
    setState(() {
      _ratingSaving.add(id);
      _ratings[id] = stars;
      if (text.isNotEmpty) {
        _reviewTexts[id] = text;
      } else {
        _reviewTexts.remove(id);
      }
    });
    try {
      await MealApiService.rateMeal(
        id,
        stars,
        review: text,
        syncReview: true,
        append: true,
      );
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Could not save review';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) {
        setState(() => _ratingSaving.remove(id));
      }
    }
  }

  Future<void> _openPostAttachedMeal(FeedPostMeal m) async {
    final full = await MealApiService.getMealById(m.id);
    if (!mounted) return;
    if (full != null) {
      Navigator.pushNamed(context, '/recommendation', arguments: full);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not load meal')));
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
          meal: p.meal,
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
      myReviewTexts: feed.myReviewTexts,
    );
  }

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

  bool _sectionVisible(
    FeedSectionModel section,
    _FeedTab tab,
    _SocialSub socialSub,
  ) {
    final id = section.id;
    final hasMeals = section.meals.isNotEmpty;
    final hasPosts = section.posts.isNotEmpty;

    switch (tab) {
      case _FeedTab.all:
        return hasMeals || hasPosts;
      case _FeedTab.meals:
        return hasMeals;
      case _FeedTab.social:
        if (!hasPosts) return false;
        if (id == 'community') {
          return socialSub == _SocialSub.community;
        }
        if (id == 'friends') {
          return socialSub == _SocialSub.friends;
        }
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mq = MediaQuery.of(context);
            var maxH = constraints.maxHeight;
            if (!maxH.isFinite || maxH <= 0) {
              maxH =
                  mq.size.height - mq.padding.vertical - mq.viewInsets.bottom;
            }
            maxH = maxH.clamp(120.0, mq.size.height);
            return SizedBox(
              height: maxH,
              width: double.infinity,
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
                                'DeciDish',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Decide.Eat.Enjoy',
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
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.primary,
                          onPressed: _openNewPost,
                          tooltip: 'New post',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Fixed height: non-flex Column children get unbounded max
                        // height; a horizontal ScrollView can otherwise expand to a
                        // huge intrinsic height and blow up the parent Column.
                        SizedBox(
                          height: 48,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FeedFilterPill(
                                    label: 'All',
                                    selected: _feedTab == _FeedTab.all,
                                    onTap: () => _setMainFeedTab(_FeedTab.all),
                                  ),
                                  const SizedBox(width: 8),
                                  _FeedFilterPill(
                                    label: 'Meals',
                                    selected: _feedTab == _FeedTab.meals,
                                    onTap: () =>
                                        _setMainFeedTab(_FeedTab.meals),
                                  ),
                                  const SizedBox(width: 8),
                                  _FeedFilterPill(
                                    label: 'Social',
                                    selected: _feedTab == _FeedTab.social,
                                    onTap: () =>
                                        _setMainFeedTab(_FeedTab.social),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_feedTab == _FeedTab.social) ...[
                          const SizedBox(height: 8),
                          // Fixed height so parent Column(mainAxisSize: min) does not
                          // use scroll view intrinsic height (~full scroll extent).
                          SizedBox(
                            height: 60,
                            child: _SocialSwipeTabBar(
                              pageController: _socialPageController,
                              onCommunity: () => _animateSocialPage(0),
                              onFriends: () => _animateSocialPage(1),
                            ),
                          ),
                        ],
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
                        : _feedTab == _FeedTab.social
                        ? _buildSocialSwipeBody()
                        : RefreshIndicator(
                            onRefresh: _loadFeed,
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                if (_feed != null &&
                                    (_feedTab == _FeedTab.all ||
                                        _feedTab == _FeedTab.meals)) ...[
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
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSectionSlivers() {
    return _buildSectionSliversFor(_feedTab, _socialSub);
  }

  /// Builds feed section slivers for a fixed tab/social pair (used by Social [PageView]).
  List<Widget> _buildSectionSliversFor(_FeedTab tab, _SocialSub socialSub) {
    final feed = _feed!;
    final out = <Widget>[];

    for (final section in feed.sections) {
      final isMeals = section.meals.isNotEmpty;
      final isPosts = section.posts.isNotEmpty;

      if (!isMeals && !isPosts) continue;
      if (!_sectionVisible(section, tab, socialSub)) continue;

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
                      onReview: () => _openMealReviewEditor(meal),
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
                  onOpenAttachedMeal: post.meal != null
                      ? () => _openPostAttachedMeal(post.meal!)
                      : null,
                ),
              );
            }, childCount: section.posts.length),
          ),
        );
      }
    }

    return out;
  }

  Widget _buildSocialSwipeBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: PageView(
            controller: _socialPageController,
            onPageChanged: (index) {
              setState(() {
                _socialPageIndex = index;
                _socialSub = index == 0
                    ? _SocialSub.community
                    : _SocialSub.friends;
              });
            },
            children: [
              _buildSocialPageScroll(_SocialSub.community),
              _buildSocialPageScroll(_SocialSub.friends),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialPageScroll(_SocialSub sub) {
    return RefreshIndicator(
      onRefresh: _loadFeed,
      displacement: 40,
      child: CustomScrollView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          ..._buildSectionSliversFor(_FeedTab.social, sub),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Rounded pill filters (same look as original feed chip strips).
class _FeedFilterPill extends StatelessWidget {
  const _FeedFilterPill({
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
              fontSize: 14,
              color: selected ? AppColors.primary : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width one-line bar for Community vs Friends. The accent line tracks
/// [PageController.page] during swipes and programmatic page animations.
class _SocialSwipeTabBar extends StatefulWidget {
  const _SocialSwipeTabBar({
    required this.pageController,
    required this.onCommunity,
    required this.onFriends,
  });

  final PageController pageController;
  final VoidCallback onCommunity;
  final VoidCallback onFriends;

  @override
  State<_SocialSwipeTabBar> createState() => _SocialSwipeTabBarState();
}

class _SocialSwipeTabBarState extends State<_SocialSwipeTabBar> {
  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_onPageTick);
  }

  @override
  void didUpdateWidget(covariant _SocialSwipeTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController.removeListener(_onPageTick);
      widget.pageController.addListener(_onPageTick);
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageTick);
    super.dispose();
  }

  void _onPageTick() => setState(() {});

  static const double _gutter = 20;

  @override
  Widget build(BuildContext context) {
    // [.page] asserts when no PageView has attached yet (tab bar can build first).
    final pc = widget.pageController;
    final page = pc.hasClients
        ? (pc.page ?? pc.initialPage.toDouble())
        : pc.initialPage.toDouble();
    final communityT = (1.0 - page).clamp(0.0, 1.0);
    final friendsT = page.clamp(0.0, 1.0);
    final curve = Curves.easeOutCubic;
    final communityBlend = curve.transform(communityT);
    final friendsBlend = curve.transform(friendsT);

    // Parent adds horizontal padding 16+16; bar must have a stable width for the
    // underline. On narrow screens, allow horizontal scroll (min width 280).
    final viewW = MediaQuery.sizeOf(context).width;
    final usableW = (viewW - 32).clamp(120.0, viewW);
    const minBarW = 280.0;
    final contentW = math.max(usableW, minBarW);

    final half = contentW / 2;
    final barW = (half - 2 * _gutter).clamp(8.0, half);
    final maxLeft = contentW - barW - _gutter;
    final left = (page * half + _gutter).clamp(_gutter, maxLeft);

    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: contentW,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: widget.onCommunity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                'Community',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.lerp(
                                    FontWeight.w500,
                                    FontWeight.w700,
                                    communityBlend,
                                  )!,
                                  color: Color.lerp(
                                    AppColors.textLight,
                                    AppColors.primary,
                                    communityBlend,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: AppColors.textLight.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: widget.onFriends,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                'Friends',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.lerp(
                                    FontWeight.w500,
                                    FontWeight.w700,
                                    friendsBlend,
                                  )!,
                                  color: Color.lerp(
                                    AppColors.textLight,
                                    AppColors.primary,
                                    friendsBlend,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 4,
                  width: contentW,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: left,
                        width: barW,
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.45),
                                blurRadius: 6,
                                spreadRadius: 0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    required this.onReview,
    this.rating,
    this.isFavorite = false,
    this.inDecisionList = false,
  });

  final MealModel meal;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onDecisionTap;
  final VoidCallback onReview;
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
                  height: 112,
                  width: double.infinity,
                  child: MealNetworkImage(
                    imageUrl: meal.imageUrl,
                    height: 112,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                    iconSize: 40,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textLight,
                        ),
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
                    const SizedBox(height: 4),
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
                                  color: filled
                                      ? Colors.amber
                                      : AppColors.textLight,
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
                          icon: const Icon(Icons.rate_review_outlined),
                          color: AppColors.textLight,
                          onPressed: onReview,
                          tooltip: 'Written review',
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: Icon(
                            inDecisionList
                                ? Icons.bookmark
                                : Icons.bookmark_border,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onLike,
    this.onOpenAttachedMeal,
  });

  final FeedPostModel post;
  final VoidCallback onLike;
  final VoidCallback? onOpenAttachedMeal;

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
          if (post.meal != null && onOpenAttachedMeal != null) ...[
            const SizedBox(height: 10),
            Material(
              color: AppColors.secondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onOpenAttachedMeal,
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

class _NewPostDialog extends StatefulWidget {
  const _NewPostDialog();

  @override
  State<_NewPostDialog> createState() => _NewPostDialogState();
}

class _NewPostDialogState extends State<_NewPostDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  MealModel? _attachedMeal;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickMeal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => _AttachMealSheet(
        onSelect: (m) {
          Navigator.pop(ctx);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _attachedMeal = m);
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await PostService.createPost(text, mealId: _attachedMeal?.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final msg = e is ApiException
            ? e.message
            : e.toString().replaceAll('ApiException: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share with the community'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Quick review, tip, or dish you loved…',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickMeal,
              icon: const Icon(Icons.restaurant_menu),
              label: Text(
                _attachedMeal == null
                    ? 'Attach a meal (optional)'
                    : 'Change attached meal',
              ),
            ),
            if (_attachedMeal != null) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: MealNetworkImage(
                      imageUrl: _attachedMeal!.imageUrl,
                      height: 44,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      iconSize: 20,
                    ),
                  ),
                ),
                title: Text(
                  _attachedMeal!.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _loading
                      ? null
                      : () => setState(() => _attachedMeal = null),
                  tooltip: 'Remove',
                ),
              ),
            ],
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
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

class _AttachMealSheet extends StatefulWidget {
  const _AttachMealSheet({required this.onSelect});

  final ValueChanged<MealModel> onSelect;

  @override
  State<_AttachMealSheet> createState() => _AttachMealSheetState();
}

class _AttachMealSheetState extends State<_AttachMealSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<MealModel> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    try {
      final q = _searchController.text.trim();
      final list = await MealApiService.getMeals(search: q.isEmpty ? null : q);
      if (mounted) {
        setState(() {
          _results = list.take(40).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search meals to attach',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _runSearch,
                  ),
                ),
                onSubmitted: (_) => _runSearch(),
              ),
            ),
            if (_loading)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final m = _results[i];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: MealNetworkImage(
                          imageUrl: m.imageUrl,
                          height: 48,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(8),
                          iconSize: 22,
                        ),
                      ),
                    ),
                    title: Text(
                      m.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: m.cuisine != null ? Text(m.cuisine!) : null,
                    onTap: () => widget.onSelect(m),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
