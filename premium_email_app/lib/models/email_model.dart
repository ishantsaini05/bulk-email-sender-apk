import 'package:flutter/material.dart';

class Email {
  final int id;
  final String subject;
  final List<String> recipients;
  final String bodyPreview;
  final String status;
  final DateTime sentAt;
  final int attachmentsCount;
  final String? messageId;
  final String? errorMessage;

  Email({
    required this.id,
    required this.subject,
    required this.recipients,
    required this.bodyPreview,
    required this.status,
    required this.sentAt,
    this.attachmentsCount = 0,
    this.messageId,
    this.errorMessage,
  });

  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      subject: json['subject'] ?? '',
      recipients: List<String>.from(json['recipients'] is String 
          ? (json['recipients'] as String).split(',')
          : json['recipients'] ?? []),
      bodyPreview: json['body_preview'] ?? json['body']?.substring(0, 100) ?? '',
      status: json['status'] ?? 'unknown',
      sentAt: DateTime.parse(json['created_at'] ?? json['sent_at'] ?? DateTime.now().toString()),
      attachmentsCount: json['attachments_count'] ?? 0,
      messageId: json['message_id'],
      errorMessage: json['error_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'recipients': recipients,
      'body_preview': bodyPreview,
      'status': status,
      'sent_at': sentAt.toIso8601String(),
      'attachments_count': attachmentsCount,
      'message_id': messageId,
      'error_message': errorMessage,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(sentAt);
    
    if (difference.inDays > 7) {
      return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'sent':
      case 'success':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color get statusColor {
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
}

class EmailRecipient {
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;

  EmailRecipient({
    required this.to,
    this.cc = const [],
    this.bcc = const [],
  });

  factory EmailRecipient.fromJson(Map<String, dynamic> json) {
    return EmailRecipient(
      to: List<String>.from(json['to'] ?? []),
      cc: List<String>.from(json['cc'] ?? []),
      bcc: List<String>.from(json['bcc'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'to': to,
      'cc': cc,
      'bcc': bcc,
    };
  }

  List<String> get allRecipients => [...to, ...cc, ...bcc];
}

class EmailAttachment {
  final String filename;
  final String contentType;
  final String base64Content;
  final int sizeInBytes;
  final String? filePath;

  EmailAttachment({
    required this.filename,
    required this.contentType,
    required this.base64Content,
    required this.sizeInBytes,
    this.filePath,
  });

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      filename: json['filename'],
      contentType: json['content_type'],
      base64Content: json['base64_content'],
      sizeInBytes: json['size_in_bytes'],
      filePath: json['file_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'content_type': contentType,
      'base64_content': base64Content,
      'size_in_bytes': sizeInBytes,
      'file_path': filePath,
    };
  }

  String get fileExtension {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get isImage {
    return contentType.startsWith('image/') || 
           ['.jpg', '.jpeg', '.png', '.gif', '.bmp'].contains(fileExtension);
  }

  bool get isPdf {
    return contentType == 'application/pdf' || fileExtension == 'pdf';
  }

  bool get isDocument {
    return contentType.startsWith('application/') || 
           ['.doc', '.docx', '.txt', '.rtf'].contains(fileExtension);
  }
}