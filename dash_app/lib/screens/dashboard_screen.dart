import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/stat_card.dart';
import '../widgets/chart_widget.dart';
import './users_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  
  const DashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTimeRange = 30;
  int _selectedDrawerIndex = 0;

  Widget _getSelectedScreen() {
    switch (_selectedDrawerIndex) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return const Center(child: Text('Analytics Screen - Coming Soon'));
      case 2:
        return const UsersScreen();
      default:
        return _buildOverviewContent();
    }
  }

  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<int>(
                value: _selectedTimeRange,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                  DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                  DropdownMenuItem(value: 90, child: Text('Last 90 days')),
                ],
                onChanged: (value) {
                  setState(() => _selectedTimeRange = value!);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              StatCard(
                title: 'Total Users',
                value: '1,234',
                icon: Icons.people,
                color: Colors.blue,
              ),
              StatCard(
                title: 'Revenue',
                value: '\$12,345',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              StatCard(
                title: 'Orders',
                value: '846',
                icon: Icons.shopping_cart,
                color: Colors.orange,
              ),
              StatCard(
                title: 'Growth',
                value: '+12.3%',
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const ChartWidget(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedDrawerIndex == 0 
          ? 'Dashboard' 
          : _selectedDrawerIndex == 1 
            ? 'Analytics'
            : 'Users'
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications clicked')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings clicked')),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Dashboard Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Overview'),
              selected: _selectedDrawerIndex == 0,
              onTap: () {
                setState(() => _selectedDrawerIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              selected: _selectedDrawerIndex == 1,
              onTap: () {
                setState(() => _selectedDrawerIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              selected: _selectedDrawerIndex == 2,
              onTap: () {
                setState(() => _selectedDrawerIndex = 2);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _getSelectedScreen(),
    );
  }
}
