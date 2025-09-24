import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/tour_raksha_logo.dart';

class AuthScreen extends StatefulWidget {
  final String? initialType; // 'login' or 'register'
  
  const AuthScreen({
    super.key, 
    this.initialType,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  late TabController _tabController;
  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;
  String? _successMessage;
  String _currentType = 'register'; // 'register' or 'login'

  @override
  void initState() {
    super.initState();
    
    // Set initial type based on parameter
    _currentType = widget.initialType ?? 'register';
    print('AuthScreen: initialType = ${widget.initialType}, _currentType = $_currentType');
    
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: _currentType == 'login' ? 1 : 0,
    );
    
    print('AuthScreen: TabController initialIndex = ${_tabController.index}');
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newType = _tabController.index == 0 ? 'register' : 'login';
        if (newType != _currentType) {
          setState(() {
            _currentType = newType;
            _resetForm();
          });
          print('AuthScreen: Tab changed to $_currentType');
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _emailController.clear();
    _otpController.clear();
    _otpSent = false;
    _errorMessage = null;
    _successMessage = null;
    _isLoading = false;
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        final result = await _authService.sendEmailOTP(
          _emailController.text.trim(),
          _currentType,
        );

        setState(() {
          _isLoading = false;
          if (result?['success'] == true) {
            _otpSent = true;
            _successMessage =
                result?['message'] ??
                'OTP sent successfully! Please check your email.';
          } else {
            _errorMessage = result?['message'] ?? 'Failed to send OTP';
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        final result = await _authService.verifyEmailOTP(
          _emailController.text.trim(),
          _otpController.text.trim(),
          _currentType,
        );

        setState(() {
          _isLoading = false;
        });

        if (result?['success'] == true) {
          final data = result?['data'];

          if (_currentType == 'register' &&
              data?['requiresRegistration'] == true) {
            // Debug: Print user data
            print('OTP Verification result: $result');
            print('User data: $data');
            print('User ID: ${data?['userId']}');
            
            // Add more specific debugging
            if (data == null) {
              print('ERROR: data is null from OTP verification');
              setState(() {
                _errorMessage = 'Registration failed: No user data received. Please try again.';
              });
              return;
            }
            
            if (data['userId'] == null) {
              print('ERROR: userId is null in data: $data');
              setState(() {
                _errorMessage = 'Registration failed: User ID not received. Please try again.';
              });
              return;
            }

            // Redirect to registration screen
            if (mounted) {
              context.pushReplacement('/registration?userId=${data['userId']}&email=${Uri.encodeComponent(data['email'])}');
            }
          } else if (_currentType == 'login' && data?['user'] != null) {
            // Redirect to home screen
            if (mounted) {
              context.pushReplacement('/home');
            }
          }
        } else {
          setState(() {
            _errorMessage =
                result?['message'] ?? 'Invalid OTP. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Welcome to TourRaksha'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(text: 'Sign Up'),
            Tab(text: 'Login'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAuthForm('Create Account'),
          _buildAuthForm('Welcome Back'),
        ],
      ),
    );
  }

  Widget _buildAuthForm(String title) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Logo
            const Center(child: TourRakshaLogo(size: 100, showText: false)),

            const SizedBox(height: 32),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              _currentType == 'register'
                  ? 'Enter your email to get started with TourRaksha'
                  : 'Enter your email to access your account',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Email Input
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_otpSent && !_isLoading,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // OTP Input (shown after OTP is sent)
            if (_otpSent) ...[
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'OTP is required';
                  }
                  if (value.length != 6) {
                    return 'OTP must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],

            // Success Message
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action Button
            CustomButton(
              text: _isLoading
                  ? 'Processing...'
                  : _otpSent
                  ? 'Verify OTP'
                  : 'Send OTP',
              onPressed: _isLoading
                  ? null
                  : _otpSent
                  ? _verifyOtp
                  : _sendOtp,
              isLoading: _isLoading,
            ),

            // Resend OTP option
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _otpSent = false;
                          _otpController.clear();
                          _errorMessage = null;
                          _successMessage = null;
                        });
                      },
                child: const Text('Didn\'t receive OTP? Send again'),
              ),
            ],

            const SizedBox(height: 40),

            // Additional info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.security, color: Colors.blue[600], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Secure Authentication',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We use email-based OTP verification to ensure your account security.',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
