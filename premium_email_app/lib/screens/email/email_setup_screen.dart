import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:premium_email_app/providers/email_provider.dart';
import 'package:premium_email_app/core/constants/app_colors.dart';
import 'package:premium_email_app/widgets/common/custom_text_field.dart';
import 'package:premium_email_app/widgets/common/primary_button.dart';
import 'package:premium_email_app/widgets/common/loading_overlay.dart';
import 'package:premium_email_app/core/utils/helpers.dart';

class EmailSetupScreen extends StatefulWidget {
  final VoidCallback? onSetupComplete;

  const EmailSetupScreen({super.key, this.onSetupComplete});

  @override
  State<EmailSetupScreen> createState() => _EmailSetupScreenState();
}

class _EmailSetupScreenState extends State<EmailSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _selectedProvider = 'gmail';
  bool _isLoading = false;
  bool _showPassword = false;
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkExistingConfig();
  }

  // ✅ Check if email is already configured - FIXED
  Future<void> _checkExistingConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final isConfigured = prefs.getBool('email_configured') ?? false;
    
    if (isConfigured && mounted) {
      setState(() {
        _isConfigured = true;
      });
      
      // Load saved email
      final savedEmail = prefs.getString('configured_email');
      if (savedEmail != null) {
        _emailController.text = savedEmail;
      }
      
      // ✅ FIXED: Remove automatic callback
      // This was causing automatic navigation
      // if (widget.onSetupComplete != null) {
      //   Future.delayed(Duration.zero, () {
      //     widget.onSetupComplete!();
      //   });
      // }
    }
  }

  // ✅ Save configuration PERMANENTLY - FIXED
  Future<void> _saveEmailConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Save to SharedPreferences (Permanent storage)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('email_configured', true);
      await prefs.setString('configured_email', _emailController.text.trim());
      await prefs.setString('email_provider', _selectedProvider);
      await prefs.setString('config_timestamp', DateTime.now().toIso8601String());

      // 2. Save to Provider/Backend
      final provider = Provider.of<EmailProvider>(context, listen: false);
      
      await provider.setupEmailConfig(
        emailAddress: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        smtpServer: _getSmtpServer(),
        smtpPort: _getSmtpPort(),
      );

      if (provider.configError == null) {
        setState(() {
          _isConfigured = true;
        });
        
        // ✅ FIXED: Show success message but don't auto-navigate
        Helpers.showSnackbar(context, '✅ Email configured successfully!');
        
        // ✅ FIXED: Only navigate back when user clicks back button
        // Do NOT auto-navigate
        // Future.delayed(const Duration(milliseconds: 1500), () {
        //   if (widget.onSetupComplete != null) {
        //     widget.onSetupComplete!();
        //   }
        //   if (mounted) {
        //     Navigator.pop(context);
        //   }
        // });
      } else {
        Helpers.showSnackbar(context, provider.configError!, isError: true);
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getSmtpServer() {
    switch (_selectedProvider) {
      case 'gmail': return 'smtp.gmail.com';
      case 'outlook': return 'smtp-mail.outlook.com';
      case 'yahoo': return 'smtp.mail.yahoo.com';
      default: return 'smtp.gmail.com';
    }
  }

  int _getSmtpPort() => 587;

  Future<void> _openAppPasswordGuide() async {
    final url = Uri.parse('https://myaccount.google.com/apppasswords');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        Helpers.showSnackbar(context, 'Cannot open the link', isError: true);
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error opening link: $e', isError: true);
    }
  }

  Widget _buildProviderOption(String provider, String title, IconData icon) {
    final isSelected = _selectedProvider == provider;
    return GestureDetector(
      onTap: () => setState(() => _selectedProvider = provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Show setup form even if already configured
    // This allows users to reconfigure if needed
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Email Setup'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          actions: [
            // Add a back button with callback
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // Call callback if exists
                if (widget.onSetupComplete != null) {
                  widget.onSetupComplete!();
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ FIXED: Show status message if already configured
                if (_isConfigured)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Already Configured',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                              if (_emailController.text.isNotEmpty)
                                Text(
                                  _emailController.text,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mail, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Configure your email to start sending',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Provider Selection
                const Text(
                  'Select Provider',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                _buildProviderOption('gmail', 'Gmail', Icons.mail),
                const SizedBox(height: 8),
                _buildProviderOption('outlook', 'Outlook', Icons.business),
                const SizedBox(height: 8),
                _buildProviderOption('yahoo', 'Yahoo', Icons.email),

                const SizedBox(height: 24),

                // Email Configuration
                const Text(
                  'Email Credentials',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email address is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  labelText: 'App Password',
                  hintText: '16-character app password',
                  prefixIcon: const Icon(Icons.lock),
                  obscureText: !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'App password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // App Password Guide
                GestureDetector(
                  onTap: _openAppPasswordGuide,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need App Password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Generate Google App Password here',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: _isConfigured ? 'Update Configuration' : 'Save Configuration',
                    onPressed: _saveEmailConfig,
                    isLoading: _isLoading,
                    backgroundColor: _isConfigured ? Colors.green : AppColors.primary,
                    icon: _isConfigured ? Icons.update : Icons.save,
                  ),
                ),

                const SizedBox(height: 20),

                // Important Notes
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Important Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Configuration is saved permanently\n'
                        '• Use App Password, not your regular password\n'
                        '• Enable 2FA in your Google Account first\n'
                        '• You can send emails immediately after setup',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // ✅ FIXED: Add a clear configuration button
                if (_isConfigured) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Configuration?'),
                            content: const Text('This will remove your email configuration. You will need to set it up again.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Clear', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('email_configured');
                          await prefs.remove('configured_email');
                          await prefs.remove('email_provider');
                          
                          setState(() {
                            _isConfigured = false;
                            _emailController.clear();
                            _passwordController.clear();
                          });
                          
                          Helpers.showSnackbar(context, 'Configuration cleared');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Clear Configuration',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        // ✅ FIXED: Add floating action button to go back
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () {
            // Call callback if exists
            if (widget.onSetupComplete != null) {
              widget.onSetupComplete!();
            }
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}