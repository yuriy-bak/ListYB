import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => version = '${info.version} (${info.buildNumber})');
    });
  }

  Future<void> _showLicenseDialog() async {
    final licenseText = await DefaultAssetBundle.of(
      context,
    ).loadString('LICENSE.md');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Лицензия'),
        content: SingleChildScrollView(child: Text(licenseText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О приложении')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ListYB', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Версия: $version',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showLicenseDialog,
              icon: const Icon(Icons.description),
              label: const Text('Лицензия'),
            ),
          ],
        ),
      ),
    );
  }
}
