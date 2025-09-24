import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _otpSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await _authService.sendEmailOTP(
          _emailController.text,
          'login',
        );

        setState(() {
          _isLoading = false;
          if (result?['success'] == true) {
            _otpSent = true;
          } else {
            _errorMessage =
                result?['message'] ?? 'Failed to send OTP. Please try again.';
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
      });

      try {
        final result = await _authService.verifyEmailOTP(
          _emailController.text,
          _otpController.text,
          'login',
        );

        setState(() {
          _isLoading = false;
        });

        if (result?['success'] == true) {
          final data = result?['data'];

          // Check if user needs to complete registration
          if (data?['requiresRegistration'] == true) {
            // Redirect to registration screen with userId
            if (mounted) {
              context.go(
                '/registration?userId=${data['userId']}&email=${data['email']}',
              );
            }
          } else if (data?['user'] != null) {
            // User already registered, redirect to home
            if (mounted) {
              context.go('/home');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email OTP Login'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // If we can go back in the router stack, do that
            // Otherwise go to landing as fallback
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/landing');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // App logo or icon
              Icon(
                Icons.travel_explore,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                !_otpSent ? 'Login with Email OTP' : 'Enter Verification Code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                !_otpSent
                    ? 'We\'ll send a verification code to your email'
                    : 'Please enter the 6-digit code sent to\n${_emailController.text}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 30),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                enabled: !_otpSent,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // OTP field (visible only after OTP is sent)
              if (_otpSent)
                Column(
                  children: [
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                      ),
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        hintText: '000000',
                        prefixIcon: Icon(Icons.verified_user),
                        border: OutlineInputBorder(),
                        counterText: '', // Hide character counter
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the verification code';
                        }
                        if (value.length < 6) {
                          return 'Please enter the complete 6-digit code';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Action button (Send OTP or Verify OTP)
              CustomButton(
                onPressed: _isLoading
                    ? null
                    : (_otpSent ? _verifyOtp : _sendOtp),
                text: _isLoading
                    ? 'Please wait...'
                    : (_otpSent ? 'Verify OTP' : 'Send OTP'),
                isLoading: _isLoading,
              ),

              const SizedBox(height: 20),

              // Alternative login options
              if (!_otpSent)
                Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => context.go('/auth'),
                      icon: const Icon(Icons.login),
                      label: const Text('Use Other Login Options'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
