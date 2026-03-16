import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kenuniv/providers/auth_provider.dart';

class PointMaster extends ConsumerStatefulWidget {
  const PointMaster({super.key});

  @override
  ConsumerState<PointMaster> createState() => _PointMasterState();
}

class _PointMasterState extends ConsumerState<PointMaster> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pointsController = TextEditingController();
  Color? _selectedColor;
  List<Map<String, dynamic>> _pointMasters = [];
  final List<String> _codes = [
    'NM',
    'RM',
    'BM',
    'BM+',
    'WM',
    'MF',
    'FF',
    'WF',
    'SF',
    'SF(W)',
  ];

  String? _selectedCode;
  final List<Color> _colors = [
Color(0xFFE0E0E0), // Light Silver (Replaced C5C7C6)
    Color(0xFFD7CCC8), // Light Coffy (Replaced B09778)
    Color(0xFFF8BBD0), // Light Pink (Replaced E4097F)
    Color(0xFFA5D6A7), // Light Green (Replaced 008218)
    Color(0xFFB39DDB), // Light Purple (Replaced 3928E0)
    Color(0xFF81D4FA), // Light Blue (Replaced 015889)
    Color(0xFFFFAB91), // Light Orange (Replaced c24b0c)
    Color(0xFFFFF59D), // Light Yellow (Replaced c89900)
    Color(0xFFEF9A9A), // Light Red/Coral (Replaced C6272B)
  ];

  @override
  void initState() {
    super.initState();
    fetchPointMasters();
  }

  Future<void> deletePointMaster(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://api.kenuniv.com/api/point/points/$id'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Point Master deleted successfully')),
        );
        fetchPointMasters();
      } else {
        print("Failed to delete: ${response.body}");
      }
    } catch (e) {
      print("Error deleting point master: $e");
    }
  }

  Future<void> fetchPointMasters() async {
    try {
      final response = await http.get(
        Uri.parse('http://api.kenuniv.com/api/point/points'),
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _pointMasters = data.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      print("Failed to fetch point masters: $e");
    }
  }

  Future<void> submitPointMaster() async {
    if (_formKey.currentState!.validate() && _selectedColor != null) {
      final body = {
        'points': int.parse(_pointsController.text),
        'color': _selectedColor!.value.toRadixString(16), // send color as hex
        'code': _selectedCode,
      };
      try {
        final response = await http.post(
          Uri.parse('http://api.kenuniv.com/api/point/points'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Point Master added successfully')),
          );
          _pointsController.clear();
          _selectedCode = null;
          _selectedColor = null;
          fetchPointMasters();
        } else {
          print("Error: ${response.body}");
        }
      } catch (e) {
        print("Failed to submit: $e");
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canWrite = authState.permissions?['point'] == true;
    final isReadOnly = !canWrite;

    return Scaffold(
      appBar: AppBar(title: const Text("Point Master")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Points',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter points';
                      if (int.tryParse(value) == null)
                        return 'Enter a valid number';
                      return null;
                    },
                    enabled: !isReadOnly,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Color>(
                    value: _selectedColor,
                    hint: const Text('Select Color'),
                    items: _colors
                        .map(
                          (color) => DropdownMenuItem(
                            value: color,
                            child: Container(
                              width: 100,
                              height: 20,
                              color: color,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: isReadOnly
                        ? null
                        : (color) => setState(() => _selectedColor = color),
                    validator: (value) =>
                        value == null ? 'Select a color' : null,
                    onSaved: isReadOnly
                        ? null
                        : (color) => _selectedColor = color,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCode,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      border: OutlineInputBorder(),
                    ),
                    items: _codes
                        .map(
                          (code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          ),
                        )
                        .toList(),
                    onChanged: isReadOnly
                        ? null
                        : (value) => setState(() => _selectedCode = value),
                    validator: (value) => value == null ? 'Select code' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isReadOnly ? null : submitPointMaster,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _pointMasters.isEmpty
                  ? const Center(child: Text('No Point Masters'))
                  : ListView.builder(
                      itemCount: _pointMasters.length,
                      itemBuilder: (context, index) {
                        final point = _pointMasters[index];
                        return Card(
                          child: ListTile(
                            leading: Container(
                              width: 20,
                              height: 20,
                              color: Color(
                                int.parse(point['color'], radix: 16),
                              ),
                            ),
                            title: Text('Points: ${point['points']}'),
                            subtitle: Text('Code: ${point['code']}'),
                            trailing: isReadOnly
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        deletePointMaster(point['_id']),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
