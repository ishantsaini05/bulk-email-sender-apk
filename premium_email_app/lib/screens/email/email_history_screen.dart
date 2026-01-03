import 'package:flutter/material.dart';
import 'package:premium_email_app/core/constants/app_colors.dart';
import 'package:premium_email_app/core/services/email_service.dart';
import 'package:premium_email_app/core/utils/helpers.dart';
import 'package:premium_email_app/widgets/common/loading_overlay.dart';
import 'package:premium_email_app/widgets/email/email_card.dart';

class EmailHistoryScreen extends StatefulWidget {
  const EmailHistoryScreen({super.key});

  @override
  State<EmailHistoryScreen> createState() => _EmailHistoryScreenState();
}

class _EmailHistoryScreenState extends State<EmailHistoryScreen> {
  final EmailService _emailService = EmailService();
  final List<Map<String, dynamic>> _emails = [];
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isRefreshing = false;
  int _page = 1;
  final int _limit = 20;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  Future<void> _loadEmails() async {
    if (!_hasMore) return;

    try {
      final response = await _emailService.getEmailHistory(page: _page, limit: _limit);

      if (response.success && response.data != null) {
        final newEmails = response.data as List<dynamic>;
        
        setState(() {
          for (var email in newEmails) {
            if (email is Map<String, dynamic>) {
              _emails.add(email);
            }
          }
          _hasMore = newEmails.length >= _limit;
          _page++;
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = response.error ?? 'Failed to load emails';
        });
      }
    } catch (e) {
      print('Error loading emails: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = 'Network error. Please try again.';
      });
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
      _emails.clear();
      _page = 1;
      _hasMore = true;
      _errorMessage = null;
    });
    
    await _loadEmails();
  }

  void _retryLoad() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    _loadEmails();
  }

  Widget _buildEmailList() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryLoad,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_emails.isEmpty && !_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.email_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No emails yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send your first email to see history here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/compose-email');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Compose Email',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emails.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _emails.length) {
          return _hasMore
              ? Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Text(
                      'No more emails',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
        }

        final emailMap = _emails[index];
        
        return EmailCard(
          email: emailMap,
          onTap: () {
            _showEmailDetails(emailMap);
          },
        );
      },
    );
  }

  void _showEmailDetails(Map<String, dynamic> emailMap) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        emailMap['subject'] ?? 'No Subject',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(emailMap['status'] ?? '').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (emailMap['status'] ?? 'unknown').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(emailMap['status'] ?? ''),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                _buildDetailRow(Icons.person, 'From:', emailMap['from'] ?? 'Unknown Sender'),
                
                const SizedBox(height: 12),
                
                _buildDetailRow(Icons.email, 'To:', _formatRecipients(emailMap['recipients'])),
                
                const SizedBox(height: 12),
                
                if (emailMap['cc'] != null && (emailMap['cc'] as List).isNotEmpty)
                  _buildDetailRow(Icons.copy, 'CC:', _formatRecipients(emailMap['cc'])),
                
                if (emailMap['bcc'] != null && (emailMap['bcc'] as List).isNotEmpty)
                  _buildDetailRow(Icons.visibility_off, 'BCC:', _formatRecipients(emailMap['bcc'])),
                
                const SizedBox(height: 12),
                
                _buildDetailRow(Icons.access_time, 'Sent:', _formatDateTime(emailMap['sent_at'] ?? '')),
                
                const SizedBox(height: 12),
                
                if (emailMap['attachments'] != null && (emailMap['attachments'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_file, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 10),
                          Text(
                            'Attachments (${emailMap['attachments_count'] ?? 0}):',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: (emailMap['attachments'] as List<dynamic>).map<Widget>((attachment) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color.fromARGB(255, 160, 212, 255)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.insert_drive_file, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    attachment.toString(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                
                const SizedBox(height: 20),
                
                if (emailMap['body_full'] != null && emailMap['body_full'].toString().isNotEmpty) ...[
                  const Text(
                    'Message:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color.fromARGB(255, 216, 216, 216)),
                    ),
                    child: Text(
                      emailMap['body_full'].toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${emailMap['body_full'].toString().length} characters',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else if (emailMap['body_preview'] != null && emailMap['body_preview'].toString().isNotEmpty) ...[
                  const Text(
                    'Message Preview:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color.fromARGB(255, 197, 197, 197)),
                    ),
                    child: Text(
                      emailMap['body_preview'].toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                
                const SizedBox(height: 30),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _replyToEmail(emailMap);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                        child: const Text('Reply'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _replyToEmail(Map<String, dynamic> emailMap) {
    Navigator.pushNamed(
      context,
      '/compose-email',
      arguments: {
        'subject': 'Re: ${emailMap['subject']}',
        'to': [emailMap['from']],
        'body': '\n\n--- Original Message ---\n${emailMap['body_full'] ?? emailMap['body_preview']}',
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String dateString) {
    try {
      if (dateString.isEmpty) return 'Unknown';
      
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final emailDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (emailDate == today) {
        return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (emailDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _formatRecipients(dynamic recipients) {
    if (recipients == null) return 'No recipients';
    
    if (recipients is List) {
      return recipients.join(', ');
    }
    
    return recipients.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Email History'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading && _emails.isEmpty,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: _buildEmailList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/compose-email');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}