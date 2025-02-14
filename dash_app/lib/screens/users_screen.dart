import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5172/api/Users'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Fetch random avatars
        final avatarResponse = await http.get(
          Uri.parse('https://randomuser.me/api/?results=${data.length}')
        );
        final avatarData = json.decode(avatarResponse.body);
        
        final List<User> formattedUsers = [];
        for (var i = 0; i < data.length; i++) {
          final user = data[i];
          user['avatar'] = avatarData['results'][i]['picture']['thumbnail'];
          user['role'] = 'User';
          formattedUsers.add(User.fromJson(user));
        }
        
        setState(() {
          users = formattedUsers;
          isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error fetching users: $error');
      setState(() => isLoading = false);
    }
  }

  Future<void> handleStatusChange(int userId, String newStatus) async {
    final endpoint = newStatus == 'Active'
        ? 'http://localhost:5172/api/Users/bulk-activate'
        : 'http://localhost:5172/api/Users/bulk-block';
    try {
      final response = await http.put(
        Uri.parse(endpoint),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: json.encode([userId]),
      );
      if (response.statusCode == 200) {
        setState(() {
          users = users.map((user) {
            if (user.userId == userId) {
              return User(
                userId: user.userId,
                username: user.username,
                email: user.email,
                passwordHash: user.passwordHash,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt,
                status: newStatus,
                avatar: user.avatar,
                role: user.role,
              );
            }
            return user;
          }).toList();
        });
      }
    } catch (error) {
      debugPrint('Error updating user status: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Users',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Add user functionality
                  },
                  child: const Text('Add User'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('User')),
                              DataColumn(label: Text('Role')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: users.map((user) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(user.avatar),
                                          radius: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              user.username,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              user.email,
                                              style: TextStyle(
                                                color: Theme.of(context).textTheme.bodySmall?.color,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        user.role ?? 'User',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.status == 'Active'
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        user.status,
                                        style: TextStyle(
                                          color: user.status == 'Active'
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () => handleStatusChange(
                                        user.userId,
                                        user.status == 'Active' ? 'Blocked' : 'Active',
                                      ),
                                      child: Text(
                                        user.status == 'Active' ? 'Block' : 'Activate',
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
