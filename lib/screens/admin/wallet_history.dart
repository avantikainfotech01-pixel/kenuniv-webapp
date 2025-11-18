import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:kenuniv/models/wallet_model.dart';

class WalletHistory extends StatefulWidget {
  const WalletHistory({super.key});

  @override
  State<WalletHistory> createState() => _WalletHistoryState();
}

class _WalletHistoryState extends State<WalletHistory> {
  Future<List<WalletHistoryModel>> fetchWalletHistory() async {
    final response = await http.get(
      Uri.parse('http://api.kenuniv.com/api/wallet/all-history'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'];
      return data.map((item) => WalletHistoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load wallet history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet History")),
      body: FutureBuilder<List<WalletHistoryModel>>(
        future: fetchWalletHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No History Yet found'));
          } else {
            final data = snapshot.data!;
            return SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                  columns: const [
                    DataColumn(
                      label: Text(
                        "No.",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "User Name",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Mobile",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Type",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Points",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Balance After",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Description",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Date",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: List.generate(data.length, (index) {
                    final item = data[index];
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
                              'dd MMM yyyy, hh:mm a',
                            ).format(item.date),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
