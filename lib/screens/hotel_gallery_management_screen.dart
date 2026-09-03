import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelGalleryManagementScreen extends StatefulWidget {
  const HotelGalleryManagementScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelGalleryManagementScreen> createState() =>
      _HotelGalleryManagementScreenState();
}

class _HotelGalleryManagementScreenState
    extends State<HotelGalleryManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isSaving = false;

  String _logoUrl = '';
  String _coverImageUrl = '';
  final List<String> _galleryImageUrls = <String>[];

  @override
  void initState() {
    super.initState();
    _loadGallery();
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
          'Hotel Images & Gallery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
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
                  28,
                ),
                children: [
                  _storageNotice(),

                  const SizedBox(height: 20),

                  _sectionTitle('Hotel Logo'),

                  _imageCard(
                    title: 'Logo',
                    imageUrl: _logoUrl,
                    icon: Icons.business_outlined,
                    onAdd: () {
                      _showStorageDisabled(
                        'Hotel logo upload',
                      );
                    },
                    onRemove: _logoUrl.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _logoUrl = '';
                            });
                          },
                  ),

                  const SizedBox(height: 20),

                  _sectionTitle('Cover Photo'),

                  _imageCard(
                    title: 'Cover Image',
                    imageUrl: _coverImageUrl,
                    icon: Icons.landscape_outlined,
                    onAdd: () {
                      _showStorageDisabled(
                        'Hotel cover photo upload',
                      );
                    },
                    onRemove: _coverImageUrl.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _coverImageUrl = '';
                            });
                          },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _sectionTitle(
                          'Gallery Images',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showStorageDisabled(
                            'Hotel gallery image upload',
                          );
                        },
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: yellow,
                        ),
                        label: const Text(
                          'Add Image',
                          style: TextStyle(
                            color: yellow,
                          ),
                        ),
                      ),
                    ],
                  ),

                  _galleryGrid(),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSaving ? null : _saveMetadata,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSaving
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
                              Icons.save_outlined,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'Save Gallery Metadata',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _storageNotice() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.09,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gallery structure and Firestore metadata are active. Actual image selection and upload remain disabled until Firebase Storage billing is enabled.',
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

  Widget _imageCard({
    required String title,
    required String imageUrl,
    required IconData icon,
    required VoidCallback onAdd,
    VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: darkBackground,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: imageUrl.isEmpty
                ? Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: yellow,
                        size: 44,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$title not uploaded',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius:
                        BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                            size: 42,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(
                    Icons.upload_outlined,
                  ),
                  label: Text(
                    imageUrl.isEmpty
                        ? 'Add $title'
                        : 'Replace $title',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: yellow,
                    side: const BorderSide(
                      color: yellow,
                    ),
                  ),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Colors.red.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: Colors.red,
                  ),
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _galleryGrid() {
    if (_galleryImageUrls.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: yellow,
              size: 44,
            ),
            SizedBox(height: 10),
            Text(
              'No gallery images added.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _galleryImageUrls.length,
      itemBuilder: (context, index) {
        final String imageUrl =
            _galleryImageUrls[index];

        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(14),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      color: darkCard,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _galleryImageUrls.removeAt(
                      index,
                    );
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor:
                      Colors.black.withValues(
                    alpha: 0.65,
                  ),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.delete_outline,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadGallery() async {
    try {
      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot = await _firestore
              .collection('hotels')
              .doc(widget.hotelId)
              .get();

      final Map<String, dynamic> data =
          snapshot.data() ??
              <String, dynamic>{};

      _logoUrl =
          data['logoUrl']?.toString() ?? '';

      _coverImageUrl =
          data['coverImageUrl']?.toString() ??
              data['imageUrl']?.toString() ??
              '';

      final dynamic gallery =
          data['galleryImageUrls'] ??
              data['imageUrls'];

      if (gallery is List) {
        _galleryImageUrls
          ..clear()
          ..addAll(
            gallery
                .map(
                  (item) =>
                      item.toString().trim(),
                )
                .where(
                  (item) => item.isNotEmpty,
                ),
          );
      }
    } catch (error) {
      _showMessage(
        'Unable to load gallery: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveMetadata() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore
          .collection('hotels')
          .doc(widget.hotelId)
          .set(
        {
          'logoUrl': _logoUrl,
          'coverImageUrl':
              _coverImageUrl,
          'imageUrl':
              _coverImageUrl,
          'galleryImageUrls':
              List<String>.from(
            _galleryImageUrls,
          ),
          'imageUrls':
              List<String>.from(
            _galleryImageUrls,
          ),
          'lastUpdatedBy':
              user.uid,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        'Gallery metadata saved.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save gallery: $error',
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

  void _showStorageDisabled(
    String feature,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Storage Upload Paused',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '$feature will be enabled when Firebase Storage billing is available. The screen and Firestore metadata are already prepared.',
            style: const TextStyle(
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor:
                    Colors.black,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
