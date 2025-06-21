import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'O\'zbek';
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final isEnabled = await _notificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = isEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          // Til sozlamalari
          _buildSectionHeader('🌐 Til sozlamalari'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Til tanlash'),
              subtitle: Text(_selectedLanguage),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showLanguageDialog();
              },
            ),
          ),

          // Tema sozlamalari
          _buildSectionHeader('🎨 Tema sozlamalari'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark mode'),
              subtitle: const Text('Qorong\'i tema'),
              value: _isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
          ),

          // Bildirishnoma sozlamalari
          _buildSectionHeader('🔔 Bildirishnoma sozlamalari'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Bildirishnomalar'),
                  subtitle: const Text('Eslatma bildirishnomalari'),
                  value: _notificationsEnabled,
                  onChanged: (bool value) async {
                    if (value) {
                      await _notificationService.requestPermissions();
                    }
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up),
                  title: const Text('Ovoz'),
                  subtitle: const Text('Eslatma ovozlari'),
                  value: _soundEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('Vibratsiya'),
                  subtitle: const Text('Titrash signali'),
                  value: _vibrationEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.science),
                  title: const Text('Test bildirishnoma'),
                  subtitle: const Text(
                    'Bildirishnoma ishlayotganini tekshirish',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    await _notificationService.showTestNotification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🧪 Test bildirishnoma yuborildi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Barcha bildirishnomalarni tozalash'),
                  subtitle: const Text(
                    'Rejalashtirilgan bildirishnomalarni bekor qilish',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    await _notificationService.cancelAllNotifications();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '🗑️ Barcha bildirishnomalar bekor qilindi',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Ma'lumotlar sozlamalari
          _buildSectionHeader('💾 Ma\'lumotlar sozlamalari'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Ma\'lumotlarni saqlash'),
                  subtitle: const Text('Cloud ga saqlash'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implement backup
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Ma\'lumotlarni tiklash'),
                  subtitle: const Text('Cloud dan tiklash'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implement restore
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Barcha ma\'lumotlarni o\'chirish'),
                  subtitle: const Text('Dikkat! Bu amalni qaytarib bo\'lmaydi'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showDeleteConfirmation();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Til tanlash'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('O\'zbek'),
              _buildLanguageOption('Русский'),
              _buildLanguageOption('English'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _selectedLanguage == language
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Diqqat!'),
          content: const Text(
            'Barcha ma\'lumotlar o\'chiriladi. Bu amalni qaytarib bo\'lmaydi. Davom etasizmi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () async {
                // Cancel all notifications
                await _notificationService.cancelAllNotifications();

                // TODO: Implement delete all data
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🗑️ Barcha ma\'lumotlar o\'chirildi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('O\'chirish'),
            ),
          ],
        );
      },
    );
  }
}
