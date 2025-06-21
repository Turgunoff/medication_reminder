import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/add_medication_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'services/notification_service.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '💊 Medication Reminder',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AddMedicationScreen(),
    const SettingsScreen(),
    const AboutScreen(),
  ];

  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              final pending = await _notificationService
                  .getPendingNotifications();
              if (!mounted) return;
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  if (pending.isEmpty) {
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'Hech qanday rejalashtirilgan eslatma yo‘q',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    children: [
                      const Text(
                        'Rejalashtirilgan bildirishnomalar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...pending.map((n) {
                        String timeStr = '';
                        try {
                          final payload = n.payload != null ? n.payload! : '';
                          final data = payload.isNotEmpty
                              ? Map<String, dynamic>.from(jsonDecode(payload))
                              : {};
                          if (data.containsKey('time')) {
                            timeStr = data['time'];
                          }
                        } catch (_) {}
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.notifications_active,
                              color: Colors.blue,
                            ),
                            title: Text(n.title ?? 'Bildirishnoma'),
                            subtitle: Text(n.body ?? ''),
                            trailing: timeStr.isNotEmpty ? Text(timeStr) : null,
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer header
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue, Colors.lightBlue],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.medication, size: 40, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '💊 Medication Reminder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Sog\'liq - eng qimmat boylik',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Drawer menu items
            _buildDrawerItem(
              icon: Icons.home,
              title: '🏠 Bosh sahifa',
              subtitle: 'Dorilar ro\'yxati va navbatdagi doza',
              onTap: () => _navigateToScreen(0),
            ),

            _buildDrawerItem(
              icon: Icons.add_circle,
              title: '➕ Dori qo\'shish',
              subtitle: 'Yangi dori qo\'shish',
              onTap: () => _navigateToAddMedication(),
            ),

            _buildDrawerItem(
              icon: Icons.settings,
              title: '⚙️ Sozlamalar',
              subtitle: 'Ilova sozlamalari',
              onTap: () => _navigateToScreen(2),
            ),

            _buildDrawerItem(
              icon: Icons.info,
              title: 'ℹ️ Ilova haqida',
              subtitle: 'Ilova va ishlab chiquvchi haqida',
              onTap: () => _navigateToScreen(3),
            ),

            const Divider(),

            // Additional menu items
            _buildDrawerItem(
              icon: Icons.history,
              title: '📊 Tarix',
              subtitle: 'Dorilar ichish tarixi',
              onTap: () {
                // TODO: Navigate to history screen
              },
            ),

            _buildDrawerItem(
              icon: Icons.analytics,
              title: '📈 Statistika',
              subtitle: 'Dorilar ichish statistikasi',
              onTap: () {
                // TODO: Navigate to statistics screen
              },
            ),

            const Divider(),

            // Help and support
            _buildDrawerItem(
              icon: Icons.help,
              title: '❓ Yordam',
              subtitle: 'Foydalanish bo\'yicha yordam',
              onTap: () {
                // TODO: Navigate to help screen
              },
            ),

            _buildDrawerItem(
              icon: Icons.feedback,
              title: '💬 Fikr bildirish',
              subtitle: 'Ilova haqida fikr bildiring',
              onTap: () {
                // TODO: Navigate to feedback screen
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  void _navigateToScreen(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context); // Close drawer
  }

  void _navigateToAddMedication() async {
    Navigator.pop(context); // Close drawer first

    // Navigate to AddMedicationScreen and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
    );

    // If medication was added successfully, refresh HomeScreen
    if (result == true) {
      setState(() {
        _currentIndex = 0; // Go back to home screen
      });

      // Force refresh of HomeScreen
      if (_screens[0] is HomeScreen) {
        // The HomeScreen will automatically refresh when it becomes visible
        // due to the IndexedStack behavior
      }
    }
  }
}
