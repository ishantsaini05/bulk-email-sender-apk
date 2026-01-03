import 'dart:io';
import 'package:flutter/material.dart';
import 'package:premium_email_app/core/constants/app_colors.dart';
import 'package:premium_email_app/core/services/email_service.dart';
import 'package:premium_email_app/models/api_response.dart';
import 'package:premium_email_app/widgets/common/custom_text_field.dart';
import 'package:premium_email_app/widgets/common/primary_button.dart';
import 'package:premium_email_app/widgets/common/loading_overlay.dart';
import 'package:premium_email_app/widgets/email/recipient_chips.dart';
import 'package:premium_email_app/widgets/email/attachment_picker.dart';
import 'package:premium_email_app/core/utils/helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:premium_email_app/models/email_model.dart';
import 'package:premium_email_app/core/services/storage_service.dart';

class ComposeEmailScreen extends StatefulWidget {
  const ComposeEmailScreen({super.key});

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  final List<String> _toRecipients = [];
  final List<String> _ccRecipients = [];
  final List<String> _bccRecipients = [];
  final List<EmailAttachment> _attachments = [];

  bool _showCc = false;
  bool _showBcc = false;
  bool _isLoading = false;
  bool _hasEmailConfig = false;

  @override
  void initState() {
    super.initState();
    _checkEmailConfig();
  }

  Future<void> _checkEmailConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final isConfigured = prefs.getBool('email_configured') ?? false;
    setState(() {
      _hasEmailConfig = isConfigured;
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    print('\n📤 ===== COMPOSE SCREEN: SEND EMAIL START =====');
    
    if (!_hasEmailConfig) {
      Helpers.showSnackbar(
        context, 
        'Please configure email first from Dashboard',
        isError: true
      );
      print('❌ Email not configured');
      return;
    }

    if (_toRecipients.isEmpty) {
      Helpers.showSnackbar(context, 'Add at least one recipient', isError: true);
      print('❌ No recipients');
      return;
    }

    if (_subjectController.text.trim().isEmpty) {
      Helpers.showSnackbar(context, 'Subject is required', isError: true);
      print('❌ No subject');
      return;
    }

    if (_bodyController.text.trim().isEmpty) {
      Helpers.showSnackbar(context, 'Email body cannot be empty', isError: true);
      print('❌ No body');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    bool allEmailsValid = true;
    
    for (var email in _toRecipients) {
      if (!emailRegex.hasMatch(email)) {
        Helpers.showSnackbar(context, 'Invalid email format: $email', isError: true);
        allEmailsValid = false;
        break;
      }
    }
    
    if (!allEmailsValid) return;
    
    final storageService = StorageService();
    final authToken = await storageService.getToken();
    
    print('🔑 Auth check before sending:');
    print('  Token exists: ${authToken != null && authToken.isNotEmpty}');
    print('  Token length: ${authToken?.length ?? 0}');
    
    if (authToken == null || authToken.isEmpty) {
      Helpers.showSnackbar(
        context,
        'Authentication required. Please login first.',
        isError: true,
      );
      print('❌ No auth token - redirecting to login');
      
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    setState(() => _isLoading = true);
    print('⏳ Loading started...');

    try {
      final emailService = EmailService();
      
      final List<Map<String, dynamic>> attachmentMaps = [];
      if (_attachments.isNotEmpty) {
        print('📎 Processing ${_attachments.length} attachments');
        
        for (var attachment in _attachments) {
          try {
            Map<String, dynamic> attachmentData = {
              'filename': attachment.filename,
              'content_type': attachment.contentType,
              'base64_content': attachment.base64Content,
              'size_in_bytes': attachment.sizeInBytes,
            };
            
            print('  📄 ${attachment.filename}: ${attachment.contentType}, ${attachment.sizeInBytes} bytes');
            
            attachmentMaps.add(attachmentData);
          } catch (e) {
            print('❌ Error processing attachment ${attachment.filename}: $e');
          }
        }
      }
      
      print('📨 Sending email details:');
      print('  To: $_toRecipients');
      print('  Subject: ${_subjectController.text}');
      print('  Body length: ${_bodyController.text.length}');
      print('  Attachments ready: ${attachmentMaps.length}');
      
      final ApiResponse result = await emailService.sendEmail(
        subject: _subjectController.text.trim(),
        body: _bodyController.text.trim(),
        recipients: _toRecipients,
        attachments: attachmentMaps.isNotEmpty ? attachmentMaps : null,
      );

      setState(() => _isLoading = false);
      print('✅ Loading stopped');

      if (result.success) {
        print('🎉 Email sent successfully!');
        Helpers.showSnackbar(context, '✅ Email sent successfully!');
        
        _clearAllFields();
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        print('❌ Email send failed: ${result.error}');
        
        if (result.error?.contains('Authentication') == true || 
            result.error?.contains('401') == true) {
          Helpers.showSnackbar(
            context,
            'Session expired. Please login again.',
            isError: true,
          );
          
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, '/login');
          });
        } else {
          Helpers.showSnackbar(
            context,
            result.error ?? 'Failed to send email',
            isError: true,
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('💥 Exception during email send: $e');
      
      String errorMessage = 'Error sending email';
      if (e.toString().contains('Network is unreachable')) {
        errorMessage = 'No internet connection';
      } else if (e.toString().contains('timed out')) {
        errorMessage = 'Request timeout. Server might be slow.';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Authentication failed. Please login again.';
      }
      
      Helpers.showSnackbar(context, errorMessage, isError: true);
    }
    
    print('📤 ===== COMPOSE SCREEN: SEND EMAIL END =====\n');
  }

  void _clearAllFields() {
    _subjectController.clear();
    _bodyController.clear();
    _toController.clear();
    _toRecipients.clear();
    _ccRecipients.clear();
    _bccRecipients.clear();
    _attachments.clear();
    setState(() {});
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildEditor() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border),
      ),
      child: SizedBox(
        height: 260,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: TextFormField(
            controller: _bodyController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Write your email here...',
              hintStyle: TextStyle(color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  void _addToRecipient() {
    final email = _toController.text.trim();
    if (email.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (emailRegex.hasMatch(email)) {
        if (!_toRecipients.contains(email)) {
          setState(() {
            _toRecipients.add(email);
            _toController.clear();
          });
          Helpers.showSnackbar(context, 'Added: $email');
        } else {
          Helpers.showSnackbar(context, 'Email already added', isError: true);
        }
      } else {
        Helpers.showSnackbar(context, 'Invalid email format', isError: true);
      }
    }
  }

  void _handleAttachmentSelected(EmailAttachment attachment) {
    setState(() {
      _attachments.add(attachment);
    });
    
    print('📎 Attachment added: ${attachment.filename}');
    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '✅ Attachment added: ${attachment.filename}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _removeAttachment(int index) {
    final attachment = _attachments[index];
    setState(() {
      _attachments.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🗑️ Attachment removed: ${attachment.filename}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    print('❌ Attachment removed: ${attachment.filename}');
  }

  String _getFileIcon(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    if (ext == 'pdf') return '📄';
    if (ext == 'doc' || ext == 'docx') return '📝';
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'gif') return '🖼️';
    if (ext == 'zip' || ext == 'rar') return '📦';
    if (ext == 'txt') return '📃';
    return '📎';
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Compose Email'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: _sendEmail,
              tooltip: 'Send Email',
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_hasEmailConfig)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Email not configured. Setup email first from Dashboard.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _toController,
                          labelText: 'To',
                          hintText: 'recipient@example.com',
                          prefixIcon: const Icon(Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          onSubmitted: (_) => _addToRecipient(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ElevatedButton(
                          onPressed: _addToRecipient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          child: const Text('Add', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_toRecipients.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _toRecipients.map((email) {
                          return Chip(
                            label: Text(email),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _toRecipients.remove(email);
                              });
                            },
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              CustomTextField(
                controller: _subjectController,
                labelText: 'Subject',
                prefixIcon: const Icon(Icons.subject),
              ),

              const SizedBox(height: 20),

              Text(
                'Message',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildEditor(),

              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AttachmentPicker(
                    onAttachmentSelected: _handleAttachmentSelected,
                  ),

                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_file, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Attachments (${_attachments.length})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          for (int i = 0; i < _attachments.length; i++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _getFileIcon(_attachments[i].filename),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _attachments[i].filename,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_formatFileSize(_attachments[i].sizeInBytes)} • ${_attachments[i].contentType}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _removeAttachment(i),
                                  ),
                                ],
                              ),
                            ),
                          
                          const SizedBox(height: 8),
                          Text(
                            '✅ Files are attached and ready to send',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Send Email',
                  icon: Icons.send,
                  isLoading: _isLoading,
                  onPressed: _sendEmail,
                  backgroundColor: AppColors.primary,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}