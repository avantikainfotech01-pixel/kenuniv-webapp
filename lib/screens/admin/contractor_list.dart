import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ContractorList extends StatefulWidget {
  const ContractorList({super.key});

  @override
  State<ContractorList> createState() => _ContractorListState();
}

class _ContractorListState extends State<ContractorList> {
  // Controllers for filters
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedLocation;
  List<String> _locations = ['All'];

  // API base url
  final String _baseUrl =
      "http://api.kenuniv.com"; // example: http://65.0.0.0:5000

  // Runtime list of contractors fetched from API
  List<Map<String, dynamic>> _contractors = [];
  List<Map<String, dynamic>> _allContractors = [];

  bool _isLoading = false;

  // format createdAt date into readable format
  String _formatDate(String value) {
    try {
      final dt = DateTime.parse(value);
      return DateFormat('dd-MM-yyyy  hh:mm a').format(dt);
    } catch (e) {
      return '-';
    }
  }

  // Fetch contractor list from backend
  Future<void> _fetchContractors() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse("$_baseUrl/api/app-users");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      final List users = body["data"] ?? [];

      _allContractors = users.map<Map<String, dynamic>>((u) {
        return {
          "id": u["_id"] ?? "",
          "name": u["name"] ?? "-",
          "mobile": u["mobile"] ?? "-",
          "address": u["address"] ?? "-",
          "city": u["city"] ?? "-",
          "state": u["state"] ?? "-",
          "date": (u["createdAt"] ?? "").toString(),
        };
      }).toList();

      _contractors = List<Map<String, dynamic>>.from(_allContractors);

      // build unique dynamic locations list from API data
      final Set<String> citySet = {};
      for (final c in _allContractors) {
        final city = (c['city'] ?? '').toString().trim();
        if (city.isNotEmpty) {
          citySet.add(city);
        }
      }
      _locations = ['All', ...citySet.toList()];

      // reset selected location when refreshing
      if (!_locations.contains(_selectedLocation)) {
        _selectedLocation = 'All';
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchContractors();
    _searchController.addListener(() {
      _applyFilters();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Apply filters for search, location and date
  void _applyFilters() {
    String search = _searchController.text.trim().toLowerCase();
    String? selectedLoc = _selectedLocation;
    String selectedDate = _dateController.text.trim();

    List<Map<String, dynamic>> filtered = List<Map<String, dynamic>>.from(
      _allContractors,
    );

    // text search by name or mobile
    if (search.isNotEmpty) {
      filtered = filtered.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final mobile = (c['mobile'] ?? '').toString().toLowerCase();
        return name.contains(search) || mobile.contains(search);
      }).toList();
    }

    // location filter
    if (selectedLoc != null && selectedLoc.isNotEmpty && selectedLoc != 'All') {
      filtered = filtered.where((c) {
        final city = (c['city'] ?? '').toString();
        return city == selectedLoc;
      }).toList();
    }

    // date filter (YYYY-MM-DD from controller matched against createdAt)
    if (selectedDate.isNotEmpty) {
      filtered = filtered.where((c) {
        final dateStr = (c['date'] ?? '').toString();
        return dateStr.startsWith(selectedDate);
      }).toList();
    }

    setState(() {
      _contractors = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applicator List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by Name, ID, Company, or Mobile',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Contract Location Dropdown
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            items: _locations
                                .map(
                                  (loc) => DropdownMenuItem<String>(
                                    value: loc,
                                    child: Text(loc),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedLocation = val;
                              });
                              _applyFilters();
                            },
                            decoration: const InputDecoration(
                              labelText: 'Contract Location',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Date Picker
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Registration Date',
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Apply Filters Button
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: _applyFilters,
                              child: const Text('APPLY FILTERS'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // DataTable Card
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : DataTable(
                            columns: const [
                              DataColumn(label: Text('No.')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Contact Person')),
                              DataColumn(label: Text('Registration Date')),
                              DataColumn(label: Text('Mobile No.')),
                              DataColumn(label: Text('Location')),
                            ],
                            rows: List.generate(_contractors.length, (index) {
                              final c = _contractors[index];
                              return DataRow(
                                cells: [
                                  DataCell(Text((index + 1).toString())),
                                  DataCell(Text(c['name'] ?? '')),
                                  DataCell(Text(c['name'] ?? '')),
                                  DataCell(Text(_formatDate(c['date'] ?? ''))),
                                  DataCell(Text(c['mobile'] ?? '')),
                                  DataCell(Text(c['city'] ?? '')),
                                ],
                              );
                            }),
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
