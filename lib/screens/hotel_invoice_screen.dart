import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HotelInvoiceScreen extends StatefulWidget {
  const HotelInvoiceScreen({
    super.key,
    required this.booking,
  });

  final Map<String, dynamic> booking;

  @override
  State<HotelInvoiceScreen> createState() =>
      _HotelInvoiceScreenState();
}

class _HotelInvoiceScreenState
    extends State<HotelInvoiceScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  bool _isGenerating = false;
  bool _isLoadingSettings = true;

  Map<String, dynamic> _invoiceSettings =
      <String, dynamic>{};

  String get _bookingId =>
      widget.booking['bookingId']?.toString() ??
      widget.booking['id']?.toString() ??
      'Not available';

  String get _hotelName =>
      widget.booking['hotelName']?.toString() ??
      'SWAT RIDE Hotel Partner';

  String get _hotelLocation =>
      widget.booking['hotelLocation']?.toString() ??
      widget.booking['location']?.toString() ??
      'Swat, KPK';

  String get _hotelPhone =>
      widget.booking['hotelPhone']?.toString() ??
      '';

  String get _roomName =>
      widget.booking['roomName']?.toString() ??
      widget.booking['roomType']?.toString() ??
      'Hotel Room';

  String get _roomNumber =>
      widget.booking['roomNumber']?.toString() ??
      '';

  String get _guestName =>
      widget.booking['guestName']?.toString() ??
      'Guest';

  String get _guestPhone =>
      widget.booking['guestPhone']?.toString() ??
      widget.booking['phoneNumber']?.toString() ??
      '';

  String get _guestCnic =>
      widget.booking['guestCnic']?.toString() ??
      widget.booking['cnic']?.toString() ??
      '';

  String get _paymentMethod =>
      widget.booking['paymentMethod']?.toString() ??
      'Not set';

  String get _paymentStatus =>
      widget.booking['paymentStatus']?.toString() ??
      'pending';

  String get _bookingStatus =>
      widget.booking['bookingStatus']?.toString() ??
      'pending';

  DateTime get _checkIn =>
      _readDateTime(widget.booking['checkIn']);

  DateTime get _checkOut =>
      _readDateTime(widget.booking['checkOut']);

  DateTime get _createdAt =>
      _readDateTime(widget.booking['createdAt']);

  int get _nights {
    final int savedNights =
        _readInt(widget.booking['nights']);

    if (savedNights > 0) {
      return savedNights;
    }

    if (_checkIn.millisecondsSinceEpoch == 0 ||
        _checkOut.millisecondsSinceEpoch == 0) {
      return 0;
    }

    final int value =
        _checkOut.difference(_checkIn).inDays;

    return value < 0 ? 0 : value;
  }

  int get _rooms =>
      _readInt(
        widget.booking['rooms'],
        fallback: 1,
      );

  int get _guests =>
      _readInt(
        widget.booking['guests'],
        fallback: 1,
      );

  double get _roomPrice =>
      _readNumber(widget.booking['roomPrice']);

  double get _subtotal {
    final double savedSubtotal =
        _readNumber(widget.booking['subtotal']);

    if (savedSubtotal > 0) {
      return savedSubtotal;
    }

    return _roomPrice * _rooms * _nights;
  }

  double get _discountAmount =>
      _readNumber(widget.booking['discountAmount']);

  double get _taxAmount =>
      _readNumber(widget.booking['taxAmount']);

  double get _serviceCharges =>
      _readNumber(widget.booking['serviceCharges']);

  double get _lateCheckoutCharge =>
      _readNumber(
        widget.booking['lateCheckoutApprovedCharge'] ??
            widget.booking['lateCheckoutEstimatedCharge'],
      );

  double get _cancellationFee =>
      _readNumber(
        widget.booking['finalCancellationFee'] ??
            widget.booking['estimatedCancellationFee'],
      );

  double get _totalAmount {
    final double savedTotal =
        _readNumber(widget.booking['totalAmount']);

    if (savedTotal > 0) {
      return savedTotal;
    }

    return _subtotal -
        _discountAmount +
        _taxAmount +
        _serviceCharges +
        _lateCheckoutCharge +
        _cancellationFee;
  }

  String get _promoCode =>
      widget.booking['promoCode']?.toString() ??
      widget.booking['couponCode']?.toString() ??
      '';

  double get _promoDiscount =>
      _readNumber(
        widget.booking['promoDiscount'] ??
            widget.booking['couponDiscount'],
      );

  double get _rewardDiscount =>
      _readNumber(
        widget.booking['rewardDiscount'] ??
            widget.booking['rewardRedeemedAmount'],
      );

  int get _rewardPointsEarned =>
      _readInt(
        widget.booking['rewardPointsEarned'],
      );

  int get _rewardPointsRedeemed =>
      _readInt(
        widget.booking['rewardPointsRedeemed'],
      );

  double get _cashbackAmount =>
      _readNumber(
        widget.booking['cashbackAmount'],
      );

  double get _paidAmount =>
      _readNumber(
        widget.booking['paidAmount'],
      );

  double get _remainingAmount {
    final double saved =
        _readNumber(
      widget.booking['remainingAmount'],
    );

    if (saved > 0) {
      return saved;
    }

    final double remaining =
        _totalAmount - _paidAmount;

    return remaining > 0 ? remaining : 0;
  }

  double get _refundAmount =>
      _readNumber(
        widget.booking['refundAmount'],
      );

  String get _refundReason =>
      widget.booking['refundReason']
          ?.toString() ??
      '';

  DateTime get _refundDate =>
      _readDateTime(
        widget.booking['refundedAt'] ??
            widget.booking['refundDate'],
      );

  String get _loyaltyLevel =>
      widget.booking['loyaltyLevel']
          ?.toString() ??
      '';

  String get _invoiceStatus {
    final String configured =
        widget.booking['invoiceStatus']
                ?.toString() ??
            '';

    if (configured.isNotEmpty) {
      return configured;
    }

    if (_bookingStatus == 'cancelled') {
      return 'cancelled';
    }

    if (_refundAmount > 0) {
      return 'refunded';
    }

    if (_paymentStatus == 'paid' ||
        _remainingAmount <= 0) {
      return 'paid';
    }

    return 'pending';
  }

  String get _invoiceNumber {
    final String saved =
        widget.booking['invoiceNumber']
                ?.toString() ??
            '';

    if (saved.isNotEmpty) {
      return saved;
    }

    final String prefix =
        _invoiceSettings['invoicePrefix']
                ?.toString() ??
            'SR-HOT';

    final String year =
        DateTime.now().year.toString();

    return '$prefix-$year-${_shortBookingId()}';
  }

  String get _verificationPayload =>
      widget.booking['invoiceQrPayload']
          ?.toString() ??
      widget.booking['qrPayload']
          ?.toString() ??
      'swatride://hotel-invoice/$_bookingId';

  bool get _showPromo =>
      _invoiceSettings['showPromo'] != false;

  bool get _showRewards =>
      _invoiceSettings['showRewards'] != false;

  bool get _showCashback =>
      _invoiceSettings['showCashback'] != false;

  bool get _showQr =>
      _invoiceSettings['qrEnabled'] != false;

  bool get _showAdminStamp =>
      _invoiceSettings['adminStampEnabled'] == true;

  String get _companyName =>
      _invoiceSettings['companyName']
          ?.toString() ??
      'SWAT RIDE';

  String get _companyNtn =>
      _invoiceSettings['ntn']?.toString() ??
      '';

  String get _companyStrn =>
      _invoiceSettings['strn']?.toString() ??
      '';

  String get _supportEmail =>
      _invoiceSettings['supportEmail']
          ?.toString() ??
      '';

  String get _website =>
      _invoiceSettings['website']
          ?.toString() ??
      '';

  bool get _canCreateInvoice {
    const Set<String> supportedStatuses = <String>{
      'confirmed',
      'checked_in',
      'active',
      'in_stay',
      'completed',
      'checked_out',
      'cancelled',
    };

    return supportedStatuses.contains(_bookingStatus);
  }

  @override
  void initState() {
    super.initState();
    _loadInvoiceSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Hotel Invoice',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoadingSettings
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
            28,
          ),
          children: [
            _invoiceHeader(),

            const SizedBox(height: 16),

            _sectionCard(
              title: 'Booking Information',
              icon: Icons.receipt_long_outlined,
              child: Column(
                children: [
                  _detailRow(
                    'Invoice Number',
                    _invoiceNumber,
                  ),
                  _detailRow(
                    'Booking ID',
                    _bookingId,
                  ),
                  _detailRow(
                    'Booking Status',
                    _statusLabel(_bookingStatus),
                  ),
                  _detailRow(
                    'Invoice Status',
                    _statusLabel(_invoiceStatus),
                  ),
                  _detailRow(
                    'Booking Date',
                    _formatDate(_createdAt),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _sectionCard(
              title: 'Stay Details',
              icon: Icons.hotel_outlined,
              child: Column(
                children: [
                  _detailRow(
                    'Hotel',
                    _hotelName,
                  ),
                  _detailRow(
                    'Room',
                    _roomNumber.isEmpty
                        ? _roomName
                        : '$_roomName - $_roomNumber',
                  ),
                  _detailRow(
                    'Check-in',
                    _formatDate(_checkIn),
                  ),
                  _detailRow(
                    'Check-out',
                    _formatDate(_checkOut),
                  ),
                  _detailRow(
                    'Nights',
                    '$_nights',
                  ),
                  _detailRow(
                    'Guests / Rooms',
                    '$_guests guest(s) / $_rooms room(s)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _sectionCard(
              title: 'Invoice Summary',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  _moneyRow(
                    'Room Subtotal',
                    _subtotal,
                  ),
                  if (_discountAmount > 0)
                    _moneyRow(
                      'Discount',
                      -_discountAmount,
                    ),
                  if (_showPromo &&
                      _promoDiscount > 0)
                    _moneyRow(
                      _promoCode.isEmpty
                          ? 'Promo Discount'
                          : 'Promo ($_promoCode)',
                      -_promoDiscount,
                    ),
                  if (_showRewards &&
                      _rewardDiscount > 0)
                    _moneyRow(
                      'Reward Discount',
                      -_rewardDiscount,
                    ),
                  if (_taxAmount > 0)
                    _moneyRow(
                      'Taxes',
                      _taxAmount,
                    ),
                  if (_serviceCharges > 0)
                    _moneyRow(
                      'Service Charges',
                      _serviceCharges,
                    ),
                  if (_lateCheckoutCharge > 0)
                    _moneyRow(
                      'Late Check-out',
                      _lateCheckoutCharge,
                    ),
                  if (_cancellationFee > 0)
                    _moneyRow(
                      'Cancellation Fee',
                      _cancellationFee,
                    ),
                  const Divider(
                    color: Colors.white12,
                    height: 22,
                  ),
                  _moneyRow(
                    'Total Amount',
                    _totalAmount,
                    isTotal: true,
                  ),
                  _detailRow(
                    'Payment Method',
                    _paymentMethod,
                  ),
                  _detailRow(
                    'Payment Status',
                    _statusLabel(_paymentStatus),
                  ),
                  if (_paidAmount > 0)
                    _moneyRow(
                      'Paid Amount',
                      _paidAmount,
                    ),
                  if (_remainingAmount > 0)
                    _moneyRow(
                      'Remaining Amount',
                      _remainingAmount,
                    ),
                  if (_showCashback &&
                      _cashbackAmount > 0)
                    _moneyRow(
                      'Cashback',
                      _cashbackAmount,
                    ),
                  if (_showRewards &&
                      _rewardPointsEarned > 0)
                    _detailRow(
                      'Reward Points Earned',
                      '$_rewardPointsEarned',
                    ),
                  if (_showRewards &&
                      _rewardPointsRedeemed > 0)
                    _detailRow(
                      'Reward Points Redeemed',
                      '$_rewardPointsRedeemed',
                    ),
                  if (_loyaltyLevel.isNotEmpty)
                    _detailRow(
                      'Loyalty Level',
                      _loyaltyLevel,
                    ),
                ],
              ),
            ),

            if (_refundAmount > 0) ...[
              const SizedBox(height: 14),
              _sectionCard(
                title: 'Refund Information',
                icon: Icons.currency_exchange,
                child: Column(
                  children: [
                    _moneyRow(
                      'Refund Amount',
                      _refundAmount,
                    ),
                    if (_refundReason.isNotEmpty)
                      _detailRow(
                        'Refund Reason',
                        _refundReason,
                      ),
                    if (_refundDate
                            .millisecondsSinceEpoch !=
                        0)
                      _detailRow(
                        'Refund Date',
                        _formatDate(_refundDate),
                      ),
                  ],
                ),
              ),
            ],

            if (_showQr) ...[
              const SizedBox(height: 14),
              _verificationCard(),
            ],

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !_canCreateInvoice ||
                        _isGenerating
                    ? null
                    : _openPdfPreview,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(
                        Icons.picture_as_pdf_outlined,
                      ),
                label: Text(
                  _isGenerating
                      ? 'Generating Invoice...'
                      : 'Preview / Print Invoice PDF',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),

            if (!_canCreateInvoice) ...[
              const SizedBox(height: 12),
              const Text(
                'Invoice becomes available after the hotel confirms the booking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                ),
              ),
            ],

            const SizedBox(height: 14),

            _noticeCard(),
          ],
        ),
      ),
    );
  }

  Widget _invoiceHeader() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: yellow.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: yellow,
              size: 31,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _companyName,
                  style: TextStyle(
                    color: yellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _hotelName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Invoice $_invoiceNumber',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdfPreview() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      await Printing.layoutPdf(
        name:
            'SWAT_RIDE_Hotel_Invoice_${_shortBookingId()}.pdf',
        onLayout: (
          PdfPageFormat format,
        ) {
          return _generatePdf(format);
        },
      );
    } catch (error) {
      _showMessage(
        'Unable to generate invoice PDF: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<Uint8List> _generatePdf(
    PdfPageFormat format,
  ) async {
    final pw.Document document =
        pw.Document(
      title:
          'SWAT RIDE Hotel Invoice ${_shortBookingId()}',
      author: 'SWAT RIDE',
      subject: 'Hotel Booking Invoice',
      creator: 'SWAT RIDE App',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        footer: (
          pw.Context context,
        ) {
          return pw.Container(
            alignment:
                pw.Alignment.center,
            margin:
                const pw.EdgeInsets.only(
              top: 16,
            ),
            child: pw.Text(
              'SWAT RIDE - Hotel Invoice - '
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey700,
              ),
            ),
          );
        },
        build: (
          pw.Context context,
        ) {
          return <pw.Widget>[
            _pdfHeader(),

            pw.SizedBox(height: 12),

            if (_companyNtn.isNotEmpty ||
                _companyStrn.isNotEmpty ||
                _supportEmail.isNotEmpty ||
                _website.isNotEmpty)
              _pdfTable(
                <List<String>>[
                  if (_companyNtn.isNotEmpty)
                    <String>['NTN', _companyNtn],
                  if (_companyStrn.isNotEmpty)
                    <String>['STRN', _companyStrn],
                  if (_supportEmail.isNotEmpty)
                    <String>[
                      'Support Email',
                      _supportEmail,
                    ],
                  if (_website.isNotEmpty)
                    <String>[
                      'Website',
                      _website,
                    ],
                ],
              ),

            pw.SizedBox(height: 20),

            _pdfSectionTitle(
              'BOOKING INFORMATION',
            ),

            _pdfTable(
              <List<String>>[
                <String>[
                  'Invoice Number',
                  _invoiceNumber,
                ],
                <String>[
                  'Booking ID',
                  _bookingId,
                ],
                <String>[
                  'Booking Date',
                  _formatDate(_createdAt),
                ],
                <String>[
                  'Booking Status',
                  _statusLabel(_bookingStatus),
                ],
              ],
            ),

            pw.SizedBox(height: 16),

            _pdfSectionTitle(
              'HOTEL & GUEST DETAILS',
            ),

            _pdfTable(
              <List<String>>[
                <String>[
                  'Hotel',
                  _hotelName,
                ],
                <String>[
                  'Location',
                  _hotelLocation,
                ],
                if (_hotelPhone.isNotEmpty)
                  <String>[
                    'Hotel Phone',
                    _hotelPhone,
                  ],
                <String>[
                  'Guest',
                  _guestName,
                ],
                if (_guestPhone.isNotEmpty)
                  <String>[
                    'Guest Phone',
                    _guestPhone,
                  ],
                if (_guestCnic.isNotEmpty)
                  <String>[
                    'Guest CNIC',
                    _guestCnic,
                  ],
              ],
            ),

            pw.SizedBox(height: 16),

            _pdfSectionTitle(
              'STAY DETAILS',
            ),

            _pdfTable(
              <List<String>>[
                <String>[
                  'Room',
                  _roomNumber.isEmpty
                      ? _roomName
                      : '$_roomName - $_roomNumber',
                ],
                <String>[
                  'Check-in',
                  _formatDate(_checkIn),
                ],
                <String>[
                  'Check-out',
                  _formatDate(_checkOut),
                ],
                <String>[
                  'Nights',
                  '$_nights',
                ],
                <String>[
                  'Guests',
                  '$_guests',
                ],
                <String>[
                  'Rooms',
                  '$_rooms',
                ],
              ],
            ),

            pw.SizedBox(height: 18),

            _pdfSectionTitle(
              'PAYMENT SUMMARY',
            ),

            _pdfAmountRow(
              'Room Subtotal',
              _subtotal,
            ),

            if (_discountAmount > 0)
              _pdfAmountRow(
                'Discount',
                -_discountAmount,
              ),

            if (_showPromo &&
                _promoDiscount > 0)
              _pdfAmountRow(
                _promoCode.isEmpty
                    ? 'Promo Discount'
                    : 'Promo ($_promoCode)',
                -_promoDiscount,
              ),

            if (_showRewards &&
                _rewardDiscount > 0)
              _pdfAmountRow(
                'Reward Discount',
                -_rewardDiscount,
              ),

            if (_taxAmount > 0)
              _pdfAmountRow(
                'Taxes',
                _taxAmount,
              ),

            if (_serviceCharges > 0)
              _pdfAmountRow(
                'Service Charges',
                _serviceCharges,
              ),

            if (_lateCheckoutCharge > 0)
              _pdfAmountRow(
                'Late Check-out',
                _lateCheckoutCharge,
              ),

            if (_cancellationFee > 0)
              _pdfAmountRow(
                'Cancellation Fee',
                _cancellationFee,
              ),

            pw.Divider(),

            _pdfAmountRow(
              'TOTAL',
              _totalAmount,
              isTotal: true,
            ),

            pw.SizedBox(height: 10),

            _pdfTable(
              <List<String>>[
                <String>[
                  'Payment Method',
                  _paymentMethod,
                ],
                <String>[
                  'Payment Status',
                  _statusLabel(_paymentStatus),
                ],
                <String>[
                  'Invoice Status',
                  _statusLabel(_invoiceStatus),
                ],
                if (_paidAmount > 0)
                  <String>[
                    'Paid Amount',
                    'PKR ${_formatMoney(_paidAmount)}',
                  ],
                if (_remainingAmount > 0)
                  <String>[
                    'Remaining Amount',
                    'PKR ${_formatMoney(_remainingAmount)}',
                  ],
                if (_showRewards &&
                    _rewardPointsEarned > 0)
                  <String>[
                    'Reward Points Earned',
                    '$_rewardPointsEarned',
                  ],
                if (_showRewards &&
                    _rewardPointsRedeemed > 0)
                  <String>[
                    'Reward Points Redeemed',
                    '$_rewardPointsRedeemed',
                  ],
                if (_loyaltyLevel.isNotEmpty)
                  <String>[
                    'Loyalty Level',
                    _loyaltyLevel,
                  ],
              ],
            ),

            if (_showCashback &&
                _cashbackAmount > 0) ...[
              pw.SizedBox(height: 12),
              _pdfAmountRow(
                'Cashback',
                _cashbackAmount,
              ),
            ],

            if (_refundAmount > 0) ...[
              pw.SizedBox(height: 16),
              _pdfSectionTitle(
                'REFUND INFORMATION',
              ),
              _pdfAmountRow(
                'Refund Amount',
                _refundAmount,
              ),
              _pdfTable(
                <List<String>>[
                  if (_refundReason.isNotEmpty)
                    <String>[
                      'Refund Reason',
                      _refundReason,
                    ],
                  if (_refundDate
                          .millisecondsSinceEpoch !=
                      0)
                    <String>[
                      'Refund Date',
                      _formatDate(_refundDate),
                    ],
                ],
              ),
            ],

            if (_showQr) ...[
              pw.SizedBox(height: 18),
              _pdfSectionTitle(
                'INVOICE VERIFICATION',
              ),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: _verificationPayload,
                  width: 110,
                  height: 110,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Scan to verify booking and invoice',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 22),

            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius:
                    pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'This invoice is generated from the SWAT RIDE hotel booking record. '
                'During testing mode, JazzCash, Easypaisa and wallet payment verification '
                'may remain bypassed. The final paid amount must match the verified payment '
                'or hotel cash settlement record.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                  lineSpacing: 2,
                ),
              ),
            ),

            pw.SizedBox(height: 18),

            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: <pw.Widget>[
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      'Guest Signature',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Container(
                      width: 130,
                      decoration:
                          const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      'Hotel Authorized Signature',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight:
                            pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Container(
                      width: 150,
                      decoration:
                          const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (_showAdminStamp) ...[
              pw.SizedBox(height: 18),
              pw.Center(
                child: pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.green,
                    ),
                    borderRadius:
                        pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'SWAT RIDE ADMIN VERIFIED',
                    style: pw.TextStyle(
                      color: PdfColors.green,
                      fontSize: 10,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ];
        },
      ),
    );

    return document.save();
  }

  pw.Widget _pdfHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.black,
        borderRadius:
            pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Container(
            width: 52,
            height: 52,
            alignment: pw.Alignment.center,
            decoration: const pw.BoxDecoration(
              color: PdfColors.amber,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Text(
              'SR',
              style: pw.TextStyle(
                color: PdfColors.black,
                fontSize: 19,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'SWAT RIDE',
                  style: pw.TextStyle(
                    color: PdfColors.amber,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'HOTEL BOOKING INVOICE',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Text(
                _invoiceNumber,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                _formatDate(DateTime.now()),
                style: const pw.TextStyle(
                  color: PdfColors.grey400,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(
    String title,
  ) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(
        bottom: 7,
      ),
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: const pw.BoxDecoration(
        color: PdfColors.amber,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.black,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _pdfTable(
    List<List<String>> rows,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 0.5,
      ),
      columnWidths: const <int,
          pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(2),
      },
      children: rows.map(
        (List<String> row) {
          return pw.TableRow(
            children: <pw.Widget>[
              pw.Padding(
                padding:
                    const pw.EdgeInsets.all(7),
                child: pw.Text(
                  row[0],
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey700,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(
                padding:
                    const pw.EdgeInsets.all(7),
                child: pw.Text(
                  row[1],
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                  ),
                ),
              ),
            ],
          );
        },
      ).toList(),
    );
  }

  pw.Widget _pdfAmountRow(
    String title,
    double amount, {
    bool isTotal = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: isTotal
          ? const pw.BoxDecoration(
              color: PdfColors.grey200,
            )
          : null,
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: isTotal ? 11 : 9,
                fontWeight: isTotal
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Text(
            '${amount < 0 ? '-' : ''}PKR '
            '${_formatMoney(amount.abs())}',
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 9,
              fontWeight: isTotal
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationCard() {
    return _sectionCard(
      title: 'Invoice Verification',
      icon: Icons.qr_code_2,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: darkBackground,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_2,
                  color: yellow,
                  size: 76,
                ),
                const SizedBox(height: 8),
                Text(
                  _invoiceNumber,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'The printable PDF contains the secure verification QR.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInvoiceSettings() async {
    try {
      final String hotelId =
          widget.booking['hotelId']
                  ?.toString() ??
              '';

      final DocumentSnapshot<
              Map<String, dynamic>>
          globalSnapshot =
          await FirebaseFirestore.instance
              .collection(
                'hotel_invoice_settings',
              )
              .doc('global')
              .get();

      final Map<String, dynamic> merged =
          <String, dynamic>{
        ...?globalSnapshot.data(),
      };

      if (hotelId.isNotEmpty) {
        final DocumentSnapshot<
                Map<String, dynamic>>
            hotelSnapshot =
            await FirebaseFirestore.instance
                .collection(
                  'hotel_invoice_settings',
                )
                .doc(hotelId)
                .get();

        merged.addAll(
          hotelSnapshot.data() ??
              <String, dynamic>{},
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _invoiceSettings = merged;
        _isLoadingSettings = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _invoiceSettings =
            <String, dynamic>{};
        _isLoadingSettings = false;
      });
    }
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: yellow,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(
    String title,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isTotal
                    ? Colors.white
                    : Colors.grey,
                fontSize:
                    isTotal ? 15 : 12,
                fontWeight: isTotal
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}PKR '
            '${_formatMoney(amount.abs())}',
            style: TextStyle(
              color:
                  isTotal ? yellow : Colors.white,
              fontSize:
                  isTotal ? 17 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'The invoice is generated from booking data and admin-controlled invoice settings. PDF generation is local and does not require Firebase Storage. Paid invoices should be voided or versioned rather than permanently deleted.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  double _readNumber(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime _readDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _formatDate(
    DateTime value,
  ) {
    if (value.millisecondsSinceEpoch == 0) {
      return 'Not available';
    }

    final String day =
        value.day.toString().padLeft(
              2,
              '0',
            );

    final String month =
        value.month.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${value.year}';
  }

  String _formatMoney(
    double amount,
  ) {
    final String value =
        amount.toStringAsFixed(0);

    return value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  String _shortBookingId() {
    final String clean =
        _bookingId.replaceAll(
      RegExp(r'[^A-Za-z0-9]'),
      '',
    );

    if (clean.isEmpty) {
      return 'UNKNOWN';
    }

    if (clean.length <= 10) {
      return clean.toUpperCase();
    }

    return clean
        .substring(clean.length - 10)
        .toUpperCase();
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'pending_hotel_confirmation':
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
      case 'active':
      case 'in_stay':
        return 'Active';
      case 'completed':
      case 'checked_out':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'paid':
        return 'Paid';
      case 'cash_pending':
        return 'Cash Pending';
      case 'testing_bypassed':
        return 'Testing Bypass';
      default:
        return status;
    }
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
