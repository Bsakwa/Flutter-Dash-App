import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final HttpLink httpLink = HttpLink(
  'http://localhost:5172/graphql',
  defaultHeaders: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
);

final GraphQLClient client = GraphQLClient(
  link: httpLink,
  cache: GraphQLCache(),
  defaultPolicies: DefaultPolicies(
    query: Policies(
      fetch: FetchPolicy.networkOnly,
    ),
  ),
);

// GraphQL Queries and Mutations
final String getUsersQuery = '''
  query GetUsers {
    users {
      userId
      username
      email
      createdAt
      updatedAt
      status
    }
  }
''';

final String createUserMutation = '''
  mutation CreateUser(\$input: CreateUserInput!) {
    createUser(input: \$input) {
      userId
      username
      email
      status
    }
  }
''';

final String updateUserMutation = '''
  mutation UpdateUser(\$input: UpdateUserInput!) {
    updateUser(input: \$input) {
      userId
      username
      email
      status

    }
  }
''';

final String deleteUserMutation = '''
  mutation DeleteUser(\$id: Int!) {
    deleteUser(id: \$id)
  }
''';

// User Model
class User {
  final int userId;
  final String username;
  final String email;
  final String? passwordHash;
  final String createdAt;
  final String updatedAt;
  final String status;
  final String avatar;
  final String? role;
  
  User({
    required this.userId,
    required this.username,
    required this.email,
    this.passwordHash,
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
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? DateTime.now().toIso8601String(),
      status: json['status'],
      avatar: json['avatar'] ?? 'https://randomuser.me/api/portraits/thumb/men/1.jpg',
      role: json['role'],
    );
  }
}

// Add User Dialog
class AddUserDialog extends StatefulWidget {
  final Function(User) onUserAdded;
  
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
        final MutationOptions options = MutationOptions(
          document: gql(createUserMutation),
          variables: {
            'input': {
              'username': _usernameController.text,
              'email': _emailController.text,
              'passwordHash': _passwordController.text,
            },
          },
        );
        
        final QueryResult result = await client.mutate(options);
        
        if (result.hasException) {
          throw Exception(result.exception.toString());
        }
        
        final user = User.fromJson(result.data?['createUser']);
        
        if (mounted) {
          Navigator.of(context).pop();
          widget.onUserAdded(user);
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

// Edit User Dialog
class EditUserDialog extends StatefulWidget {
  final User user;
  final Function(User) onUserUpdated;
  
  const EditUserDialog({
    super.key,
    required this.user,
    required this.onUserUpdated,
  });
  
  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late String _selectedStatus;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController();
    _selectedStatus = widget.user.status;
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Create the input object
        final Map<String, dynamic> input = {
          'userId': widget.user.userId,
          'username': _usernameController.text,
          'email': _emailController.text,
          'status': _selectedStatus,
          'passwordHash': widget.user.passwordHash, 
        };

        // Only add the password if it's not empty
        if (_passwordController.text.isNotEmpty) {
          input['passwordHash'] = _passwordController.text;
        }
        
        
        final MutationOptions options = MutationOptions(
          document: gql(updateUserMutation),
          variables: {
            'input': input,
          },
        );
        
        final QueryResult result = await client.mutate(options);
        
        if (result.hasException) {
          throw Exception(result.exception.toString());
        }
        
        final updatedUser = User.fromJson(result.data?['updateUser']);
        
        if (mounted) {
          Navigator.of(context).pop();
          widget.onUserUpdated(updatedUser);
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
                'Edit User: ${widget.user.username}',
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
                  labelText: 'New Password (leave blank to keep current)',
                  border: OutlineInputBorder(),
                  helperText: 'Only enter if you want to change the password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Active'),
                  ),
                  DropdownMenuItem(
                    value: 'blocked',
                    child: Text('Blocked'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
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
                        : const Text('Save Changes'),
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
    setState(() => isLoading = true);
    try {
      final QueryOptions options = QueryOptions(
        document: gql(getUsersQuery),
        fetchPolicy: FetchPolicy.networkOnly,
        errorPolicy: ErrorPolicy.all,
      );
      
      final QueryResult result = await client.query(options).timeout(const Duration(seconds: 10));
      
      if (result.hasException) {
        throw Exception(result.exception.toString());
      }
      
      final List<dynamic> userList = result.data?['users'] ?? [];
      final List<User> formattedUsers = userList.map((user) => User.fromJson(user)).toList();
      
      setState(() {
        users = formattedUsers;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching users: $error');
      setState(() => isLoading = false);
    }
  }
  
  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        onUserAdded: (user) {
          setState(() {
            users.add(user);
          });
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
  
  void _showEditUserDialog(User user) {
  showDialog(
    context: context,
    builder: (context) => EditUserDialog(
      user: user,
      onUserUpdated: (updatedUser) async {  // Make this async
        // First fetch fresh data from server
        await fetchUsers();  // Refetch all users to get latest data
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () => _showEditUserDialog(user),
                                          child: const Text('Edit'),
                                        ),
                                      ],
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


