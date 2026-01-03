import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:premium_email_app/core/constants/app_colors.dart';
import 'package:premium_email_app/core/utils/helpers.dart';
import 'package:premium_email_app/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  
  // Constants
  static const String upiId = '9625254286@ptsbi';
  static const String whatsappNumber = '+919625254286';
  static const String supportEmail = 'ishantsaini140588@gmail.com';
  
  Future<void> _openPrivacyPolicy() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We respect your privacy and protect your personal data. We collect minimal information for app functionality only. We never share your data with third parties. Your emails remain secure and confidential. We use encryption to protect all communications. You can delete your data anytime.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTerms() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'By using this app, you agree to our terms. The app is provided "as is" without warranties. We are not responsible for email delivery issues. Users must not send spam or illegal content. We may update terms without notice. Continued use means acceptance of changes.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: EMAIL SUPPORT WITH MULTIPLE OPTIONS
  Future<void> _openSupport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose how you want to contact support:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              // Email directly option
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Open Email App'),
                subtitle: const Text('Recommended if you have Gmail/Outlook'),
                onTap: () async {
                  Navigator.pop(context);
                  await _launchEmailApp();
                },
              ),
              
              const Divider(),
              
              // Copy email option
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.green),
                title: const Text('Copy Email Address'),
                subtitle: const Text('Copy to clipboard and paste manually'),
                onTap: () async {
                  Navigator.pop(context);
                  await Clipboard.setData(ClipboardData(text: supportEmail));
                  Helpers.showSnackbar(
                    context, 
                    '✅ Email copied: $supportEmail'
                  );
                },
              ),
              
              const Divider(),
              
              // Gmail Web option
              ListTile(
                leading: const Icon(Icons.language, color: Colors.red),
                title: const Text('Open Gmail Web'),
                subtitle: const Text('Use Gmail in browser'),
                onTap: () async {
                  Navigator.pop(context);
                  final url = Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&to=$supportEmail&su=Support%20Request&body=Hello,%20I%20need%20help%20with...');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    Helpers.showSnackbar(context, 'Cannot open browser', isError: true);
                  }
                },
              ),
              
              const SizedBox(height: 10),
              const Text(
                'Support Email:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              SelectableText(
                supportEmail,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Try multiple email URI formats
  Future<void> _launchEmailApp() async {
    final List<Uri> emailUris = [
      // Try different mailto formats
      Uri.parse('mailto:$supportEmail?subject=Support Request&body=Hello, I need help with...'),
      Uri.parse('mailto:$supportEmail'),
      // For Gmail directly
      Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&to=$supportEmail&su=Support%20Request&body=Hello,%20I%20need%20help%20with...'),
    ];
    
    bool launched = false;
    
    for (final uri in emailUris) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          launched = true;
          break;
        }
      } catch (e) {
        print('Failed to launch URI: $uri, error: $e');
        continue;
      }
    }
    
    if (!launched) {
      // If all methods fail, show dialog with copy option
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Email App Found'),
          content: const Text(
            'No email app is configured on your device.\n\nPlease copy the email address and contact us manually.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: supportEmail));
                Helpers.showSnackbar(
                  context, 
                  '✅ Email copied: $supportEmail'
                );
              },
              child: const Text('Copy Email'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final whatsappUrl = 'https://wa.me/$whatsappNumber?text=Hello%20Ishant,%20I%20need%20help%20with...';
    final url = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Copy WhatsApp number if can't open
      await Clipboard.setData(ClipboardData(text: whatsappNumber));
      Helpers.showSnackbar(
        context, 
        'WhatsApp not installed. Number copied: $whatsappNumber'
      );
    }
  }

  Future<void> _openUPIApp() async {
    // Paytm specific UPI URL
    final upiUrl = 'upi://pay?pa=$upiId&pn=Ishant%20Saini&mc=0000&mode=02&purpose=00';
    final url = Uri.parse(upiUrl);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Agar UPI app nahi khuli toh copy UPI ID
      await _copyUPIId();
    }
  }

  Future<void> _copyUPIId() async {
    await Clipboard.setData(ClipboardData(text: upiId));
    Helpers.showSnackbar(context, '✅ UPI ID copied to clipboard: $upiId');
  }

  Future<void> _openDonateDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support Development'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Support my work with a donation',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              // UPI ID Card
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'UPI ID:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        upiId,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Name: Ishant Saini',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '1. Copy the UPI ID above\n2. Open any UPI app (Paytm, Google Pay, PhonePe, etc.)\n3. Paste UPI ID and send donation\n4. Minimum amount: ₹10',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyUPIId,
                      icon: const Icon(Icons.copy, size: 20),
                      label: const Text('Copy UPI ID'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openUPIApp,
                      icon: const Icon(Icons.payment, size: 20),
                      label: const Text('Open UPI App'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ✅ LOGOUT FUNCTION
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.logout();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Helpers.showSnackbar(context, '✅ Logged out successfully');
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/login', 
                    (route) => false
                  );
                }
              } catch (e) {
                Helpers.showSnackbar(context, 'Logout failed: $e', isError: true);
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/login', 
                    (route) => false
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legal Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openPrivacyPolicy,
                    ),
                    
                    const Divider(),
                    
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Terms & Conditions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openTerms,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ FIXED: Support Section with better email handling
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.support_agent, color: Colors.blue),
                      title: const Text('Email Support'),
                      subtitle: const Text('ishantsaini140588@gmail.com'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openSupport, // Now opens dialog with options
                    ),
                    
                    const Divider(),
                    
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.green),
                      title: const Text('WhatsApp Support'),
                      subtitle: const Text('+91-9625254286'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: _openWhatsApp,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // App Info
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Version'),
                      subtitle: const Text('1.1.1'),
                    ),
                    
                    const Divider(),
                    
                    ListTile(
                      leading: const Icon(Icons.developer_mode),
                      title: const Text('Developer'),
                      subtitle: const Text('Made By Ishant Saini'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Donate Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support Development',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.red),
                      title: const Text('Donate via UPI'),
                      subtitle: const Text('Click to copy UPI ID or open UPI app'),
                      trailing: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: _openDonateDialog,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyUPIId,
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy UPI ID'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openUPIApp,
                            icon: const Icon(Icons.payment, size: 16),
                            label: const Text('Pay Now'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}