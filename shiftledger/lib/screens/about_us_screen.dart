import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utills/app_colors.dart';
import '../utills/app_spacing.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ---------- ACTION FUNCTIONS ---------- //

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Could not launch phone dialer');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    try {
      final Uri whatsappUri = Uri.parse('https://wa.me/91$phoneNumber');
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Could not open WhatsApp');
    }
  }

  Future<void> _openWebsite(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Could not open website');
    }
  }

  Future<void> _sendEmail(String email) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=Inquiry from Aqua Fresh User App',
      );
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: email));
      _showSuccessSnackBar('Email copied to clipboard');
    }
  }

  Future<void> _openGoogleMaps() async {
    try {
      const double latitude = 22.271447;
      const double longitude = 70.779615;

      final Uri googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );

      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showErrorSnackBar('Could not open Google Maps');
    }
  }

  // ---------- CONTACT CARD ---------- //

  Widget _buildContactCard({
    required Widget icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: AppColors.primary.withValues(alpha: 0.2),
      
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: icon),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI ---------- //

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppSpacing.getHorizontalPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    
    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: const Text("About Us"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: Container(
        padding: EdgeInsets.all(horizontalPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              child: Column(
                children: [
              // ---------- LOGO ANIMATION ---------- //
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        width: 160,
                        height: 160,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),

                       child: Image.asset(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/ally_logo_dark.png'
                              : 'assets/ally_logo_light.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // ---------- COMPANY NAME ---------- //
              Text(
                "AllySoft Solutions",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                "Your Technology Partner",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 30),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Get In Touch",
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------- CONTACT CARDS ---------- //
              _buildContactCard(
                icon: const Icon(
                  Icons.phone,
                  size: 26,
                  color: AppColors.primary,
                ),
                title: "Contact Us",
                subtitle: "88661 52292",
                onTap: () => _makePhoneCall("8866152292"),
                iconColor: AppColors.primary,
              ),

              _buildContactCard(
                icon: Image.asset(
                  'assets/whatsapp.png',
                  width: 26,
                  height: 26,
                ),
                title: "WhatsApp Us",
                subtitle: "90239 60106",
                onTap: () => _openWhatsApp("9023960106"),
                iconColor: Colors.green,
              ),

              _buildContactCard(
                icon: const Icon(
                  Icons.web,
                  size: 26,
                  color: AppColors.secondary,
                ),
                title: "Visit Us",
                subtitle: "allysoftsolutions.com",
                onTap: () => _openWebsite("https://allysoftsolutions.com/"),
                iconColor: AppColors.secondary,
              ),

              _buildContactCard(
                icon: const Icon(Icons.email, size: 26, color: AppColors.error),
                title: "Email",
                subtitle: "hr@allysoftsolutions.com",
                onTap: () => _sendEmail("hr@allysoftsolutions.com"),
                iconColor: AppColors.error,
              ),

              const SizedBox(height: 30),

              // ---------- ADDRESS BOX ---------- //
              InkWell(
                onTap: _openGoogleMaps,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Our Office",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      Text(
                        "205, Balaji Hall Complex,\nNr. Mahapuja Dham Chowk,\n150-ft Ring Road,\nRajkot - 360004",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),

                      SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 14,
                            color: Colors.white70,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Tap to open in maps",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ---------- FOOTER ---------- //
              Text(
                "Thank you for using our app!",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
      ),
    );
  }
}