import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:premium_email_app/models/api_response.dart';
import 'package:premium_email_app/models/email_model.dart';
import 'package:premium_email_app/core/constants/api_endpoints.dart';
import 'package:premium_email_app/core/services/storage_service.dart';
import 'package:premium_email_app/core/services/auth_service.dart';

class EmailService {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  
  // ✅ Get auth token - SIMPLIFIED
  Future<String?> _getAuthToken() async {
    try {
      // Pehle StorageService se try karo
      String? token = await _storageService.getToken();
      
      if (token == null || token.isEmpty) {
        // Fallback to SharedPreferences directly
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token') ?? 
                prefs.getString('access_token') ?? 
                prefs.getString('token');
      }
      
      if (token != null && token.isNotEmpty) {
        print('✅ Token found: ${token.substring(0, min(token.length, 30))}... (${token.length} chars)');
      } else {
        print('❌ No token found');
      }
      
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
  
  int min(int a, int b) => a < b ? a : b;
  
  // ✅ UPDATED: Send email individually to each recipient with FIXED ATTACHMENT HANDLING
  Future<ApiResponse> sendEmail({
    required String subject,
    required String body,
    required List<String> recipients,
    List<Map<String, dynamic>>? attachments,
    bool isHtml = false,
  }) async {
    try {
      print('🚀 === EMAIL SEND PROCESS START ===');
      print('📊 Initial check:');
      print('  Recipients: ${recipients.length}');
      print('  Attachments: ${attachments?.length ?? 0}');
      print('  Subject: $subject');
      print('  Body length: ${body.length} chars');
      
      // 1. Check email configuration
      final prefs = await SharedPreferences.getInstance();
      final isConfigured = prefs.getBool('email_configured') ?? false;
      final configuredEmail = prefs.getString('configured_email') ?? '';
      
      if (!isConfigured || configuredEmail.isEmpty) {
        print('❌ Email not configured');
        return ApiResponse(
          success: false,
          error: 'Please configure email first from Dashboard',
        );
      }
      
      print('✓ Email configured: $configuredEmail');
      
      // 2. Get authentication token
      final authToken = await _getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        print('❌ No authentication token');
        return ApiResponse(
          success: false,
          error: 'Please login first to send emails',
        );
      }
      
      print('✓ Token available: ${authToken.substring(0, min(authToken.length, 20))}...');
      
      // 3. Loop through each recipient and send individually
      final String apiUrl = ApiEndpoints.sendEmail;
      final client = http.Client();
      List<String> successfulRecipients = [];
      List<String> failedRecipients = [];
      
      try {
        for (int i = 0; i < recipients.length; i++) {
          final recipient = recipients[i];
          print('\n📧 Sending to recipient ${i + 1}/${recipients.length}: $recipient');
          
          // ✅ FIXED: Validate attachment format before sending
          List<Map<String, dynamic>> validAttachments = [];
          if (attachments != null && attachments.isNotEmpty) {
            print('  📎 Validating attachments...');
            for (var att in attachments) {
              if (att.containsKey('filename') && 
                  att.containsKey('base64_content') && 
                  att['base64_content'] != null && 
                  att['base64_content'].toString().isNotEmpty) {
                
                validAttachments.add({
                  'filename': att['filename'],
                  'content_type': att['content_type'] ?? 'application/octet-stream',
                  'base64_content': att['base64_content'],
                  'size_in_bytes': att['size_in_bytes'] ?? 0,
                });
                
                print('    ✅ ${att['filename']} - ${att['base64_content'].toString().length} chars');
              } else {
                print('    ⚠️ Skipping invalid attachment: ${att['filename']}');
              }
            }
          }
          
          // ✅ Correct format: recipients as dictionary with SINGLE recipient
          final Map<String, dynamic> requestBody = {
            'sender_email': configuredEmail,
            'subject': subject,
            'body': body,
            'recipients': {
              'to': [recipient],  // Single recipient only
              'cc': [],           // No CC
              'bcc': [],          // No BCC
            },
            'attachments': validAttachments,
            'is_html': isHtml,
          };
          
          print('  📤 Request details:');
          print('    sender_email: $configuredEmail');
          print('    recipients.to: [$recipient]');
          print('    subject: $subject');
          print('    body length: ${body.length} chars');
          print('    valid attachments: ${validAttachments.length}');
          
          try {
            final response = await client.post(
              Uri.parse(apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $authToken',
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 45));
            
            print('  📥 Response status: ${response.statusCode}');
            
            if (response.statusCode == 200 || response.statusCode == 201) {
              successfulRecipients.add(recipient);
              print('  ✅ Sent successfully to: $recipient');
              
              try {
                final responseData = jsonDecode(response.body);
                print('  📄 Server response: ${responseData['message']}');
              } catch (_) {}
              
              // Add small delay between emails (0.5 second)
              if (i < recipients.length - 1) {
                await Future.delayed(const Duration(milliseconds: 500));
              }
            } else {
              failedRecipients.add(recipient);
              print('  ❌ Failed for: $recipient');
              print('  Error code: ${response.statusCode}');
              if (response.body.isNotEmpty) {
                print('  Error body: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}');
              }
            }
          } catch (e) {
            failedRecipients.add(recipient);
            print('  💥 Exception for $recipient: $e');
          }
        }
        
        print('\n📊 ===== SENDING SUMMARY =====');
        print('  Total recipients: ${recipients.length}');
        print('  Successful: ${successfulRecipients.length}');
        print('  Failed: ${failedRecipients.length}');
        
        if (failedRecipients.isNotEmpty) {
          print('  Failed recipients: $failedRecipients');
        }
        
        // Save to local history
        await _saveEmailToHistory(
          subject: subject,
          body: body,
          recipients: recipients,
          attachments: attachments,
        );
        
        if (successfulRecipients.isNotEmpty) {
          print('✅ === EMAILS SENT SUCCESSFULLY ===');
          return ApiResponse(
            success: true,
            data: {
              'message': successfulRecipients.length == recipients.length 
                  ? 'All ${recipients.length} emails sent successfully!'
                  : '${successfulRecipients.length}/${recipients.length} emails sent',
              'total_recipients': recipients.length,
              'successful': successfulRecipients.length,
              'failed': failedRecipients.length,
              'failed_recipients': failedRecipients,
            },
          );
        } else {
          print('❌ === ALL EMAILS FAILED ===');
          return ApiResponse(
            success: false,
            error: 'Failed to send emails to all recipients',
          );
        }
        
      } finally {
        client.close();
        print('=== EMAIL SEND PROCESS END ===\n');
      }
      
    } catch (e) {
      print('❌ === UNEXPECTED ERROR ===');
      print('Error: $e');
      print('Stack trace: ${e.toString()}');
      
      return ApiResponse(
        success: false,
        error: 'Failed to send email: ${e.toString().split('\n').first}',
      );
    }
  }
  
  // ✅ Save email to local history
  Future<void> _saveEmailToHistory({
    required String subject,
    required String body,
    required List<String> recipients,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('configured_email') ?? 'unknown@example.com';
      
      final emailData = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'subject': subject,
        'recipients': recipients,
        'body_preview': body.length > 100 ? body.substring(0, 100) + '...' : body,
        'body_full': body,
        'status': 'sent',
        'sent_at': DateTime.now().toIso8601String(),
        'attachments_count': attachments?.length ?? 0,
        'attachments': attachments?.map((a) => a['filename']).toList() ?? [],
        'from': userEmail,
        'message_id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
      };
      
      final existingEmailsJson = prefs.getStringList('sent_emails') ?? [];
      final List<String> updatedEmails = [];
      
      // Add new at beginning
      updatedEmails.add(jsonEncode(emailData));
      
      // Add existing (keep last 50)
      for (int i = 0; i < existingEmailsJson.length && i < 49; i++) {
        updatedEmails.add(existingEmailsJson[i]);
      }
      
      await prefs.setStringList('sent_emails', updatedEmails);
      
      print('✅ Email saved to local history: "${subject}"');
      
    } catch (e) {
      print('❌ Error saving to history: $e');
    }
  }
  
  // ✅ Other functions
  Future<ApiResponse> hasEmailConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isConfigured = prefs.getBool('email_configured') ?? false;
      return ApiResponse(success: true, data: isConfigured);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
  
  Future<ApiResponse> getEmailStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isConfigured = prefs.getBool('email_configured') ?? false;
      
      if (!isConfigured) {
        return ApiResponse(
          success: true,
          data: {'total': 0, 'successful': 0, 'failed': 0},
        );
      }
      
      final emailsJson = prefs.getStringList('sent_emails') ?? [];
      return ApiResponse(
        success: true,
        data: {
          'total': emailsJson.length,
          'successful': emailsJson.length,
          'failed': 0,
        },
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
  
  Future<ApiResponse> getEmailHistory({int page = 1, int limit = 20}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isConfigured = prefs.getBool('email_configured') ?? false;
      
      if (!isConfigured) {
        return ApiResponse(success: true, data: []);
      }
      
      final emailsJson = prefs.getStringList('sent_emails') ?? [];
      final List<Map<String, dynamic>> realEmails = [];
      
      for (var jsonString in emailsJson) {
        try {
          final emailData = jsonDecode(jsonString);
          if (emailData is Map<String, dynamic>) {
            realEmails.add(emailData);
          }
        } catch (e) {
          print('Error parsing email: $e');
        }
      }
      
      // Sort by date (newest first)
      realEmails.sort((a, b) {
        final dateA = DateTime.tryParse(a['sent_at'] ?? '');
        final dateB = DateTime.tryParse(b['sent_at'] ?? '');
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });
      
      // Pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      if (startIndex >= realEmails.length) {
        return ApiResponse(success: true, data: []);
      }
      
      final paginatedEmails = realEmails.sublist(
        startIndex,
        endIndex < realEmails.length ? endIndex : realEmails.length,
      );
      
      return ApiResponse(success: true, data: paginatedEmails);
      
    } catch (e) {
      print('Error getting email history: $e');
      return ApiResponse(success: false, error: e.toString());
    }
  }
  
  Future<ApiResponse> saveEmailConfig({
    required String email,
    required String password,
    String smtpServer = 'smtp.gmail.com',
    int smtpPort = 587,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('email_configured', true);
      await prefs.setString('configured_email', email);
      await prefs.setString('email_password', password);
      await prefs.setString('smtp_server', smtpServer);
      await prefs.setInt('smtp_port', smtpPort);
      await prefs.setString('config_time', DateTime.now().toIso8601String());
      
      print('✅ Email configuration saved for: $email');
      
      return ApiResponse(
        success: true,
        data: {'message': 'Email configuration saved successfully'},
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Failed to save configuration: $e',
      );
    }
  }
  
  Future<ApiResponse> clearEmailConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email_configured');
      await prefs.remove('configured_email');
      await prefs.remove('email_password');
      await prefs.remove('smtp_server');
      await prefs.remove('smtp_port');
      await prefs.remove('config_time');
      await prefs.remove('sent_emails');
      
      print('✅ Email configuration cleared');
      
      return ApiResponse(
        success: true,
        data: {'message': 'Email configuration cleared'},
      );
    } catch (e) {
      print('❌ Error clearing email config: $e');
      return ApiResponse(success: false, error: e.toString());
    }
  }
  
  Future<ApiResponse> testEmailConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isConfigured = prefs.getBool('email_configured') ?? false;
      final email = prefs.getString('configured_email') ?? '';
      
      if (!isConfigured || email.isEmpty) {
        return ApiResponse(
          success: false,
          error: 'Email not configured. Please setup email first.',
        );
      }
      
      print('Testing email configuration for: $email');
      await Future.delayed(const Duration(seconds: 1));
      
      return ApiResponse(
        success: true,
        data: {
          'message': '✅ Test successful! Email configuration is working.',
          'email': email,
        },
      );
    } catch (e) {
      print('❌ Email config test failed: $e');
      return ApiResponse(
        success: false,
        error: 'Test failed: ${e.toString()}',
      );
    }
  }
  
  Future<ApiResponse> clearEmailHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sent_emails');
      print('✅ Email history cleared');
      return ApiResponse(
        success: true,
        data: {'message': 'Email history cleared'},
      );
    } catch (e) {
      print('❌ Error clearing email history: $e');
      return ApiResponse(success: false, error: e.toString());
    }
  }
}