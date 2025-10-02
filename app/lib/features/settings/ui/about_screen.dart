import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _packageInfoFuture;
  PaletteGenerator? _palette;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
    _generatePalette();
  }

  Future<void> _copyToClipboard(String text, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  Future<void> _generatePalette() async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        const AssetImage('images/bitrift-logo.png'),
        size: const Size(400, 400),
        maximumColorCount: 20,
      );
      if (!mounted) return;
      setState(() => _palette = palette);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('About')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('About')),
            body: const Center(child: Text('Unable to load app info')),
          );
        }

        final info = snapshot.data!;
        final version = '${info.version} (build ${info.buildNumber})';

        // Extract vibrant colors from logo palette
        final vibrant = _palette?.vibrantColor?.color ?? const Color(0xFFE63946);
        final darkVibrant = _palette?.darkVibrantColor?.color ?? const Color(0xFF1D3557);
        final lightVibrant = _palette?.lightVibrantColor?.color ?? const Color(0xFFF1FAEE);
        final muted = _palette?.mutedColor?.color ?? const Color(0xFFA8DADC);
        
        // Create multi-stop gradient for rich background
        final bgGradient = LinearGradient(
          colors: [
            darkVibrant,
            vibrant,
            muted,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        final onPrimary = ThemeData.estimateBrightnessForColor(darkVibrant) == Brightness.dark ? Colors.white : Colors.black87;
        final media = MediaQuery.of(context);
        final double logoSize = (media.size.width * 0.75).clamp(240.0, 380.0).toDouble();

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(gradient: bgGradient),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              children: [
              const SizedBox(height: 4),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'images/bitrift-logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
                Center(
                  child: Text(
                    info.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    version,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onPrimary.withOpacity(0.95),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _GlassCard(
                  gradient: LinearGradient(
                    colors: [
                      lightVibrant.withOpacity(0.3),
                      Colors.white.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                child: Column(
                  children: [
                      _StyledListTile(
                        icon: Icons.business_rounded,
                        iconColor: vibrant,
                        title: 'Company',
                        subtitle: 'Bitrift',
                      ),
                      Divider(height: 1, color: Colors.white.withOpacity(0.2)),
                      _StyledListTile(
                        icon: Icons.email_rounded,
                        iconColor: darkVibrant,
                        title: 'Support Email',
                        subtitle: 'gymrat@bitrift.tech',
                        trailing: IconButton(
                          tooltip: 'Copy email',
                          icon: Icon(Icons.copy_rounded, color: vibrant),
                          onPressed: () => _copyToClipboard('gymrat@bitrift.tech', 'Email address copied'),
                        ),
                      ),
                  ],
                ),
                ),
                const SizedBox(height: 12),
                _GlassCard(
                  gradient: LinearGradient(
                    colors: [
                      vibrant.withOpacity(0.25),
                      muted.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Column(
                    children: [
                      _StyledListTile(
                        icon: Icons.public_rounded,
                        iconColor: muted,
                        title: 'Website',
                        subtitle: 'bitrift.tech',
                        trailing: Icon(Icons.open_in_new_rounded, color: vibrant.withOpacity(0.7), size: 20),
                        onTap: () => launchUrl(Uri.parse('https://bitrift.tech'), mode: LaunchMode.externalApplication),
                      ),
                      Divider(height: 1, color: Colors.white.withOpacity(0.2)),
                      _StyledListTile(
                        icon: Icons.alternate_email_rounded,
                        iconColor: vibrant,
                        title: 'X (Twitter)',
                        subtitle: '@BitRiftTech',
                        trailing: Icon(Icons.open_in_new_rounded, color: vibrant.withOpacity(0.7), size: 20),
                        onTap: () => launchUrl(Uri.parse('https://x.com/BitRiftTech'), mode: LaunchMode.externalApplication),
                      ),
                      Divider(height: 1, color: Colors.white.withOpacity(0.2)),
                      _StyledListTile(
                        icon: Icons.code_rounded,
                        iconColor: darkVibrant,
                        title: 'GitHub',
                        subtitle: 'github.com/bitrifttech',
                        trailing: Icon(Icons.open_in_new_rounded, color: vibrant.withOpacity(0.7), size: 20),
                        onTap: () => launchUrl(Uri.parse('https://github.com/bitrifttech'), mode: LaunchMode.externalApplication),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _GlassCard(
                  gradient: LinearGradient(
                    colors: [
                      darkVibrant.withOpacity(0.25),
                      lightVibrant.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Column(
                    children: [
                      _StyledListTile(
                        icon: Icons.article_rounded,
                        iconColor: lightVibrant,
                        title: 'Open source licenses',
                        subtitle: 'View third-party licenses',
                        trailing: Icon(Icons.chevron_right_rounded, color: vibrant.withOpacity(0.7)),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: info.appName,
                          applicationVersion: info.version,
                          applicationIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset('images/bitrift-logo.png', width: 40, height: 40),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: Colors.white.withOpacity(0.2)),
                      _StyledListTile(
                        icon: Icons.description_rounded,
                        iconColor: muted,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms',
                        trailing: Icon(Icons.chevron_right_rounded, color: vibrant.withOpacity(0.7)),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Thanks for using ${info.appName}! If you run into any issues, feel free to reach out.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onPrimary.withOpacity(0.95),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Terms of Service',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'This app is provided "as is" by Bitrift. We make no warranties, express or implied, and we are not responsible for any damages or outcomes resulting from use of the app. Use it at your own discretion and have fun.',
          ),
          SizedBox(height: 16),
          Text(
            'By using this app, you agree that Bitrift is not liable for any losses or damages arising from your use of the app, including but not limited to data loss, inaccurate results, or health-related outcomes. Always consult a professional for nutrition or fitness advice.',
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, required this.gradient});
  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _StyledListTile extends StatelessWidget {
  const _StyledListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              iconColor.withOpacity(0.8),
              iconColor.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black26,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.85),
          shadows: const [
            Shadow(
              color: Colors.black26,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      trailing: trailing,
    );
  }
}



