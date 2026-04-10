import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/widgets/section_container.dart';
import '../../../core/ui/widgets/state_views.dart';
import '../data/contact_admin_service.dart';
import '../models/contact_model.dart';

class ContactAdminPage extends StatefulWidget {
  const ContactAdminPage({super.key});

  @override
  State<ContactAdminPage> createState() => _ContactAdminPageState();
}

class _ContactAdminPageState extends State<ContactAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _workScheduleController = TextEditingController();

  late final ContactAdminService _service;

  List<ContactModel> _contacts = const <ContactModel>[];
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _editingContactId;
  int? _editingLoadId;
  String? _loadError;
  final Set<int> _deletingIds = <int>{};

  bool get _isEditMode => _editingContactId != null;

  @override
  void initState() {
    super.initState();
    _service = ContactAdminService();
    _loadContacts();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _workScheduleController.dispose();
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Contact',
      subtitle: 'Create, update, and remove contact records.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: _isSubmitting ? null : _handleRefresh,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading && _contacts.isEmpty) {
      return const LoadingState();
    }

    if (_loadError != null && _contacts.isEmpty) {
      return ErrorState(message: _loadError!, onRetry: _handleRefresh);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormCard(context),
        const SizedBox(height: 16),
        if (_loadError != null && _contacts.isNotEmpty) ...[
          _InlineErrorBanner(message: _loadError!),
          const SizedBox(height: 12),
        ],
        Expanded(child: _buildContactsCard(context)),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _isEditMode
                        ? 'Edit Contact #$_editingContactId'
                        : 'Add Contact',
                    style: theme.textTheme.titleLarge,
                  ),
                  Chip(
                    label: Text(_isEditMode ? 'Update mode' : 'Create mode'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 920;
                  final double halfWidth = isWide
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: halfWidth,
                        child: _buildTextField(
                          controller: _phoneNumberController,
                          label: 'Phone Number',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                        ),
                      ),
                      SizedBox(
                        width: halfWidth,
                        child: _buildTextField(
                          controller: _workScheduleController,
                          label: 'Work Schedule',
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _buildTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_isEditMode ? Icons.save_outlined : Icons.add),
                    label: Text(
                      _isEditMode ? 'Update Contact' : 'Create Contact',
                    ),
                  ),
                  if (_isEditMode)
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _cancelEdit,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel Edit'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Contacts List',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Chip(
                  label: Text(
                    '${_contacts.length} item${_contacts.length == 1 ? '' : 's'}',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          const Divider(height: 1),
          Expanded(
            child: _contacts.isEmpty
                ? const EmptyState(message: 'No contact records found.')
                : LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 960) {
                        return _buildMobileList();
                      }
                      return _buildDesktopTable(context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    final highlightColor = Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: 0.25);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 48,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 104,
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Address')),
            DataColumn(label: Text('Work Schedule')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Actions')),
          ],
          rows: List<DataRow>.generate(_contacts.length, (index) {
            final contact = _contacts[index];
            final isActive =
                contact.id != null && contact.id == _editingContactId;

            return DataRow.byIndex(
              index: index,
              color: WidgetStateProperty.resolveWith<Color?>((states) {
                if (isActive) {
                  return highlightColor;
                }
                return null;
              }),
              cells: [
                DataCell(Text('${contact.id ?? '-'}')),
                DataCell(
                  SizedBox(
                    width: 140,
                    child: Text(
                      _displayValue(contact.phoneNumber),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      _displayValue(contact.email),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      _displayValue(contact.address),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      _displayValue(contact.workSchedule),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 260,
                    child: Text(
                      _displayValue(contact.description),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(width: 220, child: _buildRowActions(contact)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _contacts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final theme = Theme.of(context);
        final isActive = contact.id != null && contact.id == _editingContactId;

        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.45)
                  : theme.dividerColor,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Contact #${contact.id ?? '-'}',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (isActive)
                      Chip(
                        label: const Text('Editing'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailLine(label: 'Phone', value: contact.phoneNumber),
                _DetailLine(label: 'Email', value: contact.email),
                _DetailLine(label: 'Address', value: contact.address),
                _DetailLine(
                  label: 'Work Schedule',
                  value: contact.workSchedule,
                ),
                _DetailLine(
                  label: 'Description',
                  value: contact.description,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                _buildRowActions(contact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildRowActions(ContactModel contact) {
    final contactId = contact.id;
    final isLoadingEdit = contactId != null && _editingLoadId == contactId;
    final isDeleting = contactId != null && _deletingIds.contains(contactId);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: contactId == null || isDeleting || _isSubmitting
              ? null
              : () => _startEdit(contact),
          icon: isLoadingEdit
              ? const _SmallButtonLoader()
              : const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
        ),
        TextButton.icon(
          onPressed: contactId == null || isDeleting || _isSubmitting
              ? null
              : () => _confirmDelete(contact),
          icon: isDeleting
              ? const _SmallButtonLoader()
              : const Icon(Icons.delete_outline, size: 18),
          label: const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _handleRefresh() async {
    await _loadContacts(showFailureSnackBar: true);
  }

  Future<void> _loadContacts({bool showFailureSnackBar = false}) async {
    setState(() {
      _isLoading = true;
      if (_contacts.isEmpty) {
        _loadError = null;
      }
    });

    try {
      final contacts = await _service.fetchContacts();
      contacts.sort((left, right) => (right.id ?? 0).compareTo(left.id ?? 0));

      if (!mounted) {
        return;
      }

      setState(() {
        _contacts = contacts;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = _errorMessage(error);
      setState(() {
        _isLoading = false;
        _loadError = message;
      });

      if (showFailureSnackBar) {
        _showSnackBar(message, isError: true);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = ContactModel(
      phoneNumber: _phoneNumberController.text,
      address: _addressController.text,
      description: _descriptionController.text,
      email: _emailController.text,
      workSchedule: _workScheduleController.text,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditMode) {
        await _service.updateContact(_editingContactId!, draft);
      } else {
        await _service.createContact(draft);
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        _isEditMode
            ? 'Contact updated successfully.'
            : 'Contact created successfully.',
      );
      _cancelEdit();
      await _loadContacts(showFailureSnackBar: true);
    } catch (error) {
      if (mounted) {
        _showSnackBar(_errorMessage(error), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _startEdit(ContactModel contact) async {
    final contactId = contact.id;
    if (contactId == null) {
      _fillForm(contact);
      return;
    }

    setState(() {
      _editingLoadId = contactId;
    });

    try {
      final freshContact = await _service.fetchContact(contactId);
      if (!mounted) {
        return;
      }
      _fillForm(freshContact);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _fillForm(contact);
      _showSnackBar(
        '${_errorMessage(error)} Using the currently loaded row values.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _editingLoadId = null;
        });
      }
    }
  }

  void _fillForm(ContactModel contact) {
    _phoneNumberController.text = contact.phoneNumber ?? '';
    _addressController.text = contact.address ?? '';
    _descriptionController.text = contact.description ?? '';
    _emailController.text = contact.email ?? '';
    _workScheduleController.text = contact.workSchedule ?? '';

    setState(() {
      _editingContactId = contact.id;
    });
  }

  void _cancelEdit() {
    _formKey.currentState?.reset();
    _phoneNumberController.clear();
    _addressController.clear();
    _descriptionController.clear();
    _emailController.clear();
    _workScheduleController.clear();

    setState(() {
      _editingContactId = null;
    });
  }

  Future<void> _confirmDelete(ContactModel contact) async {
    final contactId = contact.id;
    if (contactId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text(
            'Are you sure you want to delete contact #$contactId? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      _deletingIds.add(contactId);
    });

    try {
      await _service.deleteContact(contactId);
      if (!mounted) {
        return;
      }

      if (_editingContactId == contactId) {
        _cancelEdit();
      }

      _showSnackBar('Contact deleted successfully.');
      await _loadContacts(showFailureSnackBar: true);
    } catch (error) {
      if (mounted) {
        _showSnackBar(_errorMessage(error), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(contactId);
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error700 : AppColors.success700,
        content: Text(message),
      ),
    );
  }

  String _displayValue(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '-';
    }
    return normalized;
  }

  String _errorMessage(Object error) {
    if (error is ContactAdminServiceException) {
      return error.message;
    }

    final text = error.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  final String label;
  final String? value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final normalized = value?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              normalized == null || normalized.isEmpty ? '-' : normalized,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.error700.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error700.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error700),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _SmallButtonLoader extends StatelessWidget {
  const _SmallButtonLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
