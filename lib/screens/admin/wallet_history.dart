import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:kenuniv/models/wallet_model.dart';

class WalletHistory extends StatefulWidget {
  const WalletHistory({super.key});

  @override
  State<WalletHistory> createState() => _WalletHistoryState();
}

class _WalletHistoryState extends State<WalletHistory> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWalletHistory();
    _mobileController.addListener(() {
      _applyFilters();
    });
  }

  List<WalletHistoryModel> _allData = [];
  List<WalletHistoryModel> _filteredData = [];

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _selectedType = 'All';

  Future<void> fetchWalletHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(
        Uri.parse('http://api.kenuniv.com/api/wallet/all-history'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'];

        _allData = data
            .map((item) => WalletHistoryModel.fromJson(item))
            .toList();

        _filteredData = List<WalletHistoryModel>.from(_allData);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    String mob = _mobileController.text.trim();
    String selDate = _dateController.text.trim();
    String type = _selectedType;

    List<WalletHistoryModel> temp = List.from(_allData);

    // filter by mobile
    if (mob.isNotEmpty) {
      temp = temp.where((i) => i.userMobile.contains(mob)).toList();
    }

    // filter by type
    if (type != 'All') {
      temp = temp
          .where((i) => i.type.toLowerCase() == type.toLowerCase())
          .toList();
    }

    // filter by date (yyyy-MM-dd compare only date part)
    if (selDate.isNotEmpty) {
      temp = temp.where((i) {
        final formatted = DateFormat('yyyy-MM-dd').format(i.date);
        return formatted == selDate;
      }).toList();
    }

    setState(() {
      _filteredData = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet History")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredData.isEmpty
          ? const Center(child: Text("No History Yet Found"))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Filters",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: 220,
                                  child: TextField(
                                    controller: _mobileController,
                                    decoration: InputDecoration(
                                      labelText: 'Search by mobile',
                                      prefixIcon: const Icon(Icons.search),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedType,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'All',
                                        child: Text('All'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'credit',
                                        child: Text('Credit'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'debit',
                                        child: Text('Debit'),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      _selectedType = val ?? 'All';
                                      _applyFilters();
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Transaction Type',
                                      prefixIcon: const Icon(Icons.swap_vert),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  child: TextField(
                                    controller: _dateController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      labelText: 'Select date',
                                      prefixIcon: const Icon(
                                        Icons.calendar_today,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        _dateController.text = DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(picked);
                                        _applyFilters();
                                      }
                                    },
                                  ),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    _mobileController.clear();
                                    _dateController.clear();
                                    _selectedType = 'All';
                                    setState(() {
                                      _filteredData = List.from(_allData);
                                    });
                                  },
                                  label: const Text('Clear filters'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey[200],
                      ),
                      columns: const [
                        DataColumn(label: Text("No.")),
                        DataColumn(label: Text("User Name")),
                        DataColumn(label: Text("Mobile")),
                        DataColumn(label: Text("Type")),
                        DataColumn(label: Text("Points")),
                        DataColumn(label: Text("Balance After")),
                        DataColumn(label: Text("Description")),
                        DataColumn(label: Text("Date")),
                      ],
                      rows: List.generate(_filteredData.length, (index) {
                        final item = _filteredData[index];
                        final type = item.type.toLowerCase();
                        final typeColor = type == 'credit'
                            ? Colors.green
                            : (type == 'debit' ? Colors.red : Colors.black);

                        return DataRow(
                          cells: [
                            DataCell(Text("${index + 1}")),
                            DataCell(Text(item.userName)),
                            DataCell(Text(item.userMobile)),
                            DataCell(
                              Text(
                                item.type,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(item.points.toString())),
                            DataCell(Text(item.balanceAfter.toString())),
                            DataCell(Text(item.description)),
                            DataCell(
                              Text(
                                DateFormat(
                                  'dd-MM-yyyy  hh:mm a',
                                ).format(item.date),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
