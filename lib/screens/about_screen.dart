import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ilova haqida
            _buildSection('💊 Ilova haqida', [
              _buildInfoCard('Nomi', 'Medication Reminder', Icons.medication),
              _buildInfoCard('Versiya', '1.0.0', Icons.info),
              _buildInfoCard(
                'Ishlab chiqarilgan',
                '2025',
                Icons.calendar_today,
              ),
            ]),

            const SizedBox(height: 24),

            // Ishlab chiquvchi haqida
            _buildSection('👨‍💻 Ishlab chiquvchi', [
              _buildInfoCard('Ism', 'Eldor', Icons.person),
              _buildInfoCard('Kasb', 'Flutter Developer', Icons.work),
              _buildInfoCard('Tajriba', '2+ yil', Icons.trending_up),
            ]),

            const SizedBox(height: 24),

            // Bog'lanish
            _buildSection('📞 Bog\'lanish', [
              _buildContactCard(
                'Email',
                'eldor@example.com',
                Icons.email,
                () => _launchEmail('eldor@example.com'),
              ),
              _buildContactCard(
                'Telegram',
                '@eldor_dev',
                Icons.telegram,
                () => _launchTelegram('@eldor_dev'),
              ),
              _buildContactCard(
                'GitHub',
                'github.com/eldor',
                Icons.code,
                () => _launchGitHub('github.com/eldor'),
              ),
            ]),

            const SizedBox(height: 24),

            // Litsenziya
            _buildSection('📄 Litsenziya', [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gavel, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'MIT License',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bu ilova MIT litsenziyasi ostida tarqatiladi. '
                        'Barcha huquqlar himoyalangan.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // Yangilanishlar
            _buildSection('🆕 So\'nggi yangilanishlar', [
              _buildUpdateCard('v1.0.0', '2025-01-15', [
                '✅ Ilova yaratildi',
                '✅ Asosiy funksiyalar qo\'shildi',
                '✅ Drawer menu yaratildi',
                '✅ 4 ta asosiy sahifa qo\'shildi',
              ]),
            ]),

            const SizedBox(height: 24),

            // Foydali havolalar
            _buildSection('🔗 Foydali havolalar', [
              _buildLinkCard(
                'Flutter Documentation',
                'flutter.dev/docs',
                Icons.library_books,
                () => _launchUrl('https://flutter.dev/docs'),
              ),
              _buildLinkCard(
                'Dart Language',
                'dart.dev',
                Icons.code,
                () => _launchUrl('https://dart.dev'),
              ),
              _buildLinkCard(
                'Material Design',
                'material.io/design',
                Icons.design_services,
                () => _launchUrl('https://material.io/design'),
              ),
            ]),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  const Text(
                    '💊 Medication Reminder',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sog\'liq - eng qimmat boylik',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildContactCard(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(label),
        subtitle: Text(value),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildUpdateCard(String version, String date, List<String> changes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.update, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Versiya $version',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...changes.map(
              (change) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(change, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(
    String title,
    String url,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title),
        subtitle: Text(url),
        trailing: const Icon(Icons.open_in_new),
        onTap: onTap,
      ),
    );
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchTelegram(String username) async {
    final Uri telegramUri = Uri.parse('https://t.me/$username');
    if (await canLaunchUrl(telegramUri)) {
      await launchUrl(telegramUri);
    }
  }

  void _launchGitHub(String username) async {
    final Uri githubUri = Uri.parse('https://$username');
    if (await canLaunchUrl(githubUri)) {
      await launchUrl(githubUri);
    }
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
