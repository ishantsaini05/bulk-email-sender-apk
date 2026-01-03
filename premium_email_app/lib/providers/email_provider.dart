import 'package:flutter/material.dart';
import '../core/services/email_service.dart';
import '../models/email_model.dart';

class EmailProvider extends ChangeNotifier {
  final EmailService _emailService = EmailService();
  
  // Email Configuration State
  bool _isConfigLoading = false;
  String? _configError;
  bool _hasEmailConfig = false;
  
  // Email History State
  bool _isHistoryLoading = false;
  String? _historyError;
  List<Email> _emails = [];
  
  // Send Email State
  bool _isSending = false;
  String? _sendError;
  bool _sendSuccess = false;
  
  // Getters
  bool get isConfigLoading => _isConfigLoading;
  String? get configError => _configError;
  bool get hasEmailConfig => _hasEmailConfig;
  
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyError => _historyError;
  List<Email> get emails => _emails;
  
  bool get isSending => _isSending;
  String? get sendError => _sendError;
  bool get sendSuccess => _sendSuccess;
  
  // Email Configuration Methods
  Future<void> setupEmailConfig({
    required String emailAddress,
    required String password,
    String smtpServer = 'smtp.gmail.com',
    int smtpPort = 587,
  }) async {
    _isConfigLoading = true;
    _configError = null;
    notifyListeners();
    
    try {
      // ✅ Use actual API call instead of direct method
      final response = await _emailService.saveEmailConfig(
        email: emailAddress,
        password: password,
        smtpServer: smtpServer,
        smtpPort: smtpPort,
      );
      
      if (response.success) {
        _hasEmailConfig = true;
      } else {
        _configError = response.error ?? 'Failed to save email configuration';
      }
    } catch (e) {
      _configError = e.toString();
    } finally {
      _isConfigLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> checkEmailConfig() async {
    try {
      final response = await _emailService.hasEmailConfig();
      _hasEmailConfig = response.success && (response.data == true);
    } catch (e) {
      _hasEmailConfig = false;
      _configError = e.toString();
    }
    notifyListeners();
  }
  
  Future<void> deleteEmailConfig() async {
    try {
      // Assuming there's a delete method in EmailService
      // For now, just update local state
      _hasEmailConfig = false;
    } catch (e) {
      _configError = e.toString();
    }
    notifyListeners();
  }
  
  // Email History Methods
  Future<void> loadEmailHistory({int page = 1, int limit = 20}) async {
    _isHistoryLoading = true;
    _historyError = null;
    notifyListeners();
    
    try {
      final response = await _emailService.getEmailHistory(
        page: page,
        limit: limit,
      );
      
      if (response.success && response.data != null) {
        if (page == 1) {
          _emails = response.data!;
        } else {
          _emails.addAll(response.data!);
        }
      } else {
        _historyError = response.error ?? 'Failed to load email history';
      }
    } catch (e) {
      _historyError = e.toString();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }
  
  // Send Email Methods
  Future<bool> sendEmail({
    required List<String> recipients,
    List<String>? cc,
    List<String>? bcc,
    required String subject,
    required String body,
    bool isHtml = false,
    List<Map<String, dynamic>>? attachments,
  }) async {
    _isSending = true;
    _sendError = null;
    _sendSuccess = false;
    notifyListeners();
    
    try {
      final response = await _emailService.sendEmail(
        subject: subject,
        body: body,
        recipients: recipients,
        attachments: attachments,
        isHtml: isHtml,
      );
      
      if (response.success) {
        _sendSuccess = true;
        // Reload history after sending
        await loadEmailHistory();
        return true;
      } else {
        _sendError = response.error ?? 'Failed to send email';
        return false;
      }
    } catch (e) {
      _sendError = e.toString();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
  
  // Clear errors
  void clearConfigError() {
    _configError = null;
    notifyListeners();
  }
  
  void clearHistoryError() {
    _historyError = null;
    notifyListeners();
  }
  
  void clearSendError() {
    _sendError = null;
    _sendSuccess = false;
    notifyListeners();
  }
  
  // Reset all state
  void reset() {
    _isConfigLoading = false;
    _configError = null;
    _hasEmailConfig = false;
    
    _isHistoryLoading = false;
    _historyError = null;
    _emails = [];
    
    _isSending = false;
    _sendError = null;
    _sendSuccess = false;
    
    notifyListeners();
  }
}