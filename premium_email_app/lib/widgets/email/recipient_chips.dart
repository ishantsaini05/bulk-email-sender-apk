import 'package:flutter/material.dart';
import 'package:premium_email_app/core/constants/app_colors.dart';
import 'package:premium_email_app/core/utils/helpers.dart';

class RecipientChips extends StatefulWidget {
  final String label;
  final List<String> recipients;
  final Function(List<String>) onChanged;
  final Function(String) onRemove;
  final bool readOnly;

  const RecipientChips({
    super.key,
    required this.label,
    required this.recipients,
    required this.onChanged,
    required this.onRemove,
    this.readOnly = false,
  });

  @override
  State<RecipientChips> createState() => _RecipientChipsState();
}

class _RecipientChipsState extends State<RecipientChips> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _currentInput = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addRecipient(String email) {
    if (email.trim().isNotEmpty && Helpers.isValidEmail(email.trim())) {
      final newRecipients = [...widget.recipients, email.trim()];
      widget.onChanged(newRecipients);
      _controller.clear();
      _currentInput = '';
    } else {
      _showInvalidEmailDialog(email);
    }
  }

  void _showInvalidEmailDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid Email'),
        content: Text('"$email" is not a valid email address.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleInputChange(String value) {
    setState(() => _currentInput = value);
    
    // Add recipient when comma or enter is pressed
    if (value.contains(',') || value.contains(';')) {
      final emails = value.split(RegExp(r'[,;]'));
      for (var email in emails) {
        if (email.trim().isNotEmpty) {
          _addRecipient(email.trim());
        }
      }
      _controller.clear();
    }
  }

  Widget _buildChips() {
    if (widget.recipients.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.recipients.map((recipient) {
        return Chip(
          label: Text(recipient),
          deleteIcon: widget.readOnly ? null : const Icon(Icons.close, size: 16),
          onDeleted: widget.readOnly ? null : () => widget.onRemove(recipient),
          backgroundColor: AppColors.primary.withOpacity(0.1),
          labelStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Chips display
        _buildChips(),
        
        const SizedBox(height: 8),
        
        // Input field (if not read-only)
        if (!widget.readOnly)
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _handleInputChange,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _addRecipient(value.trim());
              }
            },
            decoration: InputDecoration(
              hintText: 'Enter email address and press Enter',
              hintStyle: TextStyle(
                color: AppColors.textTertiary,
              ),
              prefixIcon: const Icon(Icons.person_add, size: 20),
              suffixIcon: _currentInput.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () {
                        if (_currentInput.trim().isNotEmpty) {
                          _addRecipient(_currentInput.trim());
                        }
                      },
                      tooltip: 'Add recipient',
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
      ],
    );
  }
}