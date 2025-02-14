import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// User Model
class User {
  final int userId;
  final String username;
  final String email;
  final String passwordHash;
  final String createdAt;
  final String updatedAt;
  final String status;
  final String avatar;
  final String? role;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.avatar,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      username: json['username'],
      email: json['email'],
      passwordHash: json['passwordHash'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      status: json['status'],
      avatar: json['avatar'],
      role: json['role'],
    );
  }
}

// Add User Dialog
class AddUserDialog extends StatefulWidget {
  final Function onUserAdded;

  const AddUserDialog({
    super.key,
    required this.onUserAdded,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final response = await http.post(
          Uri.parse('http://localhost:5172/api/Users'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'username': _usernameController.text,
            'email': _emailController.text,
            'passwordHash': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onUserAdded();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to create user. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New User',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Add User'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Users Screen
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

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        onUserAdded: () {
          fetchUsers(); // Refresh the users list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
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
                  onPressed: _showAddUserDialog,
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
