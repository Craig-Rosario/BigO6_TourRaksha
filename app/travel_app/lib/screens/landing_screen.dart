import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../widgets/tour_raksha_logo.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC), // Light gray-blue background
              Color(0xFFE2E8F0), // Slightly darker
              Color(0xFFCBD5E1), // Even lighter blue-gray
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // App Logo and Title - Professional Shield Design
                Column(
                  children: [
                    // Professional Logo
                    const TourRakshaLogo(
                      size: 150,
                      showText: true,
                    ).animate().scale(
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),

                    const SizedBox(height: 24),

                    // Main title
                    Text(
                          'Smart Tourist Safety',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 6),

                    // Subtitle with brand name
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF475569),
                          fontSize: 20,
                          height: 1.3,
                        ),
                        children: [
                          const TextSpan(text: 'with '),
                          TextSpan(
                            text: 'TourRaksha',
                            style: TextStyle(
                              color: const Color(0xFF1E40AF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                        .fadeIn(duration: 600.ms, delay: 400.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                          'AI, Geo-Fencing, and Blockchain powered digital IDs to keep tourists safe in real time.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF64748B),
                            fontSize: 15,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                  ],
                ),

                const SizedBox(height: 40),

                // Features List - Professional Cards
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        Icons.security_outlined,
                        'AI-Powered Safety',
                        'Real-time threat detection and alerts',
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureItem(
                        Icons.location_on_outlined,
                        'Geo-Fencing',
                        'Smart boundary monitoring for safety',
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureItem(
                        Icons.verified_user_outlined,
                        'Blockchain IDs',
                        'Secure digital identity verification',
                        const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ).animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 40),

                // Action Buttons - Clear Login and Register
                Column(
                  children: [
                    // Login Button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1E40AF), // Professional blue
                            Color(0xFF3B82F6), // Light blue
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E40AF).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => context.go('/auth?type=login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Login to Your Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate()
                        .fadeIn(duration: 600.ms, delay: 800.ms)
                        .slideY(begin: 0.5, end: 0),

                    const SizedBox(height: 16),
                    
                    // Register Button  
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => context.go('/auth?type=register'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: const Color(0xFF10B981),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Create New Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate()
                        .fadeIn(duration: 600.ms, delay: 900.ms)
                        .slideY(begin: 0.5, end: 0),

                    const SizedBox(height: 12),
                    
                    // Learn More Button
                    TextButton.icon(
                      onPressed: () => context.go('/onboarding'),
                      icon: const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      label: const Text(
                        'Learn More About TourRaksha',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 950.ms),

                    const SizedBox(height: 16),
                    
                    // Continue as Guest link
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(
                        'Continue as Guest',
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, Color accentColor) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon, 
            color: accentColor, 
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
