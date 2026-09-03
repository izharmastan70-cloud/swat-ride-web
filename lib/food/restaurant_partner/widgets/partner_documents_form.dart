// lib/food/restaurant_partner/widgets/partner_documents_form.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Documents Form
//
// Firebase Storage upload is temporarily bypassed.
// This widget stores local file paths through callbacks so the
// registration screen can later connect image_picker/file_picker.
// =============================================================

import 'package:flutter/material.dart';

class PartnerDocumentsForm extends StatelessWidget {
  const PartnerDocumentsForm({
    required this.cnicFrontPath,
    required this.cnicBackPath,
    required this.restaurantLicensePath,
    required this.foodAuthorityCertificatePath,
    required this.onPickCnicFront,
    required this.onPickCnicBack,
    required this.onPickRestaurantLicense,
    required this.onPickFoodAuthorityCertificate,
    required this.onClearCnicFront,
    required this.onClearCnicBack,
    required this.onClearRestaurantLicense,
    required this.onClearFoodAuthorityCertificate,
    super.key,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final String cnicFrontPath;
  final String cnicBackPath;
  final String restaurantLicensePath;
  final String foodAuthorityCertificatePath;

  final VoidCallback onPickCnicFront;
  final VoidCallback onPickCnicBack;
  final VoidCallback onPickRestaurantLicense;
  final VoidCallback onPickFoodAuthorityCertificate;

  final VoidCallback onClearCnicFront;
  final VoidCallback onClearCnicBack;
  final VoidCallback onClearRestaurantLicense;
  final VoidCallback onClearFoodAuthorityCertificate;

  bool get hasRequiredDocuments =>
      cnicFrontPath.trim().isNotEmpty &&
      cnicBackPath.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Color(0x22FFD60A),
                child: Icon(
                  Icons.folder_copy_outlined,
                  color: yellow,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Required Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Add identity and restaurant documents',
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
          _DocumentPickerTile(
            title: 'CNIC Front',
            subtitle: 'Required',
            icon: Icons.badge_outlined,
            filePath: cnicFrontPath,
            onPick: onPickCnicFront,
            onClear: onClearCnicFront,
          ),
          const SizedBox(height: 12),
          _DocumentPickerTile(
            title: 'CNIC Back',
            subtitle: 'Required',
            icon: Icons.badge,
            filePath: cnicBackPath,
            onPick: onPickCnicBack,
            onClear: onClearCnicBack,
          ),
          const SizedBox(height: 12),
          _DocumentPickerTile(
            title: 'Restaurant License',
            subtitle: 'Optional where unavailable',
            icon: Icons.description_outlined,
            filePath: restaurantLicensePath,
            onPick: onPickRestaurantLicense,
            onClear: onClearRestaurantLicense,
          ),
          const SizedBox(height: 12),
          _DocumentPickerTile(
            title: 'Food Authority Certificate',
            subtitle: 'Optional where unavailable',
            icon: Icons.verified_user_outlined,
            filePath: foodAuthorityCertificatePath,
            onPick: onPickFoodAuthorityCertificate,
            onClear: onClearFoodAuthorityCertificate,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  hasRequiredDocuments
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: hasRequiredDocuments
                      ? Colors.greenAccent
                      : yellow,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasRequiredDocuments
                        ? 'Required CNIC documents are selected.'
                        : 'CNIC front and back are required before submitting the application.',
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
            'For now, the registration screen will keep local file paths. '
            'Cloud upload can be connected later without changing this widget.',
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
}

class _DocumentPickerTile extends StatelessWidget {
  const _DocumentPickerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.filePath,
    required this.onPick,
    required this.onClear,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final String title;
  final String subtitle;
  final IconData icon;
  final String filePath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  bool get hasFile => filePath.trim().isNotEmpty;

  String get displayFileName {
    if (!hasFile) {
      return 'No file selected';
    }

    final String normalized =
        filePath.replaceAll('\\', '/');

    return normalized.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF252525),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: hasFile
                      ? Colors.green.withValues(alpha: 0.16)
                      : yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(
                  hasFile ? Icons.check : icon,
                  color:
                      hasFile ? Colors.greenAccent : yellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasFile ? displayFileName : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasFile
                            ? Colors.greenAccent
                            : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFile)
                IconButton(
                  onPressed: onClear,
                  tooltip: 'Remove',
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                )
              else
                const Icon(
                  Icons.upload_file_outlined,
                  color: yellow,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
