import 'package:flutter/material.dart';

import 'group_tour_screen.dart';
import 'my_tour_bookings_screen.dart';

class SwatToursScreen extends StatefulWidget {
  const SwatToursScreen({super.key});

  @override
  State<SwatToursScreen> createState() => _SwatToursScreenState();
}

class _SwatToursScreenState extends State<SwatToursScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _category = 'All';

  static const List<String> _categories = <String>[
    'All',
    'Valleys',
    'Mountains',
    'Lakes',
    'Family',
    'Adventure',
  ];

  static const List<Map<String, dynamic>> _destinations =
      <Map<String, dynamic>>[
    {
      'name': 'Malam Jabba',
      'category': 'Mountains',
      'subtitle': 'Chairlift, snow, skiing and mountain views',
      'icon': Icons.downhill_skiing,
    },
    {
      'name': 'Kalam Valley',
      'category': 'Valleys',
      'subtitle': 'Hotels, rivers, forests and family tours',
      'icon': Icons.landscape,
    },
    {
      'name': 'Mahodand Lake',
      'category': 'Lakes',
      'subtitle': 'Lake, boating, jeep route and camping',
      'icon': Icons.water,
    },
    {
      'name': 'Ushu Forest',
      'category': 'Adventure',
      'subtitle': 'Forest route, photography and 4x4 travel',
      'icon': Icons.forest,
    },
    {
      'name': 'Bahrain',
      'category': 'Family',
      'subtitle': 'River-side stay, bazaar and local food',
      'icon': Icons.family_restroom,
    },
    {
      'name': 'Gabral Valley',
      'category': 'Valleys',
      'subtitle': 'Scenic valley and peaceful group tours',
      'icon': Icons.terrain,
    },
    {
      'name': 'Shahi Bagh',
      'category': 'Adventure',
      'subtitle': 'Remote route, camping and nature',
      'icon': Icons.hiking,
    },
    {
      'name': 'Marghazar',
      'category': 'Family',
      'subtitle': 'White Palace and easy family visit',
      'icon': Icons.account_balance,
    },
    {
      'name': 'Fizagat',
      'category': 'Family',
      'subtitle': 'Park, river view and short local tour',
      'icon': Icons.park,
    },
    {
      'name': 'Kundol Lake',
      'category': 'Lakes',
      'subtitle': 'Trekking, lake views and adventure',
      'icon': Icons.kayaking,
    },
    {
      'name': 'Saidgai Lake',
      'category': 'Lakes',
      'subtitle': 'High-altitude trek and camping route',
      'icon': Icons.alt_route,
    },
    {
      'name': 'Jarogo Waterfall',
      'category': 'Adventure',
      'subtitle': 'Waterfall, hiking and photography',
      'icon': Icons.waterfall_chart,
    },
  ];

  List<Map<String, dynamic>> get _visible {
    final String query = _search.trim().toLowerCase();

    return _destinations.where((item) {
      final String name = item['name'].toString().toLowerCase();
      final String subtitle = item['subtitle'].toString().toLowerCase();
      final String category = item['category'].toString();

      return (_category == 'All' || category == _category) &&
          (query.isEmpty ||
              name.contains(query) ||
              subtitle.contains(query) ||
              category.toLowerCase().contains(query));
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final int columns = width >= 1050 ? 4 : width >= 700 ? 3 : 2;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'SWAT TOURS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _showSupport,
            icon: const Icon(Icons.support_agent, color: yellow),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _hero(),
                        const SizedBox(height: 16),
                        _quickActions(),
                        const SizedBox(height: 22),
                        const Text(
                          'Explore Destinations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Choose a destination and continue to tour booking.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        _searchField(),
                        const SizedBox(height: 12),
                        _categoryBar(),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                if (_visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _destinationCard(_visible[index]),
                        childCount: _visible.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: width >= 700 ? 1.15 : 0.9,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  sliver: SliverToBoxAdapter(child: _bypassCard()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: yellow.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Swat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Group tours, private trips, hotels and tourism support from one place.',
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Icon(Icons.landscape, color: yellow, size: 64),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final List<Widget> actions = [
      _actionCard(
        Icons.groups,
        'Group Tour',
        'Shared per-person tour',
        _selectGroupDestination,
      ),
      _actionCard(
        Icons.directions_car,
        'Private Tour',
        'Custom family quotation',
        () => _privateTourSheet(),
      ),
      _actionCard(
        Icons.hotel,
        'Hotels',
        'Connected hotel module',
        () => _message(
          'Open Hotels from the Tour + Hotel option. Hotel navigation stays separate to avoid duplicate screens.',
        ),
      ),
      _actionCard(
        Icons.receipt_long,
        'My Tours',
        'Bookings and quotations',
        _openMyTourBookings,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.12,
            children: actions,
          );
        }

        return Row(
          children: [
            for (int index = 0; index < actions.length; index++) ...[
              Expanded(child: actions[index]),
              if (index < actions.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _actionCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: yellow, size: 31),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _search = value),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search destination or activity...',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: yellow),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _categoryBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final bool selected = category == _category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(category),
              selectedColor: yellow.withValues(alpha: 0.25),
              checkmarkColor: yellow,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) => setState(() => _category = category),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _destinationCard(Map<String, dynamic> item) {
    final String name = item['name'].toString();

    return InkWell(
      onTap: () => _destinationOptions(name),
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item['icon'] as IconData, color: yellow, size: 39),
            const Spacer(),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['subtitle'].toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['category'].toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                ),
                const Icon(Icons.chevron_right, color: yellow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _destinationOptions(String destination) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                destination,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.groups, color: yellow),
                title: const Text(
                  'Group / Sharing Tour',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Shared vehicle and per-person quotation',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openGroupTour(destination);
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_car, color: yellow),
                title: const Text(
                  'Private / Family Tour',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Custom pickup, vehicle and hotel request',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _privateTourSheet(destination: destination);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGroupTour(String destination) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GroupTourScreen(destinationName: destination),
      ),
    );
  }

  void _openMyTourBookings() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MyTourBookingsScreen(),
      ),
    );
  }

  Future<void> _selectGroupDestination() async {
    final String? destination = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select Destination',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._destinations.map(
                (item) => ListTile(
                  leading: Icon(item['icon'] as IconData, color: yellow),
                  title: Text(
                    item['name'].toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    item['subtitle'].toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    item['name'].toString(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (destination != null && mounted) {
      _openGroupTour(destination);
    }
  }

  Future<void> _privateTourSheet({String? destination}) async {
    String selectedDestination = destination ?? 'Kalam Valley';
    int travellers = 1;
    final TextEditingController pickup =
        TextEditingController(text: 'Mingora, Swat');
    final TextEditingController notes = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            18,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Private Tour Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedDestination,
                  dropdownColor: darkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Destination', Icons.location_on),
                  items: _destinations
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item['name'].toString(),
                          child: Text(item['name'].toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => selectedDestination = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pickup,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Pickup location', Icons.my_location),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Travellers',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: travellers > 1
                          ? () => setSheetState(() => travellers--)
                          : null,
                      icon: const Icon(Icons.remove_circle, color: yellow),
                    ),
                    Text(
                      '$travellers',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: travellers < 20
                          ? () => setSheetState(() => travellers++)
                          : null,
                      icon: const Icon(Icons.add_circle, color: yellow),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration(
                    'Hotel, vehicle or route request',
                    Icons.notes,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showPrivateResult(
                        destination: selectedDestination,
                        pickup: pickup.text.trim(),
                        travellers: travellers,
                        notes: notes.text.trim(),
                      );
                    },
                    icon: const Icon(Icons.request_quote),
                    label: const Text('Create Test Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    pickup.dispose();
    notes.dispose();
  }

  void _showPrivateResult({
    required String destination,
    required String pickup,
    required int travellers,
    required String notes,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: darkCard,
        title: const Text(
          'Private Tour Request Ready',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Destination: $destination\nPickup: ${pickup.isEmpty ? 'Not provided' : pickup}\nTravellers: $travellers\nRequest: ${notes.isEmpty ? 'Standard private tour' : notes}\n\nTesting bypass is active. No real payment is charged.',
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );

    // =======================================================
    // REAL FIREBASE + BILLING CODE - KEEP COMMENTED
    // =======================================================
    //
    // final user = FirebaseAuth.instance.currentUser;
    // final requestRef = FirebaseFirestore.instance
    //     .collection('tour_quotation_requests')
    //     .doc();
    //
    // await requestRef.set({
    //   'quotationId': requestRef.id,
    //   'userId': user!.uid,
    //   'tourType': 'private',
    //   'destinationName': destination,
    //   'pickupLocation': pickup,
    //   'travellers': travellers,
    //   'specialRequest': notes,
    //   'quotationStatus': 'pending_admin_review',
    //   'paymentStatus': 'not_started',
    //   'createdAt': FieldValue.serverTimestamp(),
    //   'updatedAt': FieldValue.serverTimestamp(),
    // });
    //
    // Production flow:
    // 1. Load admin-controlled tour/package prices.
    // 2. Assign approved tourism driver, vehicle and guide.
    // 3. Offer approved hotel/room choices.
    // 4. Calculate discount, commission and advance.
    // 5. Process JazzCash, Easypaisa or Wallet payment.
    // 6. Create the final tour booking and notifications.
    //
    // Firebase Storage remains bypassed by project decision.
    // =======================================================
  }

  Widget _bypassCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Testing bypass is active. Firebase Storage, paid Maps services and real payment gateways are paused. Production Firebase and billing flow is preserved in comments.',
              style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: yellow, size: 52),
          const SizedBox(height: 12),
          const Text(
            'No destination found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _search = '';
                _category = 'All';
              });
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: yellow),
      filled: true,
      fillColor: darkBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: yellow),
      ),
    );
  }

  void _showSupport() {
    _message(
      'Tourism support and SOS will use the shared SWAT RIDE support system.',
    );
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: darkCard),
      );
  }
}
