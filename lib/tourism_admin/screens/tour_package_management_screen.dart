import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TourPackageManagementScreen extends StatefulWidget {
  const TourPackageManagementScreen({
    super.key,
  });

  @override
  State<TourPackageManagementScreen> createState() =>
      _TourPackageManagementScreenState();
}

class _TourPackageManagementScreenState
    extends State<TourPackageManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedDuration = 'all';
  String _searchText = '';
  bool _showArchived = false;
  String _workingPackageId = '';

  CollectionReference<Map<String, dynamic>>
      get _packagesCollection =>
          _firestore.collection(
            'tour_packages',
          );

  CollectionReference<Map<String, dynamic>>
      get _auditCollection =>
          _firestore.collection(
            'tour_package_audit_logs',
          );

  final List<String> _durationFilters =
      const <String>[
    'all',
    '1',
    '2',
    '3',
    '5',
    'custom',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Tour Package Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add package',
            onPressed: _workingPackageId.isNotEmpty
                ? null
                : _openCreatePackageSheet,
            icon: const Icon(
              Icons.add_circle_outline,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _packagesCollection.snapshots(),
          builder: (
            context,
            AsyncSnapshot<
                    QuerySnapshot<Map<String, dynamic>>>
                snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title:
                    'Unable to Load Packages',
                message:
                    snapshot.error.toString(),
              );
            }

            final allDocuments =
                snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final visibleDocuments =
                allDocuments.where(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    document,
              ) {
                final data = document.data();

                final bool archived =
                    data['isArchived'] == true;

                if (_showArchived != archived) {
                  return false;
                }

                final int duration =
                    _readInt(
                  data['durationDays'],
                  fallback: 1,
                );

                if (_selectedDuration !=
                        'all' &&
                    _selectedDuration !=
                        'custom') {
                  if (duration.toString() !=
                      _selectedDuration) {
                    return false;
                  }
                }

                if (_selectedDuration ==
                        'custom' &&
                    <int>{1, 2, 3, 5}
                        .contains(duration)) {
                  return false;
                }

                final String query =
                    _searchText
                        .trim()
                        .toLowerCase();

                if (query.isEmpty) {
                  return true;
                }

                final values = <String>[
                  data['packageName']
                          ?.toString() ??
                      '',
                  data['packageCode']
                          ?.toString() ??
                      '',
                  data['shortDescription']
                          ?.toString() ??
                      '',
                  ..._readStringList(
                    data['destinations'],
                  ),
                  ..._readStringList(
                    data['tags'],
                  ),
                ];

                return values.any(
                  (String value) =>
                      value
                          .toLowerCase()
                          .contains(query),
                );
              },
            ).toList();

            visibleDocuments.sort(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    a,
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    b,
              ) {
                final int orderCompare =
                    _readInt(
                      a.data()['sortOrder'],
                      fallback: 9999,
                    ).compareTo(
                      _readInt(
                        b.data()['sortOrder'],
                        fallback: 9999,
                      ),
                    );

                if (orderCompare != 0) {
                  return orderCompare;
                }

                return (a.data()['packageName']
                            ?.toString() ??
                        '')
                    .compareTo(
                  b.data()['packageName']
                          ?.toString() ??
                      '',
                );
              },
            );

            return Column(
              children: [
                _summaryHeader(
                  allDocuments,
                ),
                _searchBox(),
                _durationFiltersBar(),
                _archiveSwitch(),
                Expanded(
                  child:
                      visibleDocuments.isEmpty
                          ? _messageState(
                              icon:
                                  Icons.card_travel_outlined,
                              title:
                                  'No Packages Found',
                              message:
                                  'No tour package matches the selected filters.',
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                24,
                              ),
                              itemCount:
                                  visibleDocuments
                                      .length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                return _packageCard(
                                  visibleDocuments[
                                      index],
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _workingPackageId.isNotEmpty
                ? null
                : _openCreatePackageSheet,
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Package',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _summaryHeader(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    int active = 0;
    int inactive = 0;
    int featured = 0;
    int archived = 0;

    for (final document in documents) {
      final data = document.data();

      if (data['isArchived'] == true) {
        archived++;
      } else if (data['isActive'] == false) {
        inactive++;
      } else {
        active++;
      }

      if (data['isFeatured'] == true) {
        featured++;
      }
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        8,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          _summaryItem(
            'Active',
            active,
            Colors.green,
          ),
          _summaryItem(
            'Inactive',
            inactive,
            Colors.orange,
          ),
          _summaryItem(
            'Featured',
            featured,
            yellow,
          ),
          _summaryItem(
            'Archived',
            archived,
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    int value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (String value) {
          setState(() {
            _searchText = value;
          });
        },
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText:
              'Search package, code or destination...',
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: yellow,
          ),
          suffixIcon:
              _searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(() {
                          _searchText = '';
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                    ),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _durationFiltersBar() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount:
            _durationFilters.length,
        separatorBuilder: (
          context,
          index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          context,
          index,
        ) {
          final filter =
              _durationFilters[index];

          final bool selected =
              _selectedDuration ==
                  filter;

          return ChoiceChip(
            selected: selected,
            label: Text(
              _durationLabel(filter),
            ),
            selectedColor:
                yellow.withValues(
              alpha: 0.24,
            ),
            checkmarkColor: yellow,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.grey,
              fontWeight:
                  FontWeight.bold,
            ),
            onSelected: (_) {
              setState(() {
                _selectedDuration =
                    filter;
              });
            },
          );
        },
      ),
    );
  }

  Widget _archiveSwitch() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.archive_outlined,
            color: yellow,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Show archived packages',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          Switch(
            value: _showArchived,
            activeThumbColor: yellow,
            onChanged: (bool value) {
              setState(() {
                _showArchived = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _packageCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final data = document.data();

    final String packageName =
        data['packageName']?.toString() ??
            'Tour Package';

    final String packageCode =
        data['packageCode']?.toString() ??
            '';

    final String shortDescription =
        data['shortDescription']
                ?.toString() ??
            '';

    final int durationDays =
        _readInt(
      data['durationDays'],
      fallback: 1,
    );

    final double adultPrice =
        _readDouble(
      data['adultPrice'],
    );

    final double childPrice =
        _readDouble(
      data['childPrice'],
    );

    final int minPersons =
        _readInt(
      data['minPersons'],
      fallback: 1,
    );

    final int maxPersons =
        _readInt(
      data['maxPersons'],
      fallback: 1,
    );

    final int availableSeats =
        _readInt(
      data['availableSeats'],
      fallback: maxPersons,
    );

    final bool isActive =
        data['isActive'] != false;

    final bool isFeatured =
        data['isFeatured'] == true;

    final bool isArchived =
        data['isArchived'] == true;

    final bool hotelIncluded =
        data['hotelIncluded'] == true;

    final bool guideIncluded =
        data['guideIncluded'] == true;

    final bool vehicleIncluded =
        data['vehicleIncluded'] == true;

    final bool mealsIncluded =
        data['mealsIncluded'] == true;

    final int sortOrder =
        _readInt(
      data['sortOrder'],
      fallback: 9999,
    );

    final bool working =
        _workingPackageId ==
            document.id;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: isActive
              ? Colors.green.withValues(
                  alpha: 0.25,
                )
              : Colors.orange.withValues(
                  alpha: 0.25,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration:
                    BoxDecoration(
                  color:
                      yellow.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons.card_travel_outlined,
                  color: yellow,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      packageName,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      packageCode.isEmpty
                          ? '$durationDays Day Package'
                          : '$packageCode • $durationDays Day${durationDays == 1 ? '' : 's'}',
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                isArchived
                    ? 'archived'
                    : isActive
                        ? 'active'
                        : 'inactive',
              ),
            ],
          ),
          if (shortDescription
              .trim()
              .isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              shortDescription,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isFeatured)
                _smallBadge(
                  'Featured',
                  yellow,
                ),
              _smallBadge(
                '$durationDays Day${durationDays == 1 ? '' : 's'}',
                Colors.blue,
              ),
              _smallBadge(
                'Order $sortOrder',
                Colors.blueGrey,
              ),
              if (hotelIncluded)
                _smallBadge(
                  'Hotel',
                  Colors.purple,
                ),
              if (vehicleIncluded)
                _smallBadge(
                  'Vehicle',
                  Colors.teal,
                ),
              if (guideIncluded)
                _smallBadge(
                  'Guide',
                  Colors.indigo,
                ),
              if (mealsIncluded)
                _smallBadge(
                  'Meals',
                  Colors.orange,
                ),
            ],
          ),
          const SizedBox(height: 11),
          _detailRow(
            'Adult Price',
            adultPrice > 0
                ? 'PKR ${_money(adultPrice)}'
                : 'Not set',
          ),
          _detailRow(
            'Child Price',
            childPrice > 0
                ? 'PKR ${_money(childPrice)}'
                : 'Not set',
          ),
          _detailRow(
            'Capacity',
            '$minPersons - $maxPersons persons',
          ),
          _detailRow(
            'Available Seats',
            '$availableSeats',
          ),
          _detailRow(
            'Destinations',
            _readStringList(
              data['destinations'],
            ).isEmpty
                ? 'Not added'
                : _readStringList(
                    data['destinations'],
                  ).join(', '),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _openEditPackageSheet(
                            document,
                          );
                        },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Edit',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor: yellow,
                    side: const BorderSide(
                      color: yellow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (working)
                const SizedBox(
                  width: 42,
                  height: 42,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: yellow,
                  ),
                )
              else
                PopupMenuButton<String>(
                  color: darkCard,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onSelected: (
                    String action,
                  ) {
                    _handleAction(
                      action: action,
                      document: document,
                    );
                  },
                  itemBuilder: (
                    context,
                  ) =>
                      <PopupMenuEntry<
                          String>>[
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Text(
                        isActive
                            ? 'Disable'
                            : 'Enable',
                      ),
                    ),
                    PopupMenuItem(
                      value:
                          'toggle_featured',
                      child: Text(
                        isFeatured
                            ? 'Remove Featured'
                            : 'Mark Featured',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text(
                        'Duplicate Package',
                      ),
                    ),
                    PopupMenuItem(
                      value: isArchived
                          ? 'restore'
                          : 'archive',
                      child: Text(
                        isArchived
                            ? 'Restore'
                            : 'Archive',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Text(
                        'View audit history',
                      ),
                    ),
                    if (isArchived)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete permanently',
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openCreatePackageSheet() async {
    final _PackageFormResult? result =
        await _showPackageForm();

    if (result == null) {
      return;
    }

    await _createPackage(result);
  }

  Future<void> _openEditPackageSheet(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final _PackageFormResult? result =
        await _showPackageForm(
      existing: document.data(),
    );

    if (result == null) {
      return;
    }

    await _updatePackage(
      document: document,
      result: result,
    );
  }

  Future<_PackageFormResult?>
      _showPackageForm({
    Map<String, dynamic>? existing,
  }) async {
    final TextEditingController
        packageNameController =
        TextEditingController(
      text: existing?['packageName']
              ?.toString() ??
          '',
    );

    final TextEditingController
        packageCodeController =
        TextEditingController(
      text: existing?['packageCode']
              ?.toString() ??
          '',
    );

    final TextEditingController
        shortController =
        TextEditingController(
      text: existing?['shortDescription']
              ?.toString() ??
          '',
    );

    final TextEditingController
        descriptionController =
        TextEditingController(
      text: existing?['description']
              ?.toString() ??
          '',
    );

    final TextEditingController
        durationController =
        TextEditingController(
      text: _readInt(
        existing?['durationDays'],
        fallback: 1,
      ).toString(),
    );

    final TextEditingController
        destinationsController =
        TextEditingController(
      text: _readStringList(
        existing?['destinations'],
      ).join(', '),
    );

    final TextEditingController
        itineraryController =
        TextEditingController(
      text: _readStringList(
        existing?['itinerary'],
      ).join('\n'),
    );

    final TextEditingController
        hotelsController =
        TextEditingController(
      text: _readStringList(
        existing?['includedHotels'],
      ).join(', '),
    );

    final TextEditingController
        roomTypeController =
        TextEditingController(
      text: existing?['roomType']
              ?.toString() ??
          '',
    );

    final TextEditingController
        mealPlanController =
        TextEditingController(
      text: existing?['mealPlan']
              ?.toString() ??
          '',
    );

    final TextEditingController
        vehicleTypeController =
        TextEditingController(
      text: existing?['vehicleType']
              ?.toString() ??
          '',
    );

    final TextEditingController
        guideLanguagesController =
        TextEditingController(
      text: _readStringList(
        existing?['guideLanguages'],
      ).join(', '),
    );

    final TextEditingController
        adultPriceController =
        TextEditingController(
      text: _readDouble(
        existing?['adultPrice'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        childPriceController =
        TextEditingController(
      text: _readDouble(
        existing?['childPrice'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        seasonalPriceController =
        TextEditingController(
      text: _readDouble(
        existing?['seasonalPrice'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        weekendPriceController =
        TextEditingController(
      text: _readDouble(
        existing?['weekendPrice'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        groupDiscountController =
        TextEditingController(
      text: _readDouble(
        existing?['groupDiscountPercent'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        commissionController =
        TextEditingController(
      text: _readDouble(
        existing?['adminCommissionPercent'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        minPersonsController =
        TextEditingController(
      text: _readInt(
        existing?['minPersons'],
        fallback: 1,
      ).toString(),
    );

    final TextEditingController
        maxPersonsController =
        TextEditingController(
      text: _readInt(
        existing?['maxPersons'],
        fallback: 10,
      ).toString(),
    );

    final TextEditingController
        availableSeatsController =
        TextEditingController(
      text: _readInt(
        existing?['availableSeats'],
        fallback: 10,
      ).toString(),
    );

    final TextEditingController
        cancellationController =
        TextEditingController(
      text: existing?['cancellationPolicy']
              ?.toString() ??
          '',
    );

    final TextEditingController
        refundController =
        TextEditingController(
      text: existing?['refundPolicy']
              ?.toString() ??
          '',
    );

    final TextEditingController
        deadlineController =
        TextEditingController(
      text: existing?['bookingDeadline']
              ?.toString() ??
          '',
    );

    final TextEditingController
        advanceController =
        TextEditingController(
      text: _readDouble(
        existing?['minimumAdvancePercent'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        tagsController =
        TextEditingController(
      text: _readStringList(
        existing?['tags'],
      ).join(', '),
    );

    final TextEditingController
        keywordsController =
        TextEditingController(
      text: _readStringList(
        existing?['keywords'],
      ).join(', '),
    );

    final TextEditingController
        aiMatchController =
        TextEditingController(
      text: _readDouble(
        existing?['aiMatchScore'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        popularityController =
        TextEditingController(
      text: _readDouble(
        existing?['popularityScore'],
      ).toStringAsFixed(0),
    );

    final TextEditingController
        sortOrderController =
        TextEditingController(
      text: _readInt(
        existing?['sortOrder'],
        fallback: 100,
      ).toString(),
    );

    final TextEditingController
        coverImageController =
        TextEditingController(
      text: existing?['localCoverImagePath']
              ?.toString() ??
          '',
    );

    bool hotelIncluded =
        existing?['hotelIncluded'] ==
            true;
    bool mealsIncluded =
        existing?['mealsIncluded'] ==
            true;
    bool guideIncluded =
        existing?['guideIncluded'] ==
            true;
    bool privateGuide =
        existing?['privateGuide'] ==
            true;
    bool vehicleIncluded =
        existing?['vehicleIncluded'] !=
            false;
    bool driverIncluded =
        existing?['driverIncluded'] !=
            false;
    bool fuelIncluded =
        existing?['fuelIncluded'] !=
            false;
    bool waitingListEnabled =
        existing?['waitingListEnabled'] ==
            true;
    bool isActive =
        existing?['isActive'] != false;
    bool isFeatured =
        existing?['isFeatured'] ==
            true;
    bool isRecommended =
        existing?['isRecommended'] ==
            true;

    final _PackageFormResult? result =
        await showModalBottomSheet<
            _PackageFormResult>(
      context: context,
      backgroundColor: darkCard,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? 'Add Tour Package'
                          : 'Edit Tour Package',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle(
                      'Basic Information',
                    ),
                    _field(
                      controller:
                          packageNameController,
                      label: 'Package Name',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          packageCodeController,
                      label: 'Package Code',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          shortController,
                      label:
                          'Short Description',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          descriptionController,
                      label:
                          'Full Description',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          durationController,
                      label:
                          'Duration Days',
                      keyboardType:
                          TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      'Route & Itinerary',
                    ),
                    _field(
                      controller:
                          destinationsController,
                      label:
                          'Destinations (comma separated)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          itineraryController,
                      label:
                          'Itinerary (one day per line)',
                      maxLines: 6,
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      'Hotel & Meals',
                    ),
                    _field(
                      controller:
                          hotelsController,
                      label:
                          'Included Hotels (comma separated)',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          roomTypeController,
                      label: 'Room Type',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          mealPlanController,
                      label: 'Meal Plan',
                    ),
                    _switchTile(
                      title:
                          'Hotel Included',
                      value:
                          hotelIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          hotelIncluded =
                              value;
                        });
                      },
                    ),
                    _switchTile(
                      title:
                          'Meals Included',
                      value:
                          mealsIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          mealsIncluded =
                              value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      'Vehicle & Guide',
                    ),
                    _field(
                      controller:
                          vehicleTypeController,
                      label: 'Vehicle Type',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          guideLanguagesController,
                      label:
                          'Guide Languages (comma separated)',
                    ),
                    _switchTile(
                      title:
                          'Vehicle Included',
                      value:
                          vehicleIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          vehicleIncluded =
                              value;
                        });
                      },
                    ),
                    _switchTile(
                      title:
                          'Driver Included',
                      value:
                          driverIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          driverIncluded =
                              value;
                        });
                      },
                    ),
                    _switchTile(
                      title:
                          'Fuel Included',
                      value:
                          fuelIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          fuelIncluded =
                              value;
                        });
                      },
                    ),
                    _switchTile(
                      title:
                          'Guide Included',
                      value:
                          guideIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          guideIncluded =
                              value;
                        });
                      },
                    ),
                    _switchTile(
                      title:
                          'Private Guide',
                      value:
                          privateGuide,
                      onChanged: (value) {
                        setSheetState(() {
                          privateGuide =
                              value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      'Pricing',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                adultPriceController,
                            label:
                                'Adult Price',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                childPriceController,
                            label:
                                'Child Price',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                seasonalPriceController,
                            label:
                                'Seasonal Price',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                weekendPriceController,
                            label:
                                'Weekend Price',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                groupDiscountController,
                            label:
                                'Group Discount %',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                commissionController,
                            label:
                                'Admin Commission %',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      'Capacity',
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                minPersonsController,
                            label:
                                'Min Persons',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                maxPersonsController,
                            label:
                                'Max Persons',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          availableSeatsController,
                      label:
                          'Available Seats',
                      keyboardType:
                          TextInputType.number,
                    ),
                    _switchTile(
                      title:
                          'Waiting List Enabled',
                      value:
                          waitingListEnabled,
                      onChanged: (value) {
                        setSheetState(() {
                          waitingListEnabled =
                              value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      'Booking Rules',
                    ),
                    _field(
                      controller:
                          cancellationController,
                      label:
                          'Cancellation Policy',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          refundController,
                      label:
                          'Refund Policy',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          deadlineController,
                      label:
                          'Booking Deadline',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          advanceController,
                      label:
                          'Minimum Advance %',
                      keyboardType:
                          TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      'AI & Visibility',
                    ),
                    _field(
                      controller:
                          tagsController,
                      label:
                          'Tags (comma separated)',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          keywordsController,
                      label:
                          'Keywords (comma separated)',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                aiMatchController,
                            label:
                                'AI Match Score',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                popularityController,
                            label:
                                'Popularity Score',
                            keyboardType:
                                TextInputType
                                    .number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          sortOrderController,
                      label: 'Sort Order',
                      keyboardType:
                          TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          coverImageController,
                      label:
                          'Local Cover Image Path',
                    ),
                    _switchTile(
                      title: 'Active',
                      value: isActive,
                      onChanged: (value) {
                        setSheetState(() {
                          isActive = value;
                        });
                      },
                    ),
                    _switchTile(
                      title: 'Featured',
                      value: isFeatured,
                      onChanged: (value) {
                        setSheetState(() {
                          isFeatured = value;
                        });
                      },
                    ),
                    _switchTile(
                      title:
                          'Recommended',
                      value:
                          isRecommended,
                      onChanged: (value) {
                        setSheetState(() {
                          isRecommended =
                              value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton(
                        onPressed: () {
                          if (packageNameController
                              .text
                              .trim()
                              .isEmpty) {
                            return;
                          }

                          Navigator.pop(
                            sheetContext,
                            _PackageFormResult(
                              packageName:
                                  packageNameController
                                      .text
                                      .trim(),
                              packageCode:
                                  packageCodeController
                                      .text
                                      .trim(),
                              shortDescription:
                                  shortController
                                      .text
                                      .trim(),
                              description:
                                  descriptionController
                                      .text
                                      .trim(),
                              durationDays:
                                  int.tryParse(
                                        durationController
                                            .text
                                            .trim(),
                                      ) ??
                                      1,
                              destinations:
                                  _splitValues(
                                destinationsController
                                    .text,
                              ),
                              itinerary:
                                  _splitLines(
                                itineraryController
                                    .text,
                              ),
                              includedHotels:
                                  _splitValues(
                                hotelsController
                                    .text,
                              ),
                              roomType:
                                  roomTypeController
                                      .text
                                      .trim(),
                              mealPlan:
                                  mealPlanController
                                      .text
                                      .trim(),
                              hotelIncluded:
                                  hotelIncluded,
                              mealsIncluded:
                                  mealsIncluded,
                              vehicleType:
                                  vehicleTypeController
                                      .text
                                      .trim(),
                              vehicleIncluded:
                                  vehicleIncluded,
                              driverIncluded:
                                  driverIncluded,
                              fuelIncluded:
                                  fuelIncluded,
                              guideIncluded:
                                  guideIncluded,
                              privateGuide:
                                  privateGuide,
                              guideLanguages:
                                  _splitValues(
                                guideLanguagesController
                                    .text,
                              ),
                              adultPrice:
                                  double.tryParse(
                                        adultPriceController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              childPrice:
                                  double.tryParse(
                                        childPriceController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              seasonalPrice:
                                  double.tryParse(
                                        seasonalPriceController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              weekendPrice:
                                  double.tryParse(
                                        weekendPriceController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              groupDiscountPercent:
                                  double.tryParse(
                                        groupDiscountController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              adminCommissionPercent:
                                  double.tryParse(
                                        commissionController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              minPersons:
                                  int.tryParse(
                                        minPersonsController
                                            .text
                                            .trim(),
                                      ) ??
                                      1,
                              maxPersons:
                                  int.tryParse(
                                        maxPersonsController
                                            .text
                                            .trim(),
                                      ) ??
                                      1,
                              availableSeats:
                                  int.tryParse(
                                        availableSeatsController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              waitingListEnabled:
                                  waitingListEnabled,
                              cancellationPolicy:
                                  cancellationController
                                      .text
                                      .trim(),
                              refundPolicy:
                                  refundController
                                      .text
                                      .trim(),
                              bookingDeadline:
                                  deadlineController
                                      .text
                                      .trim(),
                              minimumAdvancePercent:
                                  double.tryParse(
                                        advanceController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              tags: _splitValues(
                                tagsController.text,
                              ),
                              keywords:
                                  _splitValues(
                                keywordsController
                                    .text,
                              ),
                              aiMatchScore:
                                  double.tryParse(
                                        aiMatchController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              popularityScore:
                                  double.tryParse(
                                        popularityController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              sortOrder:
                                  int.tryParse(
                                        sortOrderController
                                            .text
                                            .trim(),
                                      ) ??
                                      100,
                              localCoverImagePath:
                                  coverImageController
                                      .text
                                      .trim(),
                              isActive:
                                  isActive,
                              isFeatured:
                                  isFeatured,
                              isRecommended:
                                  isRecommended,
                            ),
                          );
                        },
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              yellow,
                          foregroundColor:
                              Colors.black,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          existing == null
                              ? 'Create Package'
                              : 'Save Changes',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    for (final controller
        in <TextEditingController>[
      packageNameController,
      packageCodeController,
      shortController,
      descriptionController,
      durationController,
      destinationsController,
      itineraryController,
      hotelsController,
      roomTypeController,
      mealPlanController,
      vehicleTypeController,
      guideLanguagesController,
      adultPriceController,
      childPriceController,
      seasonalPriceController,
      weekendPriceController,
      groupDiscountController,
      commissionController,
      minPersonsController,
      maxPersonsController,
      availableSeatsController,
      cancellationController,
      refundController,
      deadlineController,
      advanceController,
      tagsController,
      keywordsController,
      aiMatchController,
      popularityController,
      sortOrderController,
      coverImageController,
    ]) {
      controller.dispose();
    }

    return result;
  }

  Future<void> _createPackage(
    _PackageFormResult result,
  ) async {
    final reference =
        _packagesCollection.doc();

    await _setWorking(
      reference.id,
      () async {
        await reference.set(
          <String, dynamic>{
            'packageId': reference.id,
            ...result.toMap(),
            'isArchived': false,
            'coverImageUrl': '',
            'storageUploadUsed': false,
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        await _saveAudit(
          packageId: reference.id,
          action: 'package_created',
          details:
              'Tour package created: ${result.packageName}.',
        );
      },
    );

    _showMessage(
      'Tour package created successfully.',
    );
  }

  Future<void> _updatePackage({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    required _PackageFormResult result,
  }) async {
    await _setWorking(
      document.id,
      () async {
        await document.reference.set(
          <String, dynamic>{
            ...result.toMap(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          packageId: document.id,
          action: 'package_updated',
          details:
              'Tour package updated: ${result.packageName}.',
        );
      },
    );

    _showMessage(
      'Tour package updated successfully.',
    );
  }

  Future<void> _handleAction({
    required String action,
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  }) async {
    switch (action) {
      case 'toggle_active':
        await _toggleActive(document);
        break;
      case 'toggle_featured':
        await _toggleFeatured(document);
        break;
      case 'duplicate':
        await _duplicatePackage(document);
        break;
      case 'archive':
        await _setArchived(
          document,
          true,
        );
        break;
      case 'restore':
        await _setArchived(
          document,
          false,
        );
        break;
      case 'history':
        _showHistory(document);
        break;
      case 'delete':
        await _deletePackage(document);
        break;
    }
  }

  Future<void> _toggleActive(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final bool newValue =
        document.data()['isActive'] ==
                false
            ? true
            : false;

    await _updateSimpleField(
      document: document,
      update: <String, dynamic>{
        'isActive': newValue,
      },
      action: newValue
          ? 'package_enabled'
          : 'package_disabled',
      details: newValue
          ? 'Tour package enabled.'
          : 'Tour package disabled.',
    );
  }

  Future<void> _toggleFeatured(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final bool newValue =
        document.data()['isFeatured'] ==
                true
            ? false
            : true;

    await _updateSimpleField(
      document: document,
      update: <String, dynamic>{
        'isFeatured': newValue,
      },
      action: newValue
          ? 'package_featured'
          : 'package_unfeatured',
      details: newValue
          ? 'Tour package marked featured.'
          : 'Tour package removed from featured.',
    );
  }

  Future<void> _duplicatePackage(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final data =
        Map<String, dynamic>.from(
      document.data(),
    );

    final reference =
        _packagesCollection.doc();

    final String oldName =
        data['packageName']?.toString() ??
            'Tour Package';

    data.remove('createdAt');
    data.remove('updatedAt');
    data.remove('archivedAt');
    data.remove('restoredAt');

    await _setWorking(
      document.id,
      () async {
        await reference.set(
          <String, dynamic>{
            ...data,
            'packageId': reference.id,
            'packageName':
                '$oldName Copy',
            'packageCode':
                '${data['packageCode']?.toString() ?? 'PKG'}-COPY',
            'isActive': false,
            'isFeatured': false,
            'isArchived': false,
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        await _saveAudit(
          packageId: reference.id,
          action: 'package_duplicated',
          details:
              'Package duplicated from ${document.id}.',
        );
      },
    );

    _showMessage(
      'Package duplicated as inactive copy.',
    );
  }

  Future<void> _setArchived(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    bool archived,
  ) async {
    await _updateSimpleField(
      document: document,
      update: <String, dynamic>{
        'isArchived': archived,
        if (archived)
          'archivedAt':
              FieldValue.serverTimestamp(),
        if (!archived)
          'restoredAt':
              FieldValue.serverTimestamp(),
      },
      action: archived
          ? 'package_archived'
          : 'package_restored',
      details: archived
          ? 'Tour package archived.'
          : 'Tour package restored.',
    );
  }

  Future<void> _deletePackage(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    if (document.data()['isArchived'] !=
        true) {
      _showMessage(
        'Archive the package before permanent deletion.',
        isError: true,
      );
      return;
    }

    final bool confirmed =
        await _confirmAction(
      title: 'Delete Tour Package',
      message:
          'Permanently delete this archived package?',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    await _setWorking(
      document.id,
      () async {
        await document.reference.delete();

        await _saveAudit(
          packageId: document.id,
          action: 'package_deleted',
          details:
              'Archived tour package permanently deleted.',
        );
      },
    );

    _showMessage(
      'Tour package deleted.',
    );
  }

  Future<void> _updateSimpleField({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    required Map<String, dynamic>
        update,
    required String action,
    required String details,
  }) async {
    await _setWorking(
      document.id,
      () async {
        await document.reference.set(
          <String, dynamic>{
            ...update,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          packageId: document.id,
          action: action,
          details: details,
        );
      },
    );

    _showMessage(
      'Tour package updated.',
    );
  }

  Future<void> _saveAudit({
    required String packageId,
    required String action,
    required String details,
  }) async {
    await _auditCollection.add(
      <String, dynamic>{
        'packageId': packageId,
        'action': action,
        'details': details,
        'performedByRole':
            'tourism_admin',
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _setWorking(
    String packageId,
    Future<void> Function() action,
  ) async {
    setState(() {
      _workingPackageId = packageId;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update package: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingPackageId = '';
        });
      }
    }
  }

  void _showHistory(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          darkBackground,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height:
                MediaQuery.of(context)
                        .size
                        .height *
                    0.72,
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _auditCollection
                  .where(
                    'packageId',
                    isEqualTo:
                        document.id,
                  )
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                final logs =
                    snapshot.data?.docs ??
                        <QueryDocumentSnapshot<
                            Map<String,
                                dynamic>>>[];

                logs.sort(
                  (a, b) =>
                      _readDateTime(
                        b.data()[
                            'createdAt'],
                      ).compareTo(
                        _readDateTime(
                          a.data()[
                              'createdAt'],
                        ),
                      ),
                );

                return Column(
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.all(
                        18,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: yellow,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Package Audit History',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: logs.isEmpty
                          ? const Center(
                              child: Text(
                                'No package history yet.',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                20,
                              ),
                              itemCount:
                                  logs.length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                final data =
                                    logs[index]
                                        .data();

                                return Container(
                                  margin:
                                      const EdgeInsets.only(
                                    bottom: 9,
                                  ),
                                  padding:
                                      const EdgeInsets.all(
                                    13,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        darkCard,
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['action']
                                                ?.toString() ??
                                            'Action',
                                        style:
                                            const TextStyle(
                                          color:
                                              yellow,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        data['details']
                                                ?.toString() ??
                                            '',
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                          fontSize:
                                              11,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        _formatDateTime(
                                          _readDateTime(
                                            data['createdAt'],
                                          ),
                                        ),
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                          fontSize:
                                              9,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: yellow,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(
          color: Colors.grey,
        ),
        filled: true,
        fillColor: darkBackground,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          borderSide:
              BorderSide.none,
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool>
        onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      value: value,
      activeThumbColor: yellow,
      onChanged: onChanged,
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (
            BuildContext dialogContext,
          ) =>
              AlertDialog(
            backgroundColor: darkCard,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child:
                    const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      destructive
                          ? Colors.red
                          : yellow,
                  foregroundColor:
                      destructive
                          ? Colors.white
                          : Colors.black,
                ),
                child: Text(
                  confirmLabel,
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _smallBadge(
    String label,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.12,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final Color color;

    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'inactive':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return _smallBadge(
      _capitalize(status),
      color,
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
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
                fontSize: 10,
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
                fontSize: 10,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
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
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              color: yellow,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _durationLabel(
    String value,
  ) {
    switch (value) {
      case 'all':
        return 'All';
      case 'custom':
        return 'Custom';
      default:
        return '$value Day${value == '1' ? '' : 's'}';
    }
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

  double _readDouble(
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

  List<String> _readStringList(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (dynamic item) =>
                item.toString().trim(),
          )
          .where(
            (String item) =>
                item.isNotEmpty,
          )
          .toList();
    }

    return const <String>[];
  }

  static List<String> _splitValues(
    String value,
  ) {
    return value
        .split(',')
        .map(
          (String item) => item.trim(),
        )
        .where(
          (String item) =>
              item.isNotEmpty,
        )
        .toList();
  }

  static List<String> _splitLines(
    String value,
  ) {
    return value
        .split('\n')
        .map(
          (String item) => item.trim(),
        )
        .where(
          (String item) =>
              item.isNotEmpty,
        )
        .toList();
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

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _formatDateTime(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return '';
    }

    final String day =
        date.day
            .toString()
            .padLeft(2, '0');

    final String month =
        date.month
            .toString()
            .padLeft(2, '0');

    final String hour =
        date.hour
            .toString()
            .padLeft(2, '0');

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }

  String _money(
    num amount,
  ) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (Match match) => ',',
        );
  }

  static String _capitalize(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
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
              isError
                  ? Colors.red
                  : darkCard,
        ),
      );
  }
}

class _PackageFormResult {
  const _PackageFormResult({
    required this.packageName,
    required this.packageCode,
    required this.shortDescription,
    required this.description,
    required this.durationDays,
    required this.destinations,
    required this.itinerary,
    required this.includedHotels,
    required this.roomType,
    required this.mealPlan,
    required this.hotelIncluded,
    required this.mealsIncluded,
    required this.vehicleType,
    required this.vehicleIncluded,
    required this.driverIncluded,
    required this.fuelIncluded,
    required this.guideIncluded,
    required this.privateGuide,
    required this.guideLanguages,
    required this.adultPrice,
    required this.childPrice,
    required this.seasonalPrice,
    required this.weekendPrice,
    required this.groupDiscountPercent,
    required this.adminCommissionPercent,
    required this.minPersons,
    required this.maxPersons,
    required this.availableSeats,
    required this.waitingListEnabled,
    required this.cancellationPolicy,
    required this.refundPolicy,
    required this.bookingDeadline,
    required this.minimumAdvancePercent,
    required this.tags,
    required this.keywords,
    required this.aiMatchScore,
    required this.popularityScore,
    required this.sortOrder,
    required this.localCoverImagePath,
    required this.isActive,
    required this.isFeatured,
    required this.isRecommended,
  });

  final String packageName;
  final String packageCode;
  final String shortDescription;
  final String description;
  final int durationDays;
  final List<String> destinations;
  final List<String> itinerary;
  final List<String> includedHotels;
  final String roomType;
  final String mealPlan;
  final bool hotelIncluded;
  final bool mealsIncluded;
  final String vehicleType;
  final bool vehicleIncluded;
  final bool driverIncluded;
  final bool fuelIncluded;
  final bool guideIncluded;
  final bool privateGuide;
  final List<String> guideLanguages;
  final double adultPrice;
  final double childPrice;
  final double seasonalPrice;
  final double weekendPrice;
  final double groupDiscountPercent;
  final double adminCommissionPercent;
  final int minPersons;
  final int maxPersons;
  final int availableSeats;
  final bool waitingListEnabled;
  final String cancellationPolicy;
  final String refundPolicy;
  final String bookingDeadline;
  final double minimumAdvancePercent;
  final List<String> tags;
  final List<String> keywords;
  final double aiMatchScore;
  final double popularityScore;
  final int sortOrder;
  final String localCoverImagePath;
  final bool isActive;
  final bool isFeatured;
  final bool isRecommended;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'packageName': packageName,
      'packageCode': packageCode,
      'shortDescription':
          shortDescription,
      'description': description,
      'durationDays': durationDays,
      'destinations': destinations,
      'itinerary': itinerary,
      'includedHotels':
          includedHotels,
      'roomType': roomType,
      'mealPlan': mealPlan,
      'hotelIncluded':
          hotelIncluded,
      'mealsIncluded':
          mealsIncluded,
      'vehicleType': vehicleType,
      'vehicleIncluded':
          vehicleIncluded,
      'driverIncluded':
          driverIncluded,
      'fuelIncluded':
          fuelIncluded,
      'guideIncluded':
          guideIncluded,
      'privateGuide': privateGuide,
      'guideLanguages':
          guideLanguages,
      'adultPrice': adultPrice,
      'childPrice': childPrice,
      'seasonalPrice':
          seasonalPrice,
      'weekendPrice':
          weekendPrice,
      'groupDiscountPercent':
          groupDiscountPercent,
      'adminCommissionPercent':
          adminCommissionPercent,
      'minPersons': minPersons,
      'maxPersons': maxPersons,
      'availableSeats':
          availableSeats,
      'waitingListEnabled':
          waitingListEnabled,
      'cancellationPolicy':
          cancellationPolicy,
      'refundPolicy': refundPolicy,
      'bookingDeadline':
          bookingDeadline,
      'minimumAdvancePercent':
          minimumAdvancePercent,
      'tags': tags,
      'keywords': keywords,
      'aiMatchScore': aiMatchScore,
      'popularityScore':
          popularityScore,
      'sortOrder': sortOrder,
      'localCoverImagePath':
          localCoverImagePath,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'isRecommended':
          isRecommended,
    };
  }
}
