import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../services/storage_service.dart';
import '../../services/health_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      title: 'Know Your Body',
      subtitle: 'Measure heart rate, blood oxygen, temperature, and more — right from your iPhone.',
      icon: Icons.favorite_rounded,
      gradient: AppColors.heartGradient,
      color: AppColors.heartRed,
    ),
    _OnboardingData(
      title: 'Track Every Day',
      subtitle: 'Monitor your activity, sleep quality, stress levels, and wellness trends over time.',
      icon: Icons.bar_chart_rounded,
      gradient: AppColors.tealGradient,
      color: AppColors.teal,
    ),
    _OnboardingData(
      title: 'Stay Connected',
      subtitle: 'Sync with Apple Health, connect Bluetooth devices, and share data with your doctor.',
      icon: Icons.health_and_safety_rounded,
      gradient: AppColors.sleepGradient,
      color: AppColors.sleepPurple,
    ),
  ];

  void _next() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await HealthService.instance.requestPermissions();
      await StorageService.instance.markOnboardingComplete();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomControls(
              controller: _pageController,
              pageCount: _pages.length,
              currentPage: _currentPage,
              onNext: _next,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.navyGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Spacer(),
            // Illustration
            Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: data.gradient,
                boxShadow: [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.35),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(data.icon, size: size.width * 0.22, color: Colors.white),
            ),
            const Spacer(),
            // Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.18),
          ],
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final PageController controller;
  final int pageCount;
  final int currentPage;
  final VoidCallback onNext;

  const _BottomControls({
    required this.controller,
    required this.pageCount,
    required this.currentPage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == pageCount - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
      child: Column(
        children: [
          SmoothPageIndicator(
            controller: controller,
            count: pageCount,
            effect: ExpandingDotsEffect(
              dotColor: Colors.white24,
              activeDotColor: AppColors.teal,
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: Text(
                isLast ? 'Get Started' : 'Continue',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color color;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.color,
  });
}
