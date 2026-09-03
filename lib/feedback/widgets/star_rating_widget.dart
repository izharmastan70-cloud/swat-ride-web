import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double starSize;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;
  final bool readOnly;
  final bool showRatingLabel;
  final MainAxisAlignment alignment;
  final String semanticsLabel;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.starSize = 42,
    this.spacing = 6,
    this.activeColor = const Color(0xFFFFC107),
    this.inactiveColor = const Color(0xFFE1E4E8),
    this.readOnly = false,
    this.showRatingLabel = false,
    this.alignment = MainAxisAlignment.center,
    this.semanticsLabel = 'Service rating',
  }) : assert(rating >= 0 && rating <= 5);

  String get ratingLabel {
    switch (rating) {
      case 1:
        return 'Very poor';
      case 2:
        return 'Could be better';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveReadOnly = readOnly || onRatingChanged == null;

    return Semantics(
      label: semanticsLabel,
      value: rating == 0 ? 'Not rated' : '$rating out of 5 stars',
      readOnly: effectiveReadOnly,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: alignment,
            children: List<Widget>.generate(5, (index) {
              final starValue = index + 1;
              final selected = starValue <= rating;

              return Padding(
                padding: EdgeInsets.only(right: index == 4 ? 0 : spacing),
                child: _RatingStar(
                  value: starValue,
                  selected: selected,
                  size: starSize,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  readOnly: effectiveReadOnly,
                  onPressed: effectiveReadOnly
                      ? null
                      : () => onRatingChanged?.call(starValue),
                ),
              );
            }),
          ),
          if (showRatingLabel) ...<Widget>[
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                ratingLabel,
                key: ValueKey<int>(rating),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: rating == 0
                      ? const Color(0xFF777C85)
                      : const Color(0xFF202124),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CompactStarRating extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double starSize;
  final Color starColor;
  final Color textColor;
  final bool showReviewCount;

  const CompactStarRating({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.starSize = 18,
    this.starColor = const Color(0xFFFFC107),
    this.textColor = const Color(0xFF44474D),
    this.showReviewCount = true,
  }) : assert(rating >= 0 && rating <= 5);

  @override
  Widget build(BuildContext context) {
    final roundedRating = rating.toStringAsFixed(1);

    return Semantics(
      label: '$roundedRating out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.star_rounded, size: starSize, color: starColor),
          const SizedBox(width: 4),
          Text(
            roundedRating,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showReviewCount) ...<Widget>[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF777C85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RatingBreakdownBar extends StatelessWidget {
  final int star;
  final int count;
  final int total;
  final Color activeColor;
  final Color backgroundColor;

  const RatingBreakdownBar({
    super.key,
    required this.star,
    required this.count,
    required this.total,
    this.activeColor = const Color(0xFFFFC107),
    this.backgroundColor = const Color(0xFFE9EAED),
  }) : assert(star >= 1 && star <= 5),
       assert(count >= 0),
       assert(total >= 0);

  double get percentage {
    if (total <= 0) {
      return 0;
    }

    return (count / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$star star, $count reviews',
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 18,
            child: Text(
              '$star',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF555960),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.star_rounded, size: 15, color: activeColor),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF777C85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingStar extends StatelessWidget {
  final int value;
  final bool selected;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool readOnly;
  final VoidCallback? onPressed;

  const _RatingStar({
    required this.value,
    required this.selected,
    required this.size,
    required this.activeColor,
    required this.inactiveColor,
    required this.readOnly,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AnimatedScale(
      scale: selected ? 1.08 : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Icon(
          selected ? Icons.star_rounded : Icons.star_outline_rounded,
          key: ValueKey<bool>(selected),
          size: size,
          color: selected ? activeColor : inactiveColor,
        ),
      ),
    );

    if (readOnly) {
      return icon;
    }

    return Semantics(
      button: true,
      selected: selected,
      label: 'Rate $value out of 5 stars',
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onPressed,
          radius: size * 0.7,
          splashColor: activeColor.withAlpha(40),
          highlightColor: activeColor.withAlpha(20),
          child: Padding(padding: const EdgeInsets.all(2), child: icon),
        ),
      ),
    );
  }
}
