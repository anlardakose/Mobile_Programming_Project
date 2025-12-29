import 'package:flutter/material.dart';
import '../notification/notification_list_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../notification/create_notification_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const NotificationListScreen(),
    const MapScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Campus'),
        actions: [
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminPanelScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1 
          ? null // Map ekranında FloatingActionButton gösterme (zoom butonlarıyla çakışmasın)
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateNotificationScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
