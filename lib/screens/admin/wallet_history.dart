import 'package:flutter/material.dart';

class WalletHistory extends StatefulWidget {
  const WalletHistory({super.key});

  @override
  State<WalletHistory> createState() => _WalletHistoryState();
}

class _WalletHistoryState extends State<WalletHistory> {
  @override
  Widget build(BuildContext context) {
    // Prepare dummy data for static table, ready for dynamic usage
    final List<Map<String, String>> data = [
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "1200 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "100 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "1300 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "1400 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "300 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "1600 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "200 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "400 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "310 Pts",
      },
      {
        "qr": "0121230314",
        "product": "Tshirt",
        "redeemedBy": "User Name",
        "date": "02/09/2025 (09:00 PM)",
        "points": "3120 Pts",
      },
    ];
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet History")),
      body: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          columns: const [
            DataColumn(
              label: Text("No.", style: TextStyle(fontWeight: FontWeight.bold)),
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
                DataCell(Text(item["redeemedBy"] ?? "")),
                DataCell(Text(item["date"] ?? "")),
                DataCell(Text(item["points"] ?? "")),
              ],
            );
          }),
        ),
      ),
    );
  }
}
