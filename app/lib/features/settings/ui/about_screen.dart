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
        maximumColorCount: 16,
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

        final primary = _palette?.vibrantColor?.color ?? _palette?.dominantColor?.color ?? const Color(0xFF0A84FF);
        final secondary = _palette?.lightVibrantColor?.color ?? _palette?.mutedColor?.color ?? const Color(0xFF6EC6FF);
        final bgGradient = LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        final onPrimary = ThemeData.estimateBrightnessForColor(primary) == Brightness.dark ? Colors.white : Colors.black87;
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'images/bitrift-logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 6),
                Center(child: Text(info.appName, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: onPrimary))),
                Center(
                  child: Text(
                    version,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: onPrimary.withOpacity(0.9)),
                  ),
                ),
                const SizedBox(height: 24),
                _FrostedCard(
                child: Column(
                  children: [
                      const ListTile(
                        leading: Icon(Icons.business),
                        title: Text('Company'),
                        subtitle: Text('Bitrift'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Support Email'),
                        subtitle: const SelectableText('gymrat@bitrift.tech'),
                        trailing: IconButton(
                          tooltip: 'Copy email',
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard('gymrat@bitrift.tech', 'Email address copied'),
                        ),
                      ),
                  ],
                ),
                ),
                const SizedBox(height: 12),
                _FrostedCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.public),
                        title: const Text('Website'),
                        subtitle: const Text('bitrift.tech'),
                        onTap: () => launchUrl(Uri.parse('https://bitrift.tech'), mode: LaunchMode.externalApplication),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.alternate_email),
                        title: const Text('X (Twitter)'),
                        subtitle: const Text('@BitRiftTech'),
                        onTap: () => launchUrl(Uri.parse('https://x.com/BitRiftTech'), mode: LaunchMode.externalApplication),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('GitHub'),
                        subtitle: const Text('github.com/bitrifttech'),
                        onTap: () => launchUrl(Uri.parse('https://github.com/bitrifttech'), mode: LaunchMode.externalApplication),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _FrostedCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: const Text('Open source licenses'),
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
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Terms of Service'),
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
                  style: TextStyle(color: onPrimary.withOpacity(0.95)),
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

class _FrostedCard extends StatelessWidget {
  const _FrostedCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}


