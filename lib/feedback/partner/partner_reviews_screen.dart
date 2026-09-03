import 'package:flutter/material.dart';

import '../models/feedback_model.dart';
import '../models/feedback_summary_model.dart';
import '../services/feedback_service.dart';

class PartnerReviewsScreen extends StatefulWidget {
  final FeedbackServiceType serviceType;
  final FeedbackTargetType targetType;
  final String targetId;
  final String partnerName;
  final FeedbackService? feedbackService;
  final ValueChanged<FeedbackModel>? onReviewOpened;
  final ValueChanged<FeedbackModel>? onReplyRequested;

  const PartnerReviewsScreen({
    super.key,
    required this.serviceType,
    required this.targetType,
    required this.targetId,
    this.partnerName = '',
    this.feedbackService,
    this.onReviewOpened,
    this.onReplyRequested,
  });

  @override
  State<PartnerReviewsScreen> createState() => _PartnerReviewsScreenState();
}

class _PartnerReviewsScreenState extends State<PartnerReviewsScreen> {
  late final FeedbackService _feedbackService;

  int? _selectedRating;
  bool _unansweredOnly = false;

  @override
  void initState() {
    super.initState();
    _feedbackService = widget.feedbackService ?? FeedbackService();
  }

  Stream<List<FeedbackModel>> _reviewsStream() {
    return _feedbackService.watchTargetReviews(
      serviceType: widget.serviceType,
      targetId: widget.targetId,
      publicOnly: true,
      limit: 100,
    );
  }

  Stream<FeedbackSummaryModel?> _summaryStream() {
    return _feedbackService.watchSummary(
      serviceType: widget.serviceType,
      targetType: widget.targetType,
      targetId: widget.targetId,
    );
  }

  List<FeedbackModel> _applyFilters(List<FeedbackModel> reviews) {
    return reviews
        .where((review) {
          if (_selectedRating != null && review.rating != _selectedRating) {
            return false;
          }

          if (_unansweredOnly && review.hasPartnerReply) {
            return false;
          }

          return true;
        })
        .toList(growable: false);
  }

  void _openReview(FeedbackModel review) {
    final callback = widget.onReviewOpened;

    if (callback != null) {
      callback(review);
    }
  }

  void _requestReply(FeedbackModel review) {
    final callback = widget.onReplyRequested;

    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply screen will be connected in the next step.'),
        ),
      );
      return;
    }

    callback(review);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.partnerName.trim().isEmpty
        ? '${widget.targetType.displayName} reviews'
        : widget.partnerName.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F6),
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          _PartnerSummarySection(
            summaryStream: _summaryStream(),
            serviceName: widget.serviceType.displayName,
            targetName: widget.targetType.displayName,
          ),
          _FilterSection(
            selectedRating: _selectedRating,
            unansweredOnly: _unansweredOnly,
            onRatingChanged: (rating) {
              setState(() {
                _selectedRating = rating;
              });
            },
            onUnansweredChanged: (value) {
              setState(() {
                _unansweredOnly = value;
              });
            },
          ),
          Expanded(
            child: StreamBuilder<List<FeedbackModel>>(
              stream: _reviewsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF111315)),
                  );
                }

                if (snapshot.hasError) {
                  return _PartnerMessageView(
                    icon: Icons.cloud_off_rounded,
                    title: 'Reviews could not be loaded',
                    message: 'Please check your connection and try again.',
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                final allReviews = snapshot.data ?? const <FeedbackModel>[];
                final reviews = _applyFilters(allReviews);

                if (allReviews.isEmpty) {
                  return const _PartnerMessageView(
                    icon: Icons.rate_review_outlined,
                    title: 'No reviews yet',
                    message: 'Verified customer reviews will appear here.',
                  );
                }

                if (reviews.isEmpty) {
                  return const _PartnerMessageView(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No matching reviews',
                    message: 'Change or clear the selected review filters.',
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF111315),
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final review = reviews[index];

                      return _PartnerReviewCard(
                        review: review,
                        repliesEnabled: widget.onReplyRequested != null,
                        onOpen: () => _openReview(review),
                        onReply: () => _requestReply(review),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerSummarySection extends StatelessWidget {
  final Stream<FeedbackSummaryModel?> summaryStream;
  final String serviceName;
  final String targetName;

  const _PartnerSummarySection({
    required this.summaryStream,
    required this.serviceName,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FeedbackSummaryModel?>(
      stream: summaryStream,
      builder: (context, snapshot) {
        final summary = snapshot.data;

        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF111315),
              borderRadius: BorderRadius.circular(24),
            ),
            child: summary == null
                ? _EmptyPartnerSummary(
                    serviceName: serviceName,
                    targetName: targetName,
                  )
                : _LoadedPartnerSummary(summary: summary),
          ),
        );
      },
    );
  }
}

class _LoadedPartnerSummary extends StatelessWidget {
  final FeedbackSummaryModel summary;

  const _LoadedPartnerSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  summary.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                _CompactStars(
                  rating: summary.averageRating,
                  color: const Color(0xFFFFC107),
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.totalReviews} verified reviews',
                  style: const TextStyle(
                    color: Color(0xFFB8BCC2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: <Widget>[
                  _RatingBreakdownRow(
                    rating: 5,
                    count: summary.ratingBreakdown.fiveStar,
                    total: summary.totalReviews,
                  ),
                  _RatingBreakdownRow(
                    rating: 4,
                    count: summary.ratingBreakdown.fourStar,
                    total: summary.totalReviews,
                  ),
                  _RatingBreakdownRow(
                    rating: 3,
                    count: summary.ratingBreakdown.threeStar,
                    total: summary.totalReviews,
                  ),
                  _RatingBreakdownRow(
                    rating: 2,
                    count: summary.ratingBreakdown.twoStar,
                    total: summary.totalReviews,
                  ),
                  _RatingBreakdownRow(
                    rating: 1,
                    count: summary.ratingBreakdown.oneStar,
                    total: summary.totalReviews,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(color: Color(0xFF33363A), height: 1),
        const SizedBox(height: 15),
        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryMetric(
                value: '${summary.repliedReviewCount}',
                label: 'Replied',
              ),
            ),
            Container(width: 1, height: 34, color: const Color(0xFF33363A)),
            Expanded(
              child: _SummaryMetric(
                value: '${summary.responsePercentage.toStringAsFixed(0)}%',
                label: 'Response rate',
              ),
            ),
            Container(width: 1, height: 34, color: const Color(0xFF33363A)),
            Expanded(
              child: _SummaryMetric(
                value: '${summary.lowRatingCount}',
                label: 'Low ratings',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyPartnerSummary extends StatelessWidget {
  final String serviceName;
  final String targetName;

  const _EmptyPartnerSummary({
    required this.serviceName,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFF292C30),
          child: Icon(
            Icons.star_outline_rounded,
            color: Color(0xFFFFC107),
            size: 29,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'No rating summary yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$serviceName • $targetName',
                style: const TextStyle(color: Color(0xFFB8BCC2), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterSection extends StatelessWidget {
  final int? selectedRating;
  final bool unansweredOnly;
  final ValueChanged<int?> onRatingChanged;
  final ValueChanged<bool> onUnansweredChanged;

  const _FilterSection({
    required this.selectedRating,
    required this.unansweredOnly,
    required this.onRatingChanged,
    required this.onUnansweredChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _PartnerFilterChip(
              label: 'All',
              selected: selectedRating == null,
              onTap: () => onRatingChanged(null),
            ),
            const SizedBox(width: 8),
            for (var rating = 5; rating >= 1; rating--) ...<Widget>[
              _PartnerFilterChip(
                label: '$rating ★',
                selected: selectedRating == rating,
                onTap: () => onRatingChanged(rating),
              ),
              const SizedBox(width: 8),
            ],
            _PartnerFilterChip(
              label: 'Needs reply',
              selected: unansweredOnly,
              icon: Icons.reply_rounded,
              onTap: () => onUnansweredChanged(!unansweredOnly),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerReviewCard extends StatelessWidget {
  final FeedbackModel review;
  final bool repliesEnabled;
  final VoidCallback onOpen;
  final VoidCallback onReply;

  const _PartnerReviewCard({
    required this.review,
    required this.repliesEnabled,
    required this.onOpen,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final reviewerName = review.publicReviewerName;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: review.rating <= 2
                  ? const Color(0xFFF1C7C4)
                  : const Color(0xFFE7E9EC),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ReviewerAvatar(
                    name: reviewerName,
                    photoUrl: review.isAnonymous ? '' : review.reviewerPhotoUrl,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                reviewerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF202124),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (review.isVerified) ...<Widget>[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified_rounded,
                                size: 17,
                                color: Color(0xFF188038),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatPartnerDate(review.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF8A8F98),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (review.rating <= 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEA),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Low rating',
                        style: TextStyle(
                          color: Color(0xFFD93025),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 13),
              _IntegerStars(rating: review.rating),
              if (review.comment.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 11),
                Text(
                  review.comment.trim(),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3C4043),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
              if (review.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: review.tags
                      .take(5)
                      .map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F4),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFF5F6368),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    review.hasPartnerReply
                        ? Icons.check_circle_outline_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: review.hasPartnerReply
                        ? const Color(0xFF188038)
                        : const Color(0xFF777C85),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      review.hasPartnerReply
                          ? 'Response sent'
                          : 'No response yet',
                      style: TextStyle(
                        color: review.hasPartnerReply
                            ? const Color(0xFF188038)
                            : const Color(0xFF777C85),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!review.hasPartnerReply)
                    TextButton.icon(
                      onPressed: repliesEnabled ? onReply : null,
                      icon: const Icon(Icons.reply_rounded, size: 18),
                      label: const Text('Reply'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF111315),
                        disabledForegroundColor: const Color(0xFF9AA0A6),
                      ),
                    )
                  else
                    TextButton(onPressed: onOpen, child: const Text('View')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewerAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;

  const _ReviewerAvatar({required this.name, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE8EAED),
      foregroundImage: photoUrl.trim().isEmpty
          ? null
          : NetworkImage(photoUrl.trim()),
      onForegroundImageError: photoUrl.trim().isEmpty
          ? null
          : (exception, stackTrace) {},
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF3C4043),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompactStars extends StatelessWidget {
  final double rating;
  final Color color;

  const _CompactStars({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (index) {
        return Icon(
          index < rating.round()
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          size: 17,
          color: color,
        );
      }),
    );
  }
}

class _IntegerStars extends StatelessWidget {
  final int rating;

  const _IntegerStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(5, (index) {
        final selected = index < rating;

        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            selected ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 22,
            color: selected ? const Color(0xFFFFB300) : const Color(0xFFBDC1C6),
          ),
        );
      }),
    );
  }
}

class _RatingBreakdownRow extends StatelessWidget {
  final int rating;
  final int count;
  final int total;

  const _RatingBreakdownRow({
    required this.rating,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 13,
            child: Text(
              '$rating',
              style: const TextStyle(
                color: Color(0xFFB8BCC2),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: const Color(0xFF36393D),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFFC107),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 18,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFFB8BCC2), fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFB8BCC2),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PartnerFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _PartnerFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF111315) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF111315)
                  : const Color(0xFFE1E4E8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : const Color(0xFF555960),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF555960),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _PartnerMessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 58, color: const Color(0xFF9AA0A6)),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF202124),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF777C85),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 17),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111315),
                ),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatPartnerDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();

  return '$day/$month/$year';
}
