// lib/food/restaurant_partner/widgets/partner_images_form.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Images Form
//
// Firebase Storage upload is temporarily bypassed.
// This widget receives local image paths and callbacks from the
// registration screen.
// =============================================================

import 'package:flutter/material.dart';

class PartnerImagesForm extends StatelessWidget {
  const PartnerImagesForm({
    required this.logoImagePath,
    required this.coverImagePath,
    required this.galleryImagePaths,
    required this.onPickLogo,
    required this.onPickCover,
    required this.onAddGalleryImage,
    required this.onClearLogo,
    required this.onClearCover,
    required this.onRemoveGalleryImage,
    super.key,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final String logoImagePath;
  final String coverImagePath;
  final List<String> galleryImagePaths;

  final VoidCallback onPickLogo;
  final VoidCallback onPickCover;
  final VoidCallback onAddGalleryImage;

  final VoidCallback onClearLogo;
  final VoidCallback onClearCover;
  final ValueChanged<int> onRemoveGalleryImage;

  bool get hasRequiredImages {
    return logoImagePath.trim().isNotEmpty &&
        coverImagePath.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor:
                    Color(0x22FFD60A),
                child: Icon(
                  Icons.photo_library_outlined,
                  color: yellow,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Restaurant Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Add logo, cover and gallery photos',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ImagePickerTile(
            title: 'Restaurant Logo',
            subtitle:
                'Required • Square image recommended',
            icon: Icons.storefront_outlined,
            imagePath: logoImagePath,
            onPick: onPickLogo,
            onClear: onClearLogo,
          ),
          const SizedBox(height: 12),
          _ImagePickerTile(
            title: 'Cover Image',
            subtitle:
                'Required • Wide image recommended',
            icon: Icons.image_outlined,
            imagePath: coverImagePath,
            onPick: onPickCover,
            onClear: onClearCover,
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Gallery Images',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAddGalleryImage,
                icon: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: yellow,
                ),
                label: const Text(
                  'Add Image',
                  style: TextStyle(
                    color: yellow,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (galleryImagePaths.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF252525),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(
                    Icons.collections_outlined,
                    color: Colors.grey,
                    size: 34,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No gallery images selected',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              itemCount:
                  galleryImagePaths.length,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (
                BuildContext context,
                int index,
              ) {
                final String path =
                    galleryImagePaths[index];

                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF252525,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.image,
                            color: yellow,
                          ),
                          const SizedBox(height: 5),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            child: Text(
                              _fileName(path),
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 3,
                      right: 3,
                      child: InkWell(
                        onTap: () =>
                            onRemoveGalleryImage(
                          index,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                        child: Container(
                          padding:
                              const EdgeInsets.all(
                            4,
                          ),
                          decoration:
                              const BoxDecoration(
                            color:
                                Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF252525),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  hasRequiredImages
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: hasRequiredImages
                      ? Colors.greenAccent
                      : yellow,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasRequiredImages
                        ? 'Required restaurant images are selected.'
                        : 'Restaurant logo and cover image are required before submission.',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Firebase Storage upload is temporarily bypassed. '
            'The registration screen will keep local image paths until cloud uploads are enabled.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static String _fileName(
    String filePath,
  ) {
    final String normalized =
        filePath.replaceAll('\\', '/');

    return normalized.split('/').last;
  }
}

class _ImagePickerTile
    extends StatelessWidget {
  const _ImagePickerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imagePath,
    required this.onPick,
    required this.onClear,
  });

  static const Color yellow =
      Color(0xFFFFD60A);

  final String title;
  final String subtitle;
  final IconData icon;
  final String imagePath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  bool get hasImage =>
      imagePath.trim().isNotEmpty;

  String get fileName {
    final String normalized =
        imagePath.replaceAll('\\', '/');

    return normalized.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF252525),
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap: onPick,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: hasImage
                      ? Colors.green
                          .withValues(
                        alpha: 0.15,
                      )
                      : yellow.withValues(
                          alpha: 0.12,
                        ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  hasImage
                      ? Icons.check
                      : icon,
                  color: hasImage
                      ? Colors.greenAccent
                      : yellow,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasImage
                          ? fileName
                          : subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasImage
                            ? Colors.greenAccent
                            : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasImage)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                )
              else
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: yellow,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
