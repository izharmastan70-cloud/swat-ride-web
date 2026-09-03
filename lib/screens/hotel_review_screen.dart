import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hotel_review.dart';
import '../services/hotel_review_service.dart';

class HotelReviewScreen extends StatefulWidget {
  const HotelReviewScreen({
    super.key,
    required this.hotelId,
    required this.bookingId,
    required this.hotelName,
    required this.customerName,
  });

  final String hotelId;
  final String bookingId;
  final String hotelName;
  final String customerName;

  @override
  State<HotelReviewScreen> createState() =>
      _HotelReviewScreenState();
}

class _HotelReviewScreenState extends State<HotelReviewScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final HotelReviewService _reviewService =
      HotelReviewService();

  final TextEditingController _reviewController =
      TextEditingController();

  HotelReview? _existingReview;
  double _selectedRating = 5;
  bool _isLoading = true;
  bool _isSaving = false;

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _currentUser;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Hotel Review',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? _messageState(
              icon: Icons.lock_outline,
              title: 'Login Required',
              message:
                  'Please log in to write or view your hotel review.',
            )
          : SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: yellow,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        30,
                      ),
                      children: [
                        _hotelCard(),
                        const SizedBox(height: 16),
                        _ratingCard(),
                        const SizedBox(height: 16),
                        _reviewTextCard(),
                        if (_existingReview?.hasOwnerReply ==
                            true) ...[
                          const SizedBox(height: 16),
                          _ownerReplyCard(),
                        ],
                        const SizedBox(height: 18),
                        _saveButton(),
                        const SizedBox(height: 14),
                        _noticeCard(),
                      ],
                    ),
            ),
    );
  }

  Widget _hotelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: yellow.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.hotel_outlined,
              color: yellow,
              size: 29,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotelName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Booking ${_shortId(widget.bookingId)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                if (_existingReview != null) ...[
                  const SizedBox(height: 6),
                  _statusBadge(
                    _existingReview!.reviewStatus,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate Your Stay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap a star to select your rating.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) {
                final int starValue = index + 1;
                final bool selected =
                    starValue <= _selectedRating;

                return IconButton(
                  tooltip: '$starValue star',
                  onPressed: _isSaving
                      ? null
                      : () {
                          setState(() {
                            _selectedRating =
                                starValue.toDouble();
                          });
                        },
                  icon: Icon(
                    selected
                        ? Icons.star
                        : Icons.star_border,
                    color: selected
                        ? yellow
                        : Colors.grey,
                    size: 36,
                  ),
                );
              },
            ),
          ),
          Center(
            child: Text(
              '${_selectedRating.toStringAsFixed(0)} / 5',
              style: const TextStyle(
                color: yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewTextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _existingReview == null
                ? 'Write Your Review'
                : 'Update Your Review',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            maxLines: 6,
            maxLength: 1000,
            enabled: !_isSaving,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText:
                  'Share details about cleanliness, staff, room, location and overall experience.',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
              filled: true,
              fillColor: darkBackground,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerReplyCard() {
    final HotelReview review = _existingReview!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.reply_outlined,
                color: yellow,
              ),
              SizedBox(width: 8),
              Text(
                'Hotel Owner Reply',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.ownerReply,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    final bool isEditing =
        _existingReview != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving
            ? null
            : _saveReview,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Icon(
                isEditing
                    ? Icons.save_outlined
                    : Icons.rate_review_outlined,
              ),
        label: Text(
          _isSaving
              ? 'Saving...'
              : isEditing
                  ? 'Update Review'
                  : 'Submit Review',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _noticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
            size: 21,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Only guests with a completed or checked-out booking can submit a verified review. Review photo uploads remain disabled until Firebase Storage billing is enabled.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final Color color;

    switch (status) {
      case 'published':
        color = Colors.green;
        break;
      case 'hidden':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.13,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              color: yellow,
              size: 50,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadExistingReview() async {
    final User? user = _currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final HotelReview? review =
          await _reviewService.getReviewForBooking(
        bookingId: widget.bookingId,
        userId: user.uid,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _existingReview = review;

        if (review != null) {
          _selectedRating = review.rating;
          _reviewController.text =
              review.reviewText;
        }

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load review: $error',
        isError: true,
      );
    }
  }

  Future<void> _saveReview() async {
    final User? user = _currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    final String reviewText =
        _reviewController.text.trim();

    if (_selectedRating < 1 ||
        _selectedRating > 5) {
      _showMessage(
        'Please select a rating from 1 to 5.',
        isError: true,
      );
      return;
    }

    if (reviewText.length < 5) {
      _showMessage(
        'Please write at least 5 characters.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_existingReview == null) {
        final HotelReview review =
            HotelReview(
          id: '',
          hotelId: widget.hotelId,
          bookingId: widget.bookingId,
          userId: user.uid,
          customerName:
              widget.customerName.trim().isEmpty
                  ? user.displayName ?? 'Guest'
                  : widget.customerName.trim(),
          rating: _selectedRating,
          reviewText: reviewText,
          ownerReply: '',
          reviewStatus: 'pending',
          isVerifiedStay: false,
          isHiddenByAdmin: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          reviewPhotoLocalPaths:
              const <String>[],
          storageUploadUsed: false,
        );

        await _reviewService.submitReview(
          review: review,
        );

        _showMessage(
          'Hotel review submitted.',
        );
      } else {
        await _reviewService
            .updateCustomerReview(
          reviewId: _existingReview!.id,
          userId: user.uid,
          rating: _selectedRating,
          reviewText: reviewText,
        );

        _showMessage(
          'Hotel review updated.',
        );
      }

      await _loadExistingReview();
    } catch (error) {
      _showMessage(
        'Unable to save review: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _shortId(String value) {
    if (value.length <= 10) {
      return value;
    }

    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }

  String _statusLabel(String status) {
    return status
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : darkCard,
        ),
      );
  }
}
