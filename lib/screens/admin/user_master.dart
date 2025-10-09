import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kenuniv/core/api_service.dart';
import 'package:kenuniv/utils/constant.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserMaster extends ConsumerStatefulWidget {
  const UserMaster({super.key});

  @override
  ConsumerState<UserMaster> createState() => _UserMasterState();
}

class _UserMasterState extends ConsumerState<UserMaster> {
  late String token;
  List<dynamic> _fetchedUsers = [];
  bool _isLoading = false;
  List<String> _accessRights = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final api = ApiService(token: '');
      final response = await api.getRequest(userMasterGet);

      if (response['success'] == true && response['users'] != null) {
        setState(() {
          _fetchedUsers = response['users'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No users found or invalid response")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching users: $e")));
    }
  }

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedUser;
  bool _isActive = true;

  Future<void> _submitUser() async {
    final name = _fullNameController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || mobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    try {
      final body = {
        "name": name,
        "mobile": mobile,
        "password": password,
        "address": address,
        "active": _isActive,
        "role": "admin",
        "permissions": {
          "userMaster": _accessRights.contains('UserMaster'),
          "scheme": _accessRights.contains('scheme'),
          "stock": _accessRights.contains('stock'),
          "point": _accessRights.contains('Point'),
          "qr": _accessRights.contains('qr'),
          "news": _accessRights.contains('news'),
          "contractor": _accessRights.contains('contractor'),
          "wallet": _accessRights.contains('wallet'),
          "reports": _accessRights.contains('reports'),
          "dashboard": _accessRights.contains('dashboard'),
        },
      };

      final response = await http.post(
        Uri.parse('$userMasterEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("User added successfully")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${response.statusCode} - ${response.body}"),
          ),
        );
      }
    } catch (e) {
      print("Submit error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('User Master'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: Color(0xffF4F3F3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Mobile',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            CheckboxListTile(
                              title: const Text('userMaster'),
                              value: _accessRights.contains('userMaster'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _accessRights.add('userMaster');
                                  } else {
                                    _accessRights.remove('userMaster');
                                  }
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: const Text('Gift Scheme Master'),
                              value: _accessRights.contains('scheme'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _accessRights.add('scheme');
                                  } else {
                                    _accessRights.remove('scheme');
                                  }
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: const Text('Gift stock Master'),
                              value: _accessRights.contains('stock'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _accessRights.add('stock');
                                  } else {
                                    _accessRights.remove('stock');
                                  }
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: const Text('Point'),
                              value: _accessRights.contains('point'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _accessRights.add('point');
                                  } else {
                                    _accessRights.remove('point');
                                  }
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: const Text('Qr Code Genration'),
                              value: _accessRights.contains('qr'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _accessRights.add('qr');
                                  } else {
                                    _accessRights.remove('qr');
                                  }
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: const Text('Redemption Master'),
                              value: _accessRights.contains('scheme'),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _accessRights.add('scheme');
                                  } else {
                                    _accessRights.remove('scheme');
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _submitUser,
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.1,
                decoration: BoxDecoration(
                  color: Color(0xffF4F3F3),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select User',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedUser,
                        items: _fetchedUsers
                            .map(
                              (user) => DropdownMenuItem<String>(
                                value: user['_id'] as String,
                                child: Text(user['name']),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUser = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isActive
                                ? Colors.red
                                : Colors.grey[300],
                            foregroundColor: _isActive
                                ? Colors.white
                                : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _isActive = true;
                            });
                          },
                          child: const Text('Active'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_isActive
                                ? Colors.red
                                : Colors.grey[300],
                            foregroundColor: !_isActive
                                ? Colors.white
                                : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _isActive = false;
                            });
                          },
                          child: const Text('Inactive'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
