import 'package:flutter/material.dart';

class RedemptionHistory extends StatefulWidget {
  const RedemptionHistory({super.key});

  @override
  State<RedemptionHistory> createState() => _RedemptionHistoryState();
}

class _RedemptionHistoryState extends State<RedemptionHistory> {
  @override
  Widget build(BuildContext context) {
    // Prepare dummy data for static table, now including Qty
    final List<Map<String, String>> data = [
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "1",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "1200 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "2",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "100 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "1",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "1300 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "3",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "1400 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "1",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "300 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "2",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "1600 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "1",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "200 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "1",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "400 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "2",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "310 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "qty": "1",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "3120 Pts",
      },
    ];
    return Scaffold(
      appBar: AppBar(title: const Text("Redemption History")),
      body: SingleChildScrollView(
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
            rows: List.generate(data.length, (index) {
              final item = data[index];
              return DataRow(
                cells: [
                  DataCell(Text("${index + 1}")),
                  DataCell(Text(item["qr"] ?? "")),
                  DataCell(Text(item["product"] ?? "")),
                  DataCell(Text(item["qty"] ?? "")),
                  DataCell(Text(item["redeemedBy"] ?? "")),
                  DataCell(Text(item["date"] ?? "")),
                  DataCell(Text(item["points"] ?? "")),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
