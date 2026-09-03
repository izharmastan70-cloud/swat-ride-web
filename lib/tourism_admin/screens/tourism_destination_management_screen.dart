import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TourismDestinationManagementScreen
    extends StatefulWidget {
  const TourismDestinationManagementScreen({
    super.key,
  });

  @override
  State<TourismDestinationManagementScreen>
      createState() =>
          _TourismDestinationManagementScreenState();
}

class _TourismDestinationManagementScreenState
    extends State<TourismDestinationManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedCategory = 'all';
  String _searchText = '';
  bool _showArchived = false;
  String _workingDestinationId = '';

  CollectionReference<Map<String, dynamic>>
      get _destinationsCollection =>
          _firestore.collection(
            'tour_destinations',
          );

  CollectionReference<Map<String, dynamic>>
      get _auditCollection =>
          _firestore.collection(
            'tour_destination_audit_logs',
          );

  final List<String> _categories = const <String>[
    'all',
    'valley',
    'mountain',
    'lake',
    'waterfall',
    'forest',
    'family',
    'adventure',
    'historical',
    'park',
    'other',
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
          'Destination Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add destination',
            onPressed: _workingDestinationId.isNotEmpty
                ? null
                : _openCreateDestinationSheet,
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
          stream: _destinationsCollection.snapshots(),
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
                    'Unable to Load Destinations',
                message:
                    snapshot.error.toString(),
              );
            }

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                allDocuments =
                snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                visibleDocuments =
                allDocuments.where(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    document,
              ) {
                final Map<String, dynamic>
                    data = document.data();

                final bool archived =
                    data['isArchived'] == true;

                if (_showArchived != archived) {
                  return false;
                }

                final String category =
                    data['category']
                            ?.toString()
                            .toLowerCase() ??
                        'other';

                if (_selectedCategory !=
                        'all' &&
                    category !=
                        _selectedCategory) {
                  return false;
                }

                final String query =
                    _searchText
                        .trim()
                        .toLowerCase();

                if (query.isEmpty) {
                  return true;
                }

                final List<String> values =
                    <String>[
                  data['name']
                          ?.toString() ??
                      '',
                  data['shortDescription']
                          ?.toString() ??
                      '',
                  data['description']
                          ?.toString() ??
                      '',
                  category,
                  ..._readStringList(
                    data['activities'],
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

                return (a.data()['name']
                            ?.toString() ??
                        '')
                    .compareTo(
                  b.data()['name']
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
                _categoryFilters(),
                _archiveSwitch(),
                Expanded(
                  child:
                      visibleDocuments.isEmpty
                          ? _messageState(
                              icon:
                                  Icons.location_off_outlined,
                              title:
                                  'No Destinations Found',
                              message:
                                  'No destination matches the selected filters.',
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
                                return _destinationCard(
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
            _workingDestinationId.isNotEmpty
                ? null
                : _openCreateDestinationSheet,
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Destination',
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
      final Map<String, dynamic> data =
          document.data();

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
              'Search destination, activity or tag...',
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

  Widget _categoryFilters() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (
          context,
          index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          context,
          index,
        ) {
          final String category =
              _categories[index];

          final bool selected =
              _selectedCategory ==
                  category;

          return ChoiceChip(
            selected: selected,
            label: Text(
              _capitalize(category),
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
                _selectedCategory =
                    category;
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
              'Show archived destinations',
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

  Widget _destinationCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String name =
        data['name']?.toString() ??
            'Destination';

    final String category =
        data['category']?.toString() ??
            'other';

    final String shortDescription =
        data['shortDescription']
                ?.toString() ??
            data['description']
                ?.toString() ??
            '';

    final String bestSeason =
        data['bestSeason']?.toString() ??
            '';

    final String distance =
        data['distanceFromMingora']
                ?.toString() ??
            '';

    final bool isActive =
        data['isActive'] != false;

    final bool isFeatured =
        data['isFeatured'] == true;

    final bool isArchived =
        data['isArchived'] == true;

    final int sortOrder =
        _readInt(
      data['sortOrder'],
      fallback: 9999,
    );

    final double rating =
        _readDouble(
      data['averageRating'],
    );

    final int reviewCount =
        _readInt(
      data['reviewCount'],
    );

    final bool working =
        _workingDestinationId ==
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
                child: Icon(
                  _categoryIcon(category),
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
                      name,
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
                      _capitalize(category),
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
                'Order $sortOrder',
                Colors.blueGrey,
              ),
              if (bestSeason.isNotEmpty)
                _smallBadge(
                  bestSeason,
                  Colors.teal,
                ),
              if (distance.isNotEmpty)
                _smallBadge(
                  distance,
                  Colors.indigo,
                ),
              if (rating > 0)
                _smallBadge(
                  '${rating.toStringAsFixed(1)} ($reviewCount)',
                  Colors.orange,
                ),
            ],
          ),
          const SizedBox(height: 11),
          _detailRow(
            'Activities',
            _readStringList(
              data['activities'],
            ).isEmpty
                ? 'Not added'
                : _readStringList(
                    data['activities'],
                  ).join(', '),
          ),
          _detailRow(
            'Travel Time',
            data['estimatedTravelTime']
                    ?.toString() ??
                'Not added',
          ),
          _detailRow(
            'Entry Fee',
            _readDouble(
                      data['entryFee'],
                    ) >
                    0
                ? 'PKR ${_money(_readDouble(data['entryFee']))}'
                : 'Free / Not set',
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
                          _openEditDestinationSheet(
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

  Future<void> _openCreateDestinationSheet() async {
    final _DestinationFormResult? result =
        await _showDestinationForm();

    if (result == null) {
      return;
    }

    await _createDestination(result);
  }

  Future<void> _openEditDestinationSheet(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final _DestinationFormResult? result =
        await _showDestinationForm(
      existing: document.data(),
    );

    if (result == null) {
      return;
    }

    await _updateDestination(
      document: document,
      result: result,
    );
  }

  Future<_DestinationFormResult?>
      _showDestinationForm({
    Map<String, dynamic>? existing,
  }) async {
    final TextEditingController nameController =
        TextEditingController(
      text:
          existing?['name']?.toString() ??
              '',
    );

    final TextEditingController shortController =
        TextEditingController(
      text: existing?['shortDescription']
              ?.toString() ??
          '',
    );

    final TextEditingController descriptionController =
        TextEditingController(
      text:
          existing?['description']
                  ?.toString() ??
              '',
    );

    final TextEditingController routeController =
        TextEditingController(
      text:
          existing?['route']?.toString() ??
              '',
    );

    final TextEditingController distanceController =
        TextEditingController(
      text: existing?['distanceFromMingora']
              ?.toString() ??
          '',
    );

    final TextEditingController travelTimeController =
        TextEditingController(
      text: existing?['estimatedTravelTime']
              ?.toString() ??
          '',
    );

    final TextEditingController latitudeController =
        TextEditingController(
      text: existing?['latitude']
              ?.toString() ??
          '',
    );

    final TextEditingController longitudeController =
        TextEditingController(
      text: existing?['longitude']
              ?.toString() ??
          '',
    );

    final TextEditingController bestSeasonController =
        TextEditingController(
      text: existing?['bestSeason']
              ?.toString() ??
          '',
    );

    final TextEditingController openingController =
        TextEditingController(
      text: existing?['openingTime']
              ?.toString() ??
          '',
    );

    final TextEditingController closingController =
        TextEditingController(
      text: existing?['closingTime']
              ?.toString() ??
          '',
    );

    final TextEditingController entryFeeController =
        TextEditingController(
      text: _readDouble(
        existing?['entryFee'],
      ).toStringAsFixed(0),
    );

    final TextEditingController coverImageController =
        TextEditingController(
      text: existing?['localCoverImagePath']
              ?.toString() ??
          existing?['coverImageUrl']
              ?.toString() ??
          '',
    );

    final TextEditingController galleryController =
        TextEditingController(
      text: _readStringList(
        existing?['localGalleryPaths'],
      ).join(', '),
    );

    final TextEditingController activitiesController =
        TextEditingController(
      text: _readStringList(
        existing?['activities'],
      ).join(', '),
    );

    final TextEditingController tagsController =
        TextEditingController(
      text: _readStringList(
        existing?['tags'],
      ).join(', '),
    );

    final TextEditingController keywordsController =
        TextEditingController(
      text: _readStringList(
        existing?['keywords'],
      ).join(', '),
    );

    final TextEditingController sortOrderController =
        TextEditingController(
      text: _readInt(
        existing?['sortOrder'],
        fallback: 100,
      ).toString(),
    );

    final TextEditingController popularityController =
        TextEditingController(
      text: _readDouble(
        existing?['popularityScore'],
      ).toStringAsFixed(0),
    );

    final TextEditingController aiScoreController =
        TextEditingController(
      text: _readDouble(
        existing?['aiRecommendationScore'],
      ).toStringAsFixed(0),
    );

    String category =
        existing?['category']?.toString() ??
            'valley';

    String adventureLevel =
        existing?['adventureLevel']
                ?.toString() ??
            'easy';

    bool isActive =
        existing?['isActive'] != false;

    bool isFeatured =
        existing?['isFeatured'] == true;

    bool familyFriendly =
        existing?['familyFriendly'] !=
            false;

    bool kidsFriendly =
        existing?['kidsFriendly'] !=
            false;

    bool wheelchairAccess =
        existing?['wheelchairAccess'] ==
            true;

    bool parkingAvailable =
        existing?['parkingAvailable'] !=
            false;

    final _DestinationFormResult? result =
        await showModalBottomSheet<
            _DestinationFormResult>(
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
                          ? 'Add Destination'
                          : 'Edit Destination',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      controller:
                          nameController,
                      label:
                          'Destination Name',
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<
                        String>(
                      initialValue: category,
                      dropdownColor: darkCard,
                      decoration:
                          const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: _categories
                          .where(
                            (String item) =>
                                item != 'all',
                          )
                          .map(
                            (String item) =>
                                DropdownMenuItem<
                                    String>(
                              value: item,
                              child: Text(
                                _capitalize(
                                  item,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            category = value;
                          });
                        }
                      },
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
                          routeController,
                      label: 'Route',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          distanceController,
                      label:
                          'Distance from Mingora',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          travelTimeController,
                      label:
                          'Estimated Travel Time',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                latitudeController,
                            label: 'Latitude',
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                longitudeController,
                            label: 'Longitude',
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          bestSeasonController,
                      label: 'Best Season',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                openingController,
                            label:
                                'Opening Time',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                closingController,
                            label:
                                'Closing Time',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          entryFeeController,
                      label:
                          'Entry Fee (PKR)',
                      keyboardType:
                          TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<
                        String>(
                      initialValue:
                          adventureLevel,
                      dropdownColor: darkCard,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Adventure Level',
                      ),
                      items:
                          const <String>[
                        'easy',
                        'moderate',
                        'hard',
                        'extreme',
                      ]
                              .map(
                                (String item) =>
                                    DropdownMenuItem<
                                        String>(
                                  value: item,
                                  child: Text(
                                    _capitalize(
                                      item,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            adventureLevel =
                                value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          activitiesController,
                      label:
                          'Activities (comma separated)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
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
                    _field(
                      controller:
                          coverImageController,
                      label:
                          'Local Cover Image Path',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller:
                          galleryController,
                      label:
                          'Local Gallery Paths (comma separated)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                sortOrderController,
                            label:
                                'Sort Order',
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
                          aiScoreController,
                      label:
                          'AI Recommendation Score',
                      keyboardType:
                          TextInputType.number,
                    ),
                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      value: isActive,
                      activeThumbColor: yellow,
                      onChanged: (value) {
                        setSheetState(() {
                          isActive = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      value: isFeatured,
                      activeThumbColor: yellow,
                      onChanged: (value) {
                        setSheetState(() {
                          isFeatured = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Family Friendly',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      value: familyFriendly,
                      activeThumbColor: yellow,
                      onChanged: (value) {
                        setSheetState(() {
                          familyFriendly =
                              value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Kids Friendly',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      value: kidsFriendly,
                      activeThumbColor: yellow,
                      onChanged: (value) {
                        setSheetState(() {
                          kidsFriendly =
                              value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Wheelchair Access',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      value: wheelchairAccess,
                      activeThumbColor: yellow,
                      onChanged: (value) {
                        setSheetState(() {
                          wheelchairAccess =
                              value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding:
                          EdgeInsets.zero,
                      title: const Text(
                        'Parking Available',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      value: parkingAvailable,
                      activeThumbColor: yellow,
                      onChanged: (value) {
                        setSheetState(() {
                          parkingAvailable =
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
                          if (nameController
                              .text
                              .trim()
                              .isEmpty) {
                            return;
                          }

                          Navigator.pop(
                            sheetContext,
                            _DestinationFormResult(
                              name:
                                  nameController
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
                              category:
                                  category,
                              route:
                                  routeController
                                      .text
                                      .trim(),
                              distanceFromMingora:
                                  distanceController
                                      .text
                                      .trim(),
                              estimatedTravelTime:
                                  travelTimeController
                                      .text
                                      .trim(),
                              latitude:
                                  double.tryParse(
                                        latitudeController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              longitude:
                                  double.tryParse(
                                        longitudeController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              bestSeason:
                                  bestSeasonController
                                      .text
                                      .trim(),
                              openingTime:
                                  openingController
                                      .text
                                      .trim(),
                              closingTime:
                                  closingController
                                      .text
                                      .trim(),
                              entryFee:
                                  double.tryParse(
                                        entryFeeController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              adventureLevel:
                                  adventureLevel,
                              activities:
                                  _splitValues(
                                activitiesController
                                    .text,
                              ),
                              tags: _splitValues(
                                tagsController.text,
                              ),
                              keywords:
                                  _splitValues(
                                keywordsController
                                    .text,
                              ),
                              localCoverImagePath:
                                  coverImageController
                                      .text
                                      .trim(),
                              localGalleryPaths:
                                  _splitValues(
                                galleryController
                                    .text,
                              ),
                              sortOrder:
                                  int.tryParse(
                                        sortOrderController
                                            .text
                                            .trim(),
                                      ) ??
                                      100,
                              popularityScore:
                                  double.tryParse(
                                        popularityController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              aiRecommendationScore:
                                  double.tryParse(
                                        aiScoreController
                                            .text
                                            .trim(),
                                      ) ??
                                      0,
                              isActive:
                                  isActive,
                              isFeatured:
                                  isFeatured,
                              familyFriendly:
                                  familyFriendly,
                              kidsFriendly:
                                  kidsFriendly,
                              wheelchairAccess:
                                  wheelchairAccess,
                              parkingAvailable:
                                  parkingAvailable,
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
                              ? 'Create Destination'
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

    nameController.dispose();
    shortController.dispose();
    descriptionController.dispose();
    routeController.dispose();
    distanceController.dispose();
    travelTimeController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    bestSeasonController.dispose();
    openingController.dispose();
    closingController.dispose();
    entryFeeController.dispose();
    coverImageController.dispose();
    galleryController.dispose();
    activitiesController.dispose();
    tagsController.dispose();
    keywordsController.dispose();
    sortOrderController.dispose();
    popularityController.dispose();
    aiScoreController.dispose();

    return result;
  }

  Future<void> _createDestination(
    _DestinationFormResult result,
  ) async {
    final DocumentReference<
            Map<String, dynamic>>
        reference =
        _destinationsCollection.doc();

    await _setWorking(
      reference.id,
      () async {
        await reference.set(
          <String, dynamic>{
            'destinationId':
                reference.id,
            ...result.toMap(),
            'isArchived': false,
            'coverImageUrl': '',
            'galleryImageUrls':
                const <String>[],
            'storageUploadUsed': false,
            'averageRating': 0,
            'reviewCount': 0,
            'createdAt':
                FieldValue
                    .serverTimestamp(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
        );

        await _saveAudit(
          destinationId:
              reference.id,
          action:
              'destination_created',
          details:
              'Destination created: ${result.name}.',
        );
      },
    );

    _showMessage(
      'Destination created successfully.',
    );
  }

  Future<void> _updateDestination({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    required _DestinationFormResult result,
  }) async {
    await _setWorking(
      document.id,
      () async {
        await document.reference.set(
          <String, dynamic>{
            ...result.toMap(),
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          destinationId:
              document.id,
          action:
              'destination_updated',
          details:
              'Destination updated: ${result.name}.',
        );
      },
    );

    _showMessage(
      'Destination updated successfully.',
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
        await _deleteDestination(
          document,
        );
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
          ? 'destination_enabled'
          : 'destination_disabled',
      details: newValue
          ? 'Destination enabled.'
          : 'Destination disabled.',
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
          ? 'destination_featured'
          : 'destination_unfeatured',
      details: newValue
          ? 'Destination marked featured.'
          : 'Destination removed from featured.',
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
              FieldValue
                  .serverTimestamp(),
        if (!archived)
          'restoredAt':
              FieldValue
                  .serverTimestamp(),
      },
      action: archived
          ? 'destination_archived'
          : 'destination_restored',
      details: archived
          ? 'Destination archived.'
          : 'Destination restored.',
    );
  }

  Future<void> _deleteDestination(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    if (document.data()['isArchived'] !=
        true) {
      _showMessage(
        'Archive the destination before permanent deletion.',
        isError: true,
      );
      return;
    }

    final bool confirmed =
        await _confirmAction(
      title:
          'Delete Destination',
      message:
          'Permanently delete this archived destination?',
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
          destinationId:
              document.id,
          action:
              'destination_deleted',
          details:
              'Archived destination permanently deleted.',
        );
      },
    );

    _showMessage(
      'Destination deleted.',
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
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          destinationId:
              document.id,
          action: action,
          details: details,
        );
      },
    );

    _showMessage(
      'Destination updated.',
    );
  }

  Future<void> _saveAudit({
    required String destinationId,
    required String action,
    required String details,
  }) async {
    await _auditCollection.add(
      <String, dynamic>{
        'destinationId':
            destinationId,
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
    String destinationId,
    Future<void> Function() action,
  ) async {
    setState(() {
      _workingDestinationId =
          destinationId;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update destination: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingDestinationId = '';
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
                    'destinationId',
                    isEqualTo:
                        document.id,
                  )
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                final List<
                        QueryDocumentSnapshot<
                            Map<String,
                                dynamic>>>
                    logs =
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
                            'Destination Audit History',
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
                                'No destination history yet.',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets
                                      .fromLTRB(
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
                                      const EdgeInsets
                                          .only(
                                    bottom: 9,
                                  ),
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    13,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        darkCard,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
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
                                              FontWeight
                                                  .bold,
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
                                            data[
                                                'createdAt'],
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

  IconData _categoryIcon(
    String category,
  ) {
    switch (category) {
      case 'valley':
        return Icons.landscape;
      case 'mountain':
        return Icons.terrain;
      case 'lake':
        return Icons.water;
      case 'waterfall':
        return Icons.waterfall_chart;
      case 'forest':
        return Icons.forest;
      case 'family':
        return Icons.family_restroom;
      case 'adventure':
        return Icons.hiking;
      case 'historical':
        return Icons.account_balance;
      case 'park':
        return Icons.park;
      default:
        return Icons.location_on_outlined;
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

class _DestinationFormResult {
  const _DestinationFormResult({
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.category,
    required this.route,
    required this.distanceFromMingora,
    required this.estimatedTravelTime,
    required this.latitude,
    required this.longitude,
    required this.bestSeason,
    required this.openingTime,
    required this.closingTime,
    required this.entryFee,
    required this.adventureLevel,
    required this.activities,
    required this.tags,
    required this.keywords,
    required this.localCoverImagePath,
    required this.localGalleryPaths,
    required this.sortOrder,
    required this.popularityScore,
    required this.aiRecommendationScore,
    required this.isActive,
    required this.isFeatured,
    required this.familyFriendly,
    required this.kidsFriendly,
    required this.wheelchairAccess,
    required this.parkingAvailable,
  });

  final String name;
  final String shortDescription;
  final String description;
  final String category;
  final String route;
  final String distanceFromMingora;
  final String estimatedTravelTime;
  final double latitude;
  final double longitude;
  final String bestSeason;
  final String openingTime;
  final String closingTime;
  final double entryFee;
  final String adventureLevel;
  final List<String> activities;
  final List<String> tags;
  final List<String> keywords;
  final String localCoverImagePath;
  final List<String> localGalleryPaths;
  final int sortOrder;
  final double popularityScore;
  final double aiRecommendationScore;
  final bool isActive;
  final bool isFeatured;
  final bool familyFriendly;
  final bool kidsFriendly;
  final bool wheelchairAccess;
  final bool parkingAvailable;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'shortDescription':
          shortDescription,
      'description': description,
      'category': category,
      'route': route,
      'distanceFromMingora':
          distanceFromMingora,
      'estimatedTravelTime':
          estimatedTravelTime,
      'latitude': latitude,
      'longitude': longitude,
      'bestSeason': bestSeason,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'entryFee': entryFee,
      'adventureLevel':
          adventureLevel,
      'activities': activities,
      'tags': tags,
      'keywords': keywords,
      'localCoverImagePath':
          localCoverImagePath,
      'localGalleryPaths':
          localGalleryPaths,
      'sortOrder': sortOrder,
      'popularityScore':
          popularityScore,
      'aiRecommendationScore':
          aiRecommendationScore,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'familyFriendly':
          familyFriendly,
      'kidsFriendly': kidsFriendly,
      'wheelchairAccess':
          wheelchairAccess,
      'parkingAvailable':
          parkingAvailable,
    };
  }
}
