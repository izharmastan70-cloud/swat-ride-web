// SWAT RIDE - UNIVERSAL TRUSTED CONTACTS SCREEN
//
// Shared screen for:
// - Ride users and drivers
// - Student Ride parents, guardians and drivers
// - Food customers, riders and restaurant partners
// - Cargo / Parcel customers and drivers
// - Hotel guests, owners and staff
// - Tour customers, guides and tourism drivers
//
// A user keeps one central trusted-contact list.
// The same contacts can be used by every SWAT RIDE service.

import 'package:flutter/material.dart';

import '../models/trusted_contact_model.dart';
import '../services/trusted_contact_service.dart';
import '../widgets/safety_widgets.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({
    super.key,
    required this.userId,
    this.contactService,
    this.maximumContacts = 3,
  });

  final String userId;
  final TrustedContactService? contactService;
  final int maximumContacts;

  @override
  State<TrustedContactsScreen> createState() =>
      _TrustedContactsScreenState();
}

class _TrustedContactsScreenState
    extends State<TrustedContactsScreen> {
  late final TrustedContactService _contactService;

  String? _processingContactId;
  bool _isOpeningForm = false;

  @override
  void initState() {
    super.initState();

    _contactService = widget.contactService ??
        TrustedContactService(
          defaultMaximumContacts: widget.maximumContacts,
        );
  }

  Future<void> _openAddContactForm(
    List<TrustedContactModel> contacts,
  ) async {
    if (_isOpeningForm) {
      return;
    }

    if (contacts.length >= widget.maximumContacts) {
      _showMessage(
        'You can add a maximum of '
        '${widget.maximumContacts} trusted contacts.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isOpeningForm = true;
    });

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return _TrustedContactFormSheet(
            title: 'Add Trusted Contact',
            submitLabel: 'Add Contact',
            onSubmit: ({
              required String name,
              required String phoneNumber,
              required String relationship,
              required bool isPrimary,
              required bool receiveSosAlerts,
              required bool receiveLiveLocation,
              required bool receiveServiceDetails,
              required bool receiveSafetyUpdates,
            }) async {
              await _contactService.addContact(
                userId: widget.userId,
                name: name,
                phoneNumber: phoneNumber,
                relationship: relationship,
                isPrimary: isPrimary,
                receiveSosAlerts: receiveSosAlerts,
                receiveLiveLocation: receiveLiveLocation,
                receiveServiceDetails:
                    receiveServiceDetails,
                receiveSafetyUpdates:
                    receiveSafetyUpdates,
                maximumContacts: widget.maximumContacts,
              );
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningForm = false;
        });
      }
    }
  }

  Future<void> _openEditContactForm(
    TrustedContactModel contact,
  ) async {
    if (_isOpeningForm) {
      return;
    }

    setState(() {
      _isOpeningForm = true;
    });

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return _TrustedContactFormSheet(
            title: 'Edit Trusted Contact',
            submitLabel: 'Save Changes',
            initialContact: contact,
            onSubmit: ({
              required String name,
              required String phoneNumber,
              required String relationship,
              required bool isPrimary,
              required bool receiveSosAlerts,
              required bool receiveLiveLocation,
              required bool receiveServiceDetails,
              required bool receiveSafetyUpdates,
            }) async {
              await _contactService.updateContact(
                contact: contact.copyWith(
                  name: name,
                  phoneNumber: phoneNumber,
                  relationship: relationship,
                  isPrimary: isPrimary,
                  receiveSosAlerts: receiveSosAlerts,
                  receiveLiveLocation:
                      receiveLiveLocation,
                  receiveServiceDetails:
                      receiveServiceDetails,
                  receiveSafetyUpdates:
                      receiveSafetyUpdates,
                ),
              );
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningForm = false;
        });
      }
    }
  }

  Future<void> _setPrimaryContact(
    TrustedContactModel contact,
  ) async {
    if (contact.isPrimary ||
        _processingContactId != null) {
      return;
    }

    setState(() {
      _processingContactId = contact.contactId;
    });

    try {
      await _contactService.setPrimaryContact(
        userId: widget.userId,
        contactId: contact.contactId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${contact.name} is now your primary contact.',
      );
    } on TrustedContactServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to set primary contact.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingContactId = null;
        });
      }
    }
  }

  Future<void> _toggleContactStatus(
    TrustedContactModel contact,
  ) async {
    if (_processingContactId != null) {
      return;
    }

    setState(() {
      _processingContactId = contact.contactId;
    });

    try {
      await _contactService.updateContactEnabledStatus(
        contactId: contact.contactId,
        userId: widget.userId,
        isEnabled: !contact.isEnabled,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        contact.isEnabled
            ? '${contact.name} has been disabled.'
            : '${contact.name} has been enabled.',
      );
    } on TrustedContactServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to update trusted contact.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingContactId = null;
        });
      }
    }
  }

  Future<void> _deleteContact(
    TrustedContactModel contact,
  ) async {
    if (_processingContactId != null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);

        return AlertDialog(
          icon: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error,
          ),
          title: const Text(
            'Delete trusted contact?',
          ),
          content: Text(
            '${contact.name} will no longer receive '
            'SWAT RIDE safety alerts.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    theme.colorScheme.error,
                foregroundColor:
                    theme.colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _processingContactId = contact.contactId;
    });

    try {
      await _contactService.deleteContact(
        contactId: contact.contactId,
        userId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${contact.name} was removed.',
      );
    } on TrustedContactServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete trusted contact.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingContactId = null;
        });
      }
    }
  }

  void _showContactMenu(
    TrustedContactModel contact,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            22,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(height: 16),
              SafetySectionTitle(
                title: contact.name,
                subtitle: contact.phoneNumber,
              ),
              const SizedBox(height: 14),
              SafetyActionTile(
                title: 'Edit contact',
                subtitle:
                    'Update name, number and preferences',
                icon: Icons.edit_outlined,
                onTap: () {
                  Navigator.of(context).pop();
                  _openEditContactForm(contact);
                },
              ),
              if (!contact.isPrimary) ...<Widget>[
                const SizedBox(height: 9),
                SafetyActionTile(
                  title: 'Set as primary',
                  subtitle:
                      'Use first during an emergency',
                  icon: Icons.star_outline,
                  onTap: () {
                    Navigator.of(context).pop();
                    _setPrimaryContact(contact);
                  },
                ),
              ],
              const SizedBox(height: 9),
              SafetyActionTile(
                title: contact.isEnabled
                    ? 'Disable contact'
                    : 'Enable contact',
                subtitle: contact.isEnabled
                    ? 'Stop alerts without deleting'
                    : 'Allow emergency alerts again',
                icon: contact.isEnabled
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
                onTap: () {
                  Navigator.of(context).pop();
                  _toggleContactStatus(contact);
                },
              ),
              const SizedBox(height: 9),
              SafetyActionTile(
                title: 'Delete contact',
                subtitle:
                    'Remove this trusted contact',
                icon: Icons.delete_outline,
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteContact(contact);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    final ThemeData theme = Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? theme.colorScheme.error
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanUserId = widget.userId.trim();

    if (cleanUserId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'User ID is required to manage '
            'trusted contacts.',
          ),
        ),
      );
    }

    return StreamBuilder<List<TrustedContactModel>>(
      stream: _contactService.watchUserContacts(
        userId: cleanUserId,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<TrustedContactModel>> snapshot,
      ) {
        final List<TrustedContactModel> contacts =
            snapshot.data ?? <TrustedContactModel>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Trusted Contacts'),
            centerTitle: true,
          ),
          floatingActionButton: contacts.length >=
                  widget.maximumContacts
              ? null
              : FloatingActionButton.extended(
                  onPressed: _isOpeningForm
                      ? null
                      : () {
                          _openAddContactForm(contacts);
                        },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Contact'),
                ),
          body: SafeArea(
            child: _buildBody(
              context,
              snapshot,
              contacts,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<TrustedContactModel>> snapshot,
    List<TrustedContactModel> contacts,
  ) {
    if (snapshot.connectionState ==
            ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return _buildErrorState(context);
    }

    if (contacts.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        100,
      ),
      children: <Widget>[
        _buildHeaderCard(
          context,
          contacts.length,
        ),
        const SizedBox(height: 18),
        const SafetySectionTitle(
          title: 'Your contacts',
          subtitle:
              'Primary contacts are used first during '
              'an emergency.',
        ),
        const SizedBox(height: 11),
        ...contacts.map(
          (TrustedContactModel contact) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildContactCard(
                context,
                contact,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildPrivacyNotice(context),
      ],
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    int contactCount,
  ) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary
                .withValues(alpha: 0.14),
            theme.colorScheme.primary
                .withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.people_alt_outlined,
              size: 30,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'People you trust',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$contactCount of '
                  '${widget.maximumContacts} contacts added',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context,
    TrustedContactModel contact,
  ) {
    final ThemeData theme = Theme.of(context);

    final bool isProcessing =
        _processingContactId == contact.contactId;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isProcessing
            ? null
            : () {
                _showContactMenu(contact);
              },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: contact.isPrimary
                  ? theme.colorScheme.primary
                      .withValues(alpha: 0.45)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  CircleAvatar(
                    radius: 25,
                    backgroundColor:
                        theme.colorScheme.primary
                            .withValues(alpha: 0.10),
                    child: Text(
                      _initials(contact.name),
                      style:
                          theme.textTheme.titleMedium
                              ?.copyWith(
                        color:
                            theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (contact.isPrimary)
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.star,
                          size: 11,
                          color:
                              theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            contact.name,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: theme
                                .textTheme.titleSmall
                                ?.copyWith(
                              fontWeight:
                                  FontWeight.w800,
                              color: contact.isEnabled
                                  ? null
                                  : theme.disabledColor,
                            ),
                          ),
                        ),
                        if (contact.isPrimary)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme
                                  .colorScheme.primary
                                  .withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius.circular(50),
                            ),
                            child: Text(
                              'Primary',
                              style: theme
                                  .textTheme.labelSmall
                                  ?.copyWith(
                                color: theme
                                    .colorScheme.primary,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contact.phoneNumber,
                      style:
                          theme.textTheme.bodyMedium
                              ?.copyWith(
                        color: contact.isEnabled
                            ? theme.colorScheme
                                .onSurfaceVariant
                            : theme.disabledColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contact.relationship,
                      style:
                          theme.textTheme.bodySmall
                              ?.copyWith(
                        color: theme.colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _buildPreferenceChip(
                          context,
                          label: contact.isEnabled
                              ? 'Enabled'
                              : 'Disabled',
                          icon: contact.isEnabled
                              ? Icons.check_circle_outline
                              : Icons.pause_circle_outline,
                          active: contact.isEnabled,
                        ),
                        if (contact.receiveSosAlerts)
                          _buildPreferenceChip(
                            context,
                            label: 'SOS',
                            icon: Icons.sos,
                          ),
                        if (contact.receiveLiveLocation)
                          _buildPreferenceChip(
                            context,
                            label: 'Location',
                            icon:
                                Icons.location_on_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isProcessing)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(
                  Icons.more_vert,
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    bool active = true,
  }) {
    final ThemeData theme = Theme.of(context);

    final Color color = active
        ? theme.colorScheme.primary
        : theme.disabledColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary
                    .withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.people_alt_outlined,
                size: 43,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No trusted contacts yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add family, friends or guardians who can '
              'receive your emergency alerts.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isOpeningForm
                  ? null
                  : () {
                      _openAddContactForm(
                        const <TrustedContactModel>[],
                      );
                    },
              icon: const Icon(
                Icons.person_add_alt_1,
              ),
              label: const Text(
                'Add Trusted Contact',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(210, 52),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 62,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 15),
            Text(
              'Unable to load contacts',
              style: theme.textTheme.titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and '
              'try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyNotice(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.privacy_tip_outlined,
            size: 21,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Trusted contacts may receive emergency '
              'location and service details only according '
              'to the preferences you enable.',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}'
            '${parts.last.characters.first}'
        .toUpperCase();
  }
}

typedef TrustedContactSubmitCallback = Future<void> Function({
  required String name,
  required String phoneNumber,
  required String relationship,
  required bool isPrimary,
  required bool receiveSosAlerts,
  required bool receiveLiveLocation,
  required bool receiveServiceDetails,
  required bool receiveSafetyUpdates,
});

class _TrustedContactFormSheet extends StatefulWidget {
  const _TrustedContactFormSheet({
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.initialContact,
  });

  final String title;
  final String submitLabel;
  final TrustedContactModel? initialContact;
  final TrustedContactSubmitCallback onSubmit;

  @override
  State<_TrustedContactFormSheet> createState() =>
      _TrustedContactFormSheetState();
}

class _TrustedContactFormSheetState
    extends State<_TrustedContactFormSheet> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController
      _relationshipController;

  late bool _isPrimary;
  late bool _receiveSosAlerts;
  late bool _receiveLiveLocation;
  late bool _receiveServiceDetails;
  late bool _receiveSafetyUpdates;

  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    final TrustedContactModel? contact =
        widget.initialContact;

    _nameController = TextEditingController(
      text: contact?.name ?? '',
    );

    _phoneController = TextEditingController(
      text: contact?.phoneNumber ?? '',
    );

    _relationshipController =
        TextEditingController(
      text: contact?.relationship ?? '',
    );

    _isPrimary = contact?.isPrimary ?? false;

    _receiveSosAlerts =
        contact?.receiveSosAlerts ?? true;

    _receiveLiveLocation =
        contact?.receiveLiveLocation ?? true;

    _receiveServiceDetails =
        contact?.receiveServiceDetails ?? true;

    _receiveSafetyUpdates =
        contact?.receiveSafetyUpdates ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      await widget.onSubmit(
        name: _nameController.text.trim(),
        phoneNumber:
            _phoneController.text.trim(),
        relationship:
            _relationshipController.text.trim(),
        isPrimary: _isPrimary,
        receiveSosAlerts: _receiveSosAlerts,
        receiveLiveLocation:
            _receiveLiveLocation,
        receiveServiceDetails:
            _receiveServiceDetails,
        receiveSafetyUpdates:
            _receiveSafetyUpdates,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } on TrustedContactServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'Unable to save trusted contact.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              22,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.outlineVariant,
                        borderRadius:
                            BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  SafetySectionTitle(
                    title: widget.title,
                    subtitle:
                        'This contact can receive your '
                        'SWAT RIDE emergency alerts.',
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      prefixIcon:
                          const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter contact name.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon:
                          const Icon(Icons.phone_outlined),
                      hintText: '+92 300 1234567',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    validator: (String? value) {
                      final String cleanValue =
                          value?.trim() ?? '';

                      if (cleanValue.isEmpty) {
                        return 'Enter phone number.';
                      }

                      final String normalized =
                          cleanValue.replaceAll(
                        RegExp(r'[^0-9+]'),
                        '',
                      );

                      if (normalized.length < 7) {
                        return 'Enter a valid phone number.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller:
                        _relationshipController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Relationship',
                      prefixIcon: const Icon(
                        Icons.family_restroom_outlined,
                      ),
                      hintText:
                          'Father, Mother, Friend...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    validator: (String? value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter relationship.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  const SafetySectionTitle(
                    title: 'Contact preferences',
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: _isPrimary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Primary emergency contact',
                    ),
                    subtitle: const Text(
                      'This person will be contacted first',
                    ),
                    secondary:
                        const Icon(Icons.star_outline),
                    onChanged: (bool value) {
                      setState(() {
                        _isPrimary = value;
                      });
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: _receiveSosAlerts,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Receive SOS alerts',
                    ),
                    subtitle: const Text(
                      'Send emergency notifications',
                    ),
                    secondary: const Icon(Icons.sos),
                    onChanged: (bool value) {
                      setState(() {
                        _receiveSosAlerts = value;
                      });
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: _receiveLiveLocation,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Receive live location',
                    ),
                    subtitle: const Text(
                      'Share emergency location',
                    ),
                    secondary: const Icon(
                      Icons.location_on_outlined,
                    ),
                    onChanged: (bool value) {
                      setState(() {
                        _receiveLiveLocation = value;
                      });
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: _receiveServiceDetails,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Receive service details',
                    ),
                    subtitle: const Text(
                      'Ride, driver, vehicle, hotel or '
                      'tour information',
                    ),
                    secondary: const Icon(
                      Icons.receipt_long_outlined,
                    ),
                    onChanged: (bool value) {
                      setState(() {
                        _receiveServiceDetails = value;
                      });
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: _receiveSafetyUpdates,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Receive safety updates',
                    ),
                    subtitle: const Text(
                      'Incident status and resolution',
                    ),
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                    ),
                    onChanged: (bool value) {
                      setState(() {
                        _receiveSafetyUpdates = value;
                      });
                    },
                  ),
                  if (_errorMessage.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: Text(
                        _errorMessage,
                        style:
                            theme.textTheme.bodySmall
                                ?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(17),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.3,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.submitLabel),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}