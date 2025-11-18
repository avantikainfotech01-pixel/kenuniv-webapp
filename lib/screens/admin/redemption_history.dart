// lib/screens/admin/redemption_history.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RedemptionHistory extends StatefulWidget {
  const RedemptionHistory({super.key});

  @override
  State<RedemptionHistory> createState() => _RedemptionHistoryState();
}

class _RedemptionHistoryState extends State<RedemptionHistory> {
  List<dynamic> redemptionList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRedemptionHistory();
  }

  Future<void> _fetchRedemptionHistory() async {
    try {
      final res = await http.get(
        Uri.parse("http://api.kenuniv.com/api/wallet/redeem-history"),
      );
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          redemptionList = body['data'] ?? [];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  String formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return "${d.day}/${d.month}/${d.year} (${d.hour}:${d.minute})";
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Redemption History")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        "QR No.",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Product Name",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Qty",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Redeemed By",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Redemption Date",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Redeemed Points",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: List.generate(redemptionList.length, (index) {
                    final item = redemptionList[index];
                    final qr = item['qrSerial'] ?? "-";
                    final product =
                        item['schemeId']?['productName'] ??
                        item['schemeId']?['schemeName'] ??
                        "";
                    final user = item['userId']?['name'] ?? "";
                    final date = formatDate(item['createdAt'] ?? "");
                    final pts = item['pointsUsed']?.toString() ?? "0";

                    return DataRow(
                      cells: [
                        DataCell(Text("${index + 1}")),
                        DataCell(Text(qr)),
                        DataCell(Text(product)),
                        DataCell(const Text("1")),
                        DataCell(Text(user)),
                        DataCell(Text(date)),
                        DataCell(Text("$pts Pts")),
                      ],
                    );
                  }),
                ),
              ),
            ),
    );
  }
}
