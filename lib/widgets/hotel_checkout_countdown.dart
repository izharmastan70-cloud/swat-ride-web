import 'dart:async';

import 'package:flutter/material.dart';

class HotelCheckoutCountdown extends StatefulWidget {
  const HotelCheckoutCountdown({
    super.key,
    required this.checkOutDateTime,
    this.hotelName = '',
    this.checkOutLabel = 'Check-out time',
    this.onCheckoutReached,
  });

  final DateTime checkOutDateTime;
  final String hotelName;
  final String checkOutLabel;
  final VoidCallback? onCheckoutReached;

  @override
  State<HotelCheckoutCountdown> createState() =>
      _HotelCheckoutCountdownState();
}

class _HotelCheckoutCountdownState
    extends State<HotelCheckoutCountdown>
    with WidgetsBindingObserver {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);

  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _checkoutReached = false;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshRemainingTime();
    _startLocalTimer();
  }

  @override
  void didUpdateWidget(
    covariant HotelCheckoutCountdown oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.checkOutDateTime !=
        widget.checkOutDateTime) {
      _checkoutReached = false;
      _dialogShown = false;
      _refreshRemainingTime();
      _startLocalTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _refreshRemainingTime();
      _startLocalTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool urgent =
        !_checkoutReached &&
        _remaining <= const Duration(hours: 3);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _checkoutReached
              ? Colors.red.withValues(alpha: 0.45)
              : urgent
                  ? Colors.orange.withValues(alpha: 0.45)
                  : yellow.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _checkoutReached
                    ? Icons.logout
                    : Icons.timer_outlined,
                color: _checkoutReached
                    ? Colors.redAccent
                    : urgent
                        ? Colors.orange
                        : yellow,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _checkoutReached
                      ? 'Check-out time reached'
                      : 'Time remaining until check-out',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_checkoutReached)
            const Text(
              'Please complete check-out or contact hotel reception for late check-out assistance.',
              style: TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _timeBox(
                    value: '${_remaining.inDays}',
                    label: 'Days',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _timeBox(
                    value:
                        '${_remaining.inHours.remainder(24)}'
                            .padLeft(2, '0'),
                    label: 'Hours',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _timeBox(
                    value:
                        '${_remaining.inMinutes.remainder(60)}'
                            .padLeft(2, '0'),
                    label: 'Minutes',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _timeBox(
                    value:
                        '${_remaining.inSeconds.remainder(60)}'
                            .padLeft(2, '0'),
                    label: 'Seconds',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                color: Colors.grey,
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${widget.checkOutLabel}: '
                  '${_formatDateTime(widget.checkOutDateTime)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (widget.hotelName.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.hotel_outlined,
                  color: Colors.grey,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    widget.hotelName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: yellow.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Zero-cost timer: checkout time is read once, then the countdown runs locally on this phone. No per-second Firebase reads or writes.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox({
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: yellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _startLocalTimer() {
    _timer?.cancel();

    if (_checkoutReached) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        _refreshRemainingTime();
      },
    );
  }

  void _refreshRemainingTime() {
    final Duration difference =
        widget.checkOutDateTime.difference(
      DateTime.now(),
    );

    if (difference <= Duration.zero) {
      _timer?.cancel();

      if (mounted) {
        setState(() {
          _remaining = Duration.zero;
          _checkoutReached = true;
        });
      } else {
        _remaining = Duration.zero;
        _checkoutReached = true;
      }

      widget.onCheckoutReached?.call();
      _showCheckoutReachedDialogOnce();
      return;
    }

    if (mounted) {
      setState(() {
        _remaining = difference;
      });
    } else {
      _remaining = difference;
    }
  }

  void _showCheckoutReachedDialogOnce() {
    if (_dialogShown || !mounted) {
      return;
    }

    _dialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: darkCard,
              title: const Text(
                'Check-out Time',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'Your hotel check-out time has arrived. Please complete check-out or contact hotel reception for late check-out assistance.',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.45,
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDateTime(
    DateTime value,
  ) {
    final int hour12 =
        value.hour == 0
            ? 12
            : value.hour > 12
                ? value.hour - 12
                : value.hour;

    final String period =
        value.hour >= 12 ? 'PM' : 'AM';

    final String day =
        value.day.toString().padLeft(2, '0');

    final String month =
        value.month.toString().padLeft(2, '0');

    final String minute =
        value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} '
        '$hour12:$minute $period';
  }
}
