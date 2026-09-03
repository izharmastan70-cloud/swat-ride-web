import 'package:flutter/material.dart';

import '../models/feedback_model.dart';
import '../models/feedback_reply_model.dart';
import '../services/feedback_reply_service.dart';
import '../services/feedback_service.dart';

class ReviewReplyScreen extends StatefulWidget {
  final FeedbackModel review;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final FeedbackReplyAuthorType authorType;
  final FeedbackReplyService? replyService;

  const ReviewReplyScreen({
    super.key,
    required this.review,
    required this.authorId,
    required this.authorName,
    required this.authorType,
    this.authorPhotoUrl = '',
    this.replyService,
  });

  @override
  State<ReviewReplyScreen> createState() => _ReviewReplyScreenState();
}

class _ReviewReplyScreenState extends State<ReviewReplyScreen> {
  late final FeedbackReplyService _replyService;
  late final TextEditingController _messageController;

  FeedbackReplyType _replyType = FeedbackReplyType.public;
  bool _submitting = false;

  bool get _canUsePrivateReply => widget.authorType.isAdminOrSupport;

  @override
  void initState() {
    super.initState();
    _replyService = widget.replyService ?? FeedbackReplyService();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_submitting) {
      return;
    }

    final message = _messageController.text.trim();

    if (message.isEmpty) {
      _showMessage('Please write a response first.');
      return;
    }

    if (message.length > FeedbackReplyModel.maximumMessageLength) {
      _showMessage('Reply cannot exceed 1500 characters.');
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final replyId = await _replyService.createReply(
        feedbackId: widget.review.id,
        authorId: widget.authorId,
        authorName: widget.authorName,
        authorPhotoUrl: widget.authorPhotoUrl,
        authorType: widget.authorType,
        replyType: _replyType,
        message: message,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _replyType == FeedbackReplyType.privateSupport
                ? 'Private support response sent.'
                : 'Public response sent.',
          ),
        ),
      );

      Navigator.of(context).pop(replyId);
    } on FeedbackOperationException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Reply could not be submitted.');
      debugPrint('Create feedback reply error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F6),
      appBar: AppBar(
        title: const Text(
          'Reply to review',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: <Widget>[
                    _ReplyReviewCard(review: widget.review),
                    const SizedBox(height: 12),
                    if (_canUsePrivateReply)
                      _ReplyTypeCard(
                        selectedType: _replyType,
                        onChanged: (type) {
                          setState(() {
                            _replyType = type;
                          });
                        },
                      )
                    else
                      const _PublicReplyInformationCard(),
                    const SizedBox(height: 12),
                    _ReplyEditorCard(
                      controller: _messageController,
                      replyType: _replyType,
                    ),
                    const SizedBox(height: 12),
                    _ReplyGuidelinesCard(
                      isPrivate: _replyType == FeedbackReplyType.privateSupport,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(bottom: keyboardHeight > 0 ? 0 : 0),
              child: _SubmitReplyBar(
                submitting: _submitting,
                replyType: _replyType,
                onSubmit: _submitReply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyReviewCard extends StatelessWidget {
  final FeedbackModel review;

  const _ReplyReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewerName = review.publicReviewerName;
    final reference = review.sourceReference.trim().isEmpty
        ? review.sourceId.trim()
        : review.sourceReference.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _replyCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFE8EAED),
                foregroundImage:
                    review.isAnonymous || review.reviewerPhotoUrl.trim().isEmpty
                    ? null
                    : NetworkImage(review.reviewerPhotoUrl.trim()),
                child: Text(
                  reviewerName.trim().isEmpty
                      ? '?'
                      : reviewerName.trim().substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF3C4043),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
                              fontSize: 16,
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
                      '${review.serviceType.displayName} • '
                      '${_formatReplyDate(review.createdAt)}',
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
          const SizedBox(height: 14),
          _ReplyStars(rating: review.rating),
          if (review.comment.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              review.comment.trim(),
              style: const TextStyle(
                color: Color(0xFF3C4043),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          if (review.tags.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: review.tags
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
          if (reference.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 11),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 17,
                  color: Color(0xFF8A8F98),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Reference: $reference',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF777C85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReplyTypeCard extends StatelessWidget {
  final FeedbackReplyType selectedType;
  final ValueChanged<FeedbackReplyType> onChanged;

  const _ReplyTypeCard({required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _replyCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.visibility_outlined,
                size: 21,
                color: Color(0xFF555960),
              ),
              SizedBox(width: 9),
              Text(
                'Response visibility',
                style: TextStyle(
                  color: Color(0xFF202124),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<FeedbackReplyType>(
            segments: const <ButtonSegment<FeedbackReplyType>>[
              ButtonSegment<FeedbackReplyType>(
                value: FeedbackReplyType.public,
                label: Text('Public'),
                icon: Icon(Icons.public_rounded),
              ),
              ButtonSegment<FeedbackReplyType>(
                value: FeedbackReplyType.privateSupport,
                label: Text('Private'),
                icon: Icon(Icons.lock_outline_rounded),
              ),
            ],
            selected: <FeedbackReplyType>{selectedType},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) {
                return;
              }

              onChanged(selection.first);
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }

                return const Color(0xFF555960);
              }),
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF111315);
                }

                return Colors.white;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicReplyInformationCard extends StatelessWidget {
  const _PublicReplyInformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD2E3FC)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.public_rounded, color: Color(0xFF1A73E8), size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Your response will be public and may be visible '
              'with this customer review.',
              style: TextStyle(
                color: Color(0xFF315F94),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyEditorCard extends StatefulWidget {
  final TextEditingController controller;
  final FeedbackReplyType replyType;

  const _ReplyEditorCard({required this.controller, required this.replyType});

  @override
  State<_ReplyEditorCard> createState() => _ReplyEditorCardState();
}

class _ReplyEditorCardState extends State<_ReplyEditorCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _ReplyEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.text.length;
    final overLimit = count > FeedbackReplyModel.maximumMessageLength;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _replyCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.replyType == FeedbackReplyType.privateSupport
                ? 'Private support message'
                : 'Write your public response',
            style: const TextStyle(
              color: Color(0xFF202124),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.replyType == FeedbackReplyType.privateSupport
                ? 'Only the customer and authorized support can see it.'
                : 'The customer and other app users may see it.',
            style: const TextStyle(
              color: Color(0xFF8A8F98),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: widget.controller,
            minLines: 5,
            maxLines: 10,
            maxLength: FeedbackReplyModel.maximumMessageLength + 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Thank the customer and address their feedback...',
              filled: true,
              fillColor: const Color(0xFFF5F6F7),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: overLimit
                      ? const Color(0xFFD93025)
                      : const Color(0xFF111315),
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$count/${FeedbackReplyModel.maximumMessageLength}',
              style: TextStyle(
                color: overLimit
                    ? const Color(0xFFD93025)
                    : const Color(0xFF8A8F98),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyGuidelinesCard extends StatelessWidget {
  final bool isPrivate;

  const _ReplyGuidelinesCard({required this.isPrivate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5DFA7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFF9A6B00),
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Response guidelines',
                style: TextStyle(
                  color: Color(0xFF795500),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          const _GuidelineText(text: 'Be polite, factual and professional.'),
          const _GuidelineText(
            text: 'Do not share phone numbers, addresses or private data.',
          ),
          const _GuidelineText(
            text: 'Do not pressure the customer to change their rating.',
          ),
          _GuidelineText(
            text: isPrivate
                ? 'Use private support only for account-specific help.'
                : 'Remember that this response may be publicly visible.',
          ),
        ],
      ),
    );
  }
}

class _GuidelineText extends StatelessWidget {
  final String text;

  const _GuidelineText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 5, color: Color(0xFF9A6B00)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF795500),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitReplyBar extends StatelessWidget {
  final bool submitting;
  final FeedbackReplyType replyType;
  final VoidCallback onSubmit;

  const _SubmitReplyBar({
    required this.submitting,
    required this.replyType,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EA))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: submitting ? null : onSubmit,
          icon: submitting
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  replyType == FeedbackReplyType.privateSupport
                      ? Icons.lock_outline_rounded
                      : Icons.send_rounded,
                ),
          label: Text(
            submitting
                ? 'Sending...'
                : replyType == FeedbackReplyType.privateSupport
                ? 'Send private response'
                : 'Publish response',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF111315),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF777C85),
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyStars extends StatelessWidget {
  final int rating;

  const _ReplyStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(5, (index) {
        final selected = index < rating;

        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Icon(
            selected ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 23,
            color: selected ? const Color(0xFFFFB300) : const Color(0xFFBDC1C6),
          ),
        );
      }),
    );
  }
}

BoxDecoration _replyCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFE7E9EC)),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}

String _formatReplyDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();

  return '$day/$month/$year';
}
