import 'package:flutter/material.dart';
import 'package:premium_email_app/core/constants/app_colors.dart';
import 'package:premium_email_app/models/email_model.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

class AttachmentPicker extends StatelessWidget {
  final Function(EmailAttachment) onAttachmentSelected;
  final bool multiple;
  final BuildContext? parentContext;

  const AttachmentPicker({
    super.key,
    required this.onAttachmentSelected,
    this.multiple = true,
    this.parentContext,
  });

  Future<void> _pickFiles(BuildContext context) async {
    try {
      print('🎯 ATTACHMENT PICKER: Starting file selection...');
      
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: multiple,
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'
        ],
        withData: true,
        allowCompression: true,
      );

      if (result != null && result.files.isNotEmpty) {
        print('📁 Files selected: ${result.files.length}');
        
        for (var file in result.files) {
          print('📄 Processing file: ${file.name} (${file.size} bytes)');
          
          if (file.bytes != null) {
            print('✅ File bytes available: ${file.bytes!.length} bytes');
            
            final attachment = EmailAttachment(
              filename: file.name,
              contentType: _getMimeType(file.name),
              base64Content: base64Encode(file.bytes!),
              sizeInBytes: file.bytes!.length,
            );
            
            print('📦 Created attachment: ${attachment.filename}');
            onAttachmentSelected(attachment);
            
            // ✅ REMOVED: No snackbar here, parent will show it
            print('📤 Sent attachment to parent screen');
          } else {
            print('❌ File bytes are NULL for: ${file.name}');
            print('   Path: ${file.path}');
            print('   Size: ${file.size}');
            
            if (file.path != null) {
              print('🔄 Trying to read file from path...');
              try {
                final fileData = await File(file.path!).readAsBytes();
                print('✅ Read from path: ${fileData.length} bytes');
                
                final attachment = EmailAttachment(
                  filename: file.name,
                  contentType: _getMimeType(file.name),
                  base64Content: base64Encode(fileData),
                  sizeInBytes: fileData.length,
                );
                
                onAttachmentSelected(attachment);
                print('📤 Sent attachment to parent screen');
              } catch (e) {
                print('❌ Error reading file from path: $e');
                _showErrorNotification(context, 'Cannot read file: ${file.name}');
              }
            } else {
              _showErrorNotification(context, 'Cannot attach file: ${file.name}');
            }
          }
        }
      } else {
        print('⚠️ No files selected or selection cancelled');
      }
    } catch (e) {
      print('💥 Error picking files: $e');
      _showErrorNotification(context, 'Failed to add file: ${e.toString()}');
    }
  }

  Future<void> _pickFilesUsingPath(BuildContext context) async {
    try {
      print('🔄 Using alternative file picker method...');
      
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: multiple,
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'
        ],
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.path != null) {
            try {
              print('📁 Reading file from path: ${file.path}');
              final fileData = await File(file.path!).readAsBytes();
              
              if (fileData.length > 25 * 1024 * 1024) {
                _showErrorNotification(context, 'File too large: ${file.name} (max 25MB)');
                continue;
              }
              
              final attachment = EmailAttachment(
                filename: file.name,
                contentType: _getMimeType(file.name),
                base64Content: base64Encode(fileData),
                sizeInBytes: fileData.length,
              );
              
              print('✅ Attached: ${file.name} (${fileData.length} bytes)');
              onAttachmentSelected(attachment);
              print('📤 Sent attachment to parent screen');
              
            } catch (e) {
              print('❌ Error reading file: $e');
              _showErrorNotification(context, 'Error reading file: ${file.name}');
            }
          }
        }
      }
    } catch (e) {
      print('💥 Alternative picker error: $e');
      _showErrorNotification(context, 'Failed to pick files');
    }
  }

  // ✅ FIXED: Only show error notifications, success handled by parent
  void _showErrorNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveContext = parentContext ?? context;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickFiles(effectiveContext),
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _pickFilesUsingPath(effectiveContext),
              icon: const Icon(Icons.folder_open),
              label: const Text('Large Files'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.border),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '✅ Images, PDF, DOC, XLS, TXT (Max 25MB)\n⚠️ Use "Large Files" for big documents',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}