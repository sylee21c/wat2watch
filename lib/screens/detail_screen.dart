import 'package:flutter/material.dart';
import 'package:wat2watch_app/models/content.dart';
import 'package:wat2watch_app/services/api_service.dart';
import 'package:wat2watch_app/widgets/content_card.dart';

class DetailScreen extends StatefulWidget {
  final Content content;
  const DetailScreen({super.key, required this.content});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // --- 상태 변수들 ---
  List<Map<String, dynamic>> cast = [];
  List<Content> similarMovies = [];
  List<Content> recommendedMovies = [];
  bool isLoadingCast = true;
  bool isLoadingSimilar = true;
  bool isLoadingRecommended = true;

  double userRating = 0.0;
  String? userComment;
  bool isSubmittingRating = false;
  bool hasUserRated = false;

  List<Map<String, dynamic>> watchProviders = [];
  bool isLoadingProviders = true;
  // --- 상태 변수 끝 ---

  @override
  void initState() {
    super.initState();
    _loadAdditionalData();
    _loadUserRating();
    _loadWatchProviders();
  }

  Future<void> _loadAdditionalData() async {
    final contentId = widget.content.id;
    if (contentId == null) {
      setState(() {
        isLoadingCast = false;
        isLoadingSimilar = false;
        isLoadingRecommended = false;
      });
      return;
    }

    final contentIdString = contentId.toString();

    try {
      final castData = await ApiService.fetchMovieCast(contentIdString);
      if (mounted) {
        setState(() {
          cast = castData;
          isLoadingCast = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading cast: $e");
      if (mounted) setState(() => isLoadingCast = false);
    }

    try {
      final similar = await ApiService.fetchSimilarMovies(contentIdString);
      if (mounted) {
        setState(() {
          similarMovies = similar;
          isLoadingSimilar = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading similar movies: $e");
      if (mounted) setState(() => isLoadingSimilar = false);
    }

    try {
      final recommended = await ApiService.fetchRecommendedMoviesForMovie(contentIdString);
      if (mounted) {
        setState(() {
          recommendedMovies = recommended;
          isLoadingRecommended = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading recommended movies: $e");
      if (mounted) setState(() => isLoadingRecommended = false);
    }
  }

  Future<void> _loadUserRating() async {
    try {
      final contentId = widget.content.id;
      if (contentId != null) {
        final rating = await ApiService.getUserRating('user_id', contentId.toString());
        // 코멘트도 조회하려면 getUserRating이 comment까지 반환해야 함!
        if (mounted && rating != null) {
          setState(() {
            userRating = rating; // 이 부분은 서버 API 맞게 조정
            hasUserRated = true;
            // userComment = ... // comment도 서버에서 함께 받아온다면 여기서 세팅
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user rating: $e");
    }
  }

  Future<void> _showRatingDialog() async {
    double tempRating = userRating > 0 ? userRating : 3.0;
    final commentController = TextEditingController(text: userComment ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('별점 및 코멘트 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('별점: ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Slider(
                      value: tempRating,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      onChanged: (v) => setState(() => tempRating = v),
                      label: tempRating.toStringAsFixed(1),
                    ),
                  ),
                  Text(tempRating.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '코멘트 (선택)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'rating': tempRating,
                  'comment': commentController.text.trim(),
                });
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await _submitRating(result['rating'], result['comment']);
    }
  }

  Future<void> _submitRating(double rating, String? comment) async {
    setState(() {
      isSubmittingRating = true;
    });

    try {
      final contentId = widget.content.id;
      if (contentId != null) {
        await ApiService.submitRating('user_id', contentId.toString(), rating, comment ?? '');
        if (mounted) {
          setState(() {
            userRating = rating;
            userComment = comment ?? '';
            hasUserRated = true;
            isSubmittingRating = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('별점 ${rating.toStringAsFixed(1)}점이 등록되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('콘텐츠 ID가 없습니다.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSubmittingRating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('별점 등록에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadWatchProviders() async {
    final contentId = widget.content.id;
    if (contentId == null) {
      setState(() {
        watchProviders = [];
        isLoadingProviders = false;
      });
      return;
    }
    try {
      final providers = await ApiService.fetchWatchProviders(contentId.toString());
      if (mounted) {
        setState(() {
          watchProviders = providers;
          isLoadingProviders = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading watch providers: $e");
      if (mounted) {
        setState(() {
          watchProviders = [];
          isLoadingProviders = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.content.posterUrl != null
        ? 'https://image.tmdb.org/t/p/w500${widget.content.posterUrl}'
        : null;

    final backdropUrl = widget.content.backdropUrl != null
        ? 'https://image.tmdb.org/t/p/w780${widget.content.backdropUrl}'
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.content.title ?? '영화 상세',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (backdropUrl != null)
                    Image.network(
                      backdropUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey[800]);
                      },
                    )
                  else
                    Container(color: Colors.grey[800]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 포스터와 기본 정보
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 포스터
                      Container(
                        width: 120,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl != null
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.movie, size: 50),
                              );
                            },
                          )
                              : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.movie, size: 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 기본 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.content.title ?? '제목 없음',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.content.originalTitle != null &&
                                widget.content.originalTitle != widget.content.title) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.content.originalTitle!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            _buildRatingSection(),
                            const SizedBox(height: 8),
                            _buildBasicInfo(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 👇 OTT 정보 표시
                  if (isLoadingProviders)
                    Row(
                      children: const [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 8),
                        Text('시청 가능 OTT 정보를 불러오는 중...'),
                      ],
                    )
                  else if (watchProviders.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          '시청 가능한 OTT',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: watchProviders.map((provider) {
                            final logoUrl = provider['logo_path'] != null
                                ? 'https://image.tmdb.org/t/p/w92${provider['logo_path']}'
                                : null;
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (logoUrl != null)
                                  Image.network(
                                    logoUrl,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.tv, size: 40),
                                  )
                                else
                                  const Icon(Icons.tv, size: 40),
                                const SizedBox(height: 4),
                                Text(
                                  provider['provider_name'] ?? '',
                                  style: const TextStyle(fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  else
                    const Text(
                      '시청 가능한 OTT 정보 없음',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),

                  const SizedBox(height: 24),
                  _buildUserRatingSection(),
                  const SizedBox(height: 24),

                  // 장르
                  if (widget.content.genres != null && widget.content.genres!.isNotEmpty) ...[
                    const Text(
                      '장르',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.content.genres!.map((genre) {
                        return Chip(
                          label: Text(genre),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 줄거리
                  const Text(
                    '줄거리',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.content.overview ?? '줄거리 정보가 없습니다.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  _buildCastSection(),
                  const SizedBox(height: 24),
                  _buildProductionInfo(),
                  const SizedBox(height: 24),
                  _buildSimilarMoviesSection(),
                  const SizedBox(height: 24),
                  _buildRecommendedMoviesSection(),
                  const SizedBox(height: 24),

                  if (widget.content.tagline != null && widget.content.tagline!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        '"${widget.content.tagline}"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------- 섹션 위젯 함수들 -----------------
  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.content.releaseDate != null) ...[
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 4),
              Text(
                widget.content.releaseDate!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (widget.content.runtime != null) ...[
          Row(
            children: [
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.content.runtime}분',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 출연진',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (isLoadingCast)
          const Center(child: CircularProgressIndicator())
        else if (cast.isEmpty)
          const Text(
            '출연진 정보가 없습니다.',
            style: TextStyle(color: Colors.grey),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cast.length > 10 ? 10 : cast.length,
              itemBuilder: (context, index) {
                final actor = cast[index];
                final profileUrl = actor['profile_path'] != null
                    ? 'https://image.tmdb.org/t/p/w185${actor['profile_path']}'
                    : null;

                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: ClipOval(
                          child: profileUrl != null
                              ? Image.network(
                            profileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 40);
                            },
                          )
                              : const Icon(Icons.person, size: 40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actor['name'] ?? '알 수 없음',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        actor['character'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildUserRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '이 영화를 평가해주세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: isSubmittingRating ? null : _showRatingDialog,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ...List.generate(5, (index) {
                        double starValue = index + 1.0;
                        return Icon(
                          userRating >= starValue
                              ? Icons.star
                              : userRating >= starValue - 0.5
                              ? Icons.star_half
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        );
                      }),
                      const SizedBox(width: 8),
                      if (userRating > 0)
                        Text(
                          '${userRating.toStringAsFixed(1)}점',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isSubmittingRating)
                  const Icon(Icons.edit, color: Colors.blue),
              ],
            ),
          ),
          if (hasUserRated) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  '평가 완료',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (userComment != null && userComment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.comment, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      userComment!,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ]
          ],
          if (isSubmittingRating) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('평가 저장 중...', style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.content.voteAverage != null) ...[
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${widget.content.voteAverage!.toStringAsFixed(1)}/10',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(TMDB)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (widget.content.voteCount != null) ...[
                const SizedBox(width: 8),
                Text(
                  '(${widget.content.voteCount}명)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
        // 사용자 평점 표시
        if (hasUserRated) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.blue, size: 16),
              const SizedBox(width: 4),
              Text(
                '내 평점: ${userRating.toStringAsFixed(1)}/5',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSimilarMoviesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '비슷한 영화',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (isLoadingSimilar)
          const Center(child: CircularProgressIndicator())
        else if (similarMovies.isEmpty)
          const Text(
            '비슷한 영화가 없습니다.',
            style: TextStyle(color: Colors.grey),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: similarMovies.length,
              itemBuilder: (context, index) {
                final movie = similarMovies[index];
                return ContentCard(
                  content: movie,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(content: movie),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendedMoviesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 영화',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (isLoadingRecommended)
          const Center(child: CircularProgressIndicator())
        else if (recommendedMovies.isEmpty)
          const Text(
            '추천 영화가 없습니다.',
            style: TextStyle(color: Colors.grey),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recommendedMovies.length,
              itemBuilder: (context, index) {
                final movie = recommendedMovies[index];
                return ContentCard(
                  content: movie,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(content: movie),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.content.productionCompanies != null &&
            widget.content.productionCompanies!.isNotEmpty) ...[
          const Text(
            '제작사',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.content.productionCompanies!.join(', '),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.content.productionCountries != null &&
            widget.content.productionCountries!.isNotEmpty) ...[
          const Text(
            '제작 국가',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.content.productionCountries!.join(', '),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.content.budget != null && widget.content.budget! > 0) ...[
          const Text(
            '예산',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_formatCurrency(widget.content.budget!)}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.content.revenue != null && widget.content.revenue! > 0) ...[
          const Text(
            '박스오피스',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_formatCurrency(widget.content.revenue!)}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ],
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toString();
    }
  }
}
