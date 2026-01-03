import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:premium_email_app/providers/auth_provider.dart';
import 'package:premium_email_app/core/constants/app_colors.dart';
import 'package:premium_email_app/core/services/email_service.dart';
import 'package:premium_email_app/widgets/common/primary_button.dart';
import 'package:premium_email_app/screens/email/email_setup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EmailService _emailService = EmailService();
  bool _hasEmailConfig = false;
  String _configuredEmail = '';
  int _totalEmails = 0;
  int _successfulEmails = 0;
  double _successRate = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    try {
      // Load email configuration from SharedPreferences
      await _loadEmailConfiguration();
      
      // Load email statistics
      await _loadEmailStatistics();
      
      // Ensure AuthProvider has user data loaded
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        await authProvider.loadCurrentUser();
      }
      
      // Add small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 200));
      
    } catch (error) {
      print('Dashboard initialization error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmailConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isConfigured = prefs.getBool('email_configured') ?? false;
      final savedEmail = prefs.getString('configured_email') ?? '';
      
      setState(() {
        _hasEmailConfig = isConfigured;
        _configuredEmail = savedEmail;
      });

      // Optional: Verify configuration from API
      final apiResponse = await _emailService.hasEmailConfig();
      if (apiResponse.success && apiResponse.data != null) {
        setState(() {
          _hasEmailConfig = apiResponse.data as bool;
        });
      }
    } catch (error) {
      print('Error loading email configuration: $error');
    }
  }

  Future<void> _loadEmailStatistics() async {
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
    } catch (error) {
      print('Error loading email statistics: $error');
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
    });
    await _initializeDashboard();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String? subtitle) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (title == 'Success Rate')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _successRate >= 90 ? Colors.green.withOpacity(0.1) :
                           _successRate >= 70 ? Colors.orange.withOpacity(0.1) :
                           Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _successRate >= 90 ? 'Excellent' :
                    _successRate >= 70 ? 'Good' : 'Needs Work',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _successRate >= 90 ? Colors.green :
                             _successRate >= 70 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: (MediaQuery.of(context).size.width - 56) / 2,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      final firstInitial = nameParts[0].isNotEmpty ? nameParts[0][0] : '';
      final lastInitial = nameParts.last.isNotEmpty ? nameParts.last[0] : '';
      return '${firstInitial.toUpperCase()}${lastInitial.toUpperCase()}';
    }
    
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Get user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    // User information with proper fallbacks
    String userName = 'User';
    String userEmail = 'No email';
    String userInitials = 'U';
    
    if (user != null) {
      userName = user.name; // Yeh required field hai aapke User model mein
      userEmail = user.email; // Yeh bhi required field hai
      userInitials = _getUserInitials(userName);
    } else {
      // Show loading state if user is not loaded yet
      userName = 'Loading...';
      userEmail = 'Loading...';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _refreshDashboard,
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Welcome Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        // User Avatar Circle
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              userInitials,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // User Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
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

                  const SizedBox(height: 24),

                  // Email Statistics Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Email Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Icon(Icons.analytics, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Statistics Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.05,
                    children: [
                      _buildStatCard(
                        'Total Emails',
                        '$_totalEmails',
                        Icons.email_outlined,
                        Colors.blue,
                        null,
                      ),
                      _buildStatCard(
                        'Successful',
                        '$_successfulEmails',
                        Icons.check_circle_outline,
                        Colors.green,
                        null,
                      ),
                      _buildStatCard(
                        'Success Rate',
                        '${_successRate.toStringAsFixed(1)}%',
                        Icons.trending_up,
                        Colors.purple,
                        null,
                      ),
                      _buildStatCard(
                        _hasEmailConfig ? 'Configured' : 'Setup',
                        _hasEmailConfig ? 'Ready' : 'Required',
                        _hasEmailConfig ? Icons.check_circle : Icons.warning,
                        _hasEmailConfig ? Colors.teal : Colors.orange,
                        _configuredEmail.isNotEmpty 
                          ? _configuredEmail 
                          : (_hasEmailConfig ? 'Email configured' : 'Not configured'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Email Setup Status
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _hasEmailConfig 
                          ? Colors.green.withOpacity(0.05) 
                          : Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _hasEmailConfig 
                            ? Colors.green.withOpacity(0.2) 
                            : Colors.orange.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _hasEmailConfig 
                                    ? Colors.green.withOpacity(0.1) 
                                    : Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _hasEmailConfig ? Icons.check_circle : Icons.settings,
                                color: _hasEmailConfig ? Colors.green : Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _hasEmailConfig 
                                    ? 'Email Configuration Complete' 
                                    : 'Email Setup Required',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _hasEmailConfig ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (_hasEmailConfig && _configuredEmail.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.email, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _configuredEmail,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        Text(
                          _hasEmailConfig
                              ? 'Your email is configured and ready to use. You can send emails immediately.'
                              : 'Setup your email configuration to start sending professional emails.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            text: _hasEmailConfig 
                                ? 'View/Update Configuration' 
                                : 'Setup Email Configuration',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmailSetupScreen(),
                                ),
                              ).then((_) {
                                _refreshDashboard();
                              });
                            },
                            icon: _hasEmailConfig ? Icons.edit : Icons.arrow_forward,
                            backgroundColor: _hasEmailConfig ? Colors.teal : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Icon(Icons.flash_on, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.05,
                    children: [
                      _buildActionCard(
                        'Compose',
                        'Write new email',
                        Icons.edit,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/compose-email'),
                      ),
                      _buildActionCard(
                        'History',
                        'View sent emails',
                        Icons.history,
                        Colors.purple,
                        () => Navigator.pushNamed(context, '/email-history'),
                      ),
                      _buildActionCard(
                        'Profile',
                        'Manage account',
                        Icons.person,
                        Colors.orange,
                        () => Navigator.pushNamed(context, '/profile'),
                      ),
                      _buildActionCard(
                        'Settings',
                        'App preferences',
                        Icons.settings,
                        Colors.teal,
                        () => Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}