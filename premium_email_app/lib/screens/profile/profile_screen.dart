import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:premium_email_app/providers/auth_provider.dart';
import 'package:premium_email_app/core/constants/app_colors.dart';
import 'package:premium_email_app/core/services/email_service.dart';
import 'package:premium_email_app/widgets/common/custom_text_field.dart';
import 'package:premium_email_app/widgets/common/primary_button.dart';
import 'package:premium_email_app/core/utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final EmailService _emailService = EmailService();
  bool _isLoading = false;
  int _totalEmails = 0;
  int _successfulEmails = 0;
  double _successRate = 0.0;
  bool _isSavingPhone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadEmailStats();
    });
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
    }
    
    // Load saved phone number
    _loadSavedPhoneNumber();
  }

  Future<void> _loadSavedPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('user_phone_number');
      if (savedPhone != null && savedPhone.isNotEmpty) {
        _phoneController.text = savedPhone;
      }
    } catch (e) {
      print('Error loading phone number: $e');
    }
  }

  Future<void> _loadEmailStats() async {
    try {
      final statsResponse = await _emailService.getEmailStats();
      if (statsResponse.success && statsResponse.data != null) {
        final stats = statsResponse.data as Map<String, dynamic>;
        final total = stats['total'] is int ? stats['total'] as int : 0;
        final successful = stats['successful'] is int ? stats['successful'] as int : 0;
        
        setState(() {
          _totalEmails = total;
          _successfulEmails = successful;
          _successRate = total > 0 ? (successful / total * 100) : 0.0;
        });
      }
    } catch (e) {
      print('Error loading email stats: $e');
    }
  }

  // Save phone number and send WhatsApp message
  Future<void> _savePhoneNumber() async {
    final phoneNumber = _phoneController.text.trim();
    
    if (phoneNumber.isEmpty) {
      Helpers.showSnackbar(context, 'Please enter a phone number');
      return;
    }
    
    // Validate Indian phone number format
    if (!phoneNumber.startsWith('+91') && !phoneNumber.startsWith('91')) {
      Helpers.showSnackbar(context, 'Please enter a valid Indian phone number (starts with +91 or 91)');
      return;
    }
    
    setState(() {
      _isSavingPhone = true;
    });
    
    try {
      // Save phone number to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone_number', phoneNumber);
      
      // Prepare WhatsApp message
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final userName = user?.name ?? 'User';
      final userEmail = user?.email ?? 'No email';
      
      final message = '''
🚀 User Profile Update Notification

👤 User: $userName
📧 Email: $userEmail
📱 New Phone Number: $phoneNumber

📅 Updated: ${DateTime.now().toString()}

✅ This number has been saved in the user's profile.
      ''';
      
      // Encode message for URL
      final encodedMessage = Uri.encodeComponent(message);
      
      // Your WhatsApp number (Ishant Saini)
      final whatsappNumber = '919625254286'; // Your number without +91
      
      // Create WhatsApp URL
      final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';
      final url = Uri.parse(whatsappUrl);
      
      // Try to open WhatsApp
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        
        // Show success message after a delay
        await Future.delayed(const Duration(seconds: 2));
        Helpers.showSnackbar(context, '✅ Phone number saved and message sent to admin');
      } else {
        Helpers.showSnackbar(context, 'WhatsApp not installed. Phone number saved locally');
      }
      
    } catch (e) {
      print('Error saving phone number: $e');
      Helpers.showSnackbar(context, 'Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isSavingPhone = false;
      });
    }
  }

  Future<void> _sendProfileUpdateNotification() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (name.isEmpty && phone.isEmpty) {
      return; // Nothing to send
    }
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final userName = user?.name ?? 'User';
      final userEmail = user?.email ?? 'No email';
      
      final message = '''
🔄 User Profile Updated

👤 Previous Name: $userName
📧 Email: $userEmail

📝 Updated Information:
${name.isNotEmpty ? '• New Name: $name' : ''}
${phone.isNotEmpty ? '• New Phone: $phone' : ''}

📅 Updated: ${DateTime.now().toString()}

ℹ️ User has updated their profile information.
      '''.trim();
      
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappNumber = '919625254286';
      final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';
      final url = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Header with Stats
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // User Avatar without image upload option
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.1),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.name ?? 'User Name',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? 'user@example.com',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem('Total Emails', '$_totalEmails', Icons.email),
                            _buildStatItem('Successful', '$_successfulEmails', Icons.check_circle),
                            _buildStatItem('Success Rate', '${_successRate.toStringAsFixed(1)}%', Icons.trending_up),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Edit Profile Form
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        CustomTextField(
                          controller: _nameController,
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email),
                          readOnly: true,
                          enabled: false,
                        ),

                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _phoneController,
                          labelText: 'Phone Number',
                          hintText: '+91 9876543210',
                          prefixIcon: const Icon(Icons.phone),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (!value.contains(RegExp(r'^(\+91|91|0)?[6-9]\d{9}$'))) {
                              return 'Please enter a valid Indian phone number';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        Text(
                          'Note: Saving phone number will send a WhatsApp message to admin',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Save Changes Button
                        PrimaryButton(
                          text: 'Save Changes',
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true;
                              });
                              
                              try {
                                // Save changes locally
                                await _savePhoneNumber();
                                
                                // Send WhatsApp notification if name changed
                                final currentName = user?.name ?? '';
                                if (_nameController.text.trim() != currentName) {
                                  await _sendProfileUpdateNotification();
                                }
                                
                                Helpers.showSnackbar(context, 'Profile updated successfully');
                                
                              } catch (e) {
                                Helpers.showSnackbar(context, 'Error: ${e.toString()}', isError: true);
                              } finally {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                          isLoading: _isLoading || _isSavingPhone,
                          backgroundColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Contact Admin
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.support_agent, color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              'Contact Admin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Need help? Contact the admin directly via WhatsApp',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final message = '''
👤 User Profile Assistance Request

User: ${user?.name ?? 'Unknown'}
Email: ${user?.email ?? 'Unknown'}

📝 Request: Need help with profile update

📅 Time: ${DateTime.now().toString()}
                              '''.trim();
                              
                              final encodedMessage = Uri.encodeComponent(message);
                              final whatsappNumber = '919625254286';
                              final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';
                              final url = Uri.parse(whatsappUrl);
                              
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                Helpers.showSnackbar(context, 'WhatsApp not installed');
                              }
                            },
                            icon: const Icon(Icons.phone, size: 20),
                            label: const Text('Message Admin on WhatsApp'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Account Management
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              'Account Management',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Deleting your account will remove all your data permanently.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Helpers.showSnackbar(
                                context, 
                                'Account deletion request submitted.\nAdmin will contact you for confirmation.',
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Request Account Deletion'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    Color iconColor = AppColors.primary;
    
    // Set color based on success rate
    if (title == 'Success Rate' && _successRate > 0) {
      if (_successRate >= 90) {
        iconColor = Colors.green;
      } else if (_successRate >= 70) {
        iconColor = Colors.orange;
      } else {
        iconColor = Colors.red;
      }
    }
    
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}