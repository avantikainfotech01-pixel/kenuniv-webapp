// lib/screens/admin/redemption_history.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kenuniv/screens/admin/kyc_verification_screen.dart';

class RedemptionHistory extends StatefulWidget {
  const RedemptionHistory({super.key});

  @override
  State<RedemptionHistory> createState() => _RedemptionHistoryState();
}

class _RedemptionHistoryState extends State<RedemptionHistory> {
  Future<void> _showDispatchDialog(Map item, int rowIndex) async {
    final TextEditingController courierController = TextEditingController();
    final TextEditingController trackingController = TextEditingController();
    bool isLoading = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Dispatch Courier"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: courierController,
                    decoration: const InputDecoration(
                      labelText: "Courier Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: trackingController,
                    decoration: const InputDecoration(
                      labelText: "Tracking Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (courierController.text.trim().isEmpty ||
                              trackingController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please enter all fields"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() => isLoading = true);
                          try {
                            final res = await http.patch(
                              Uri.parse(
                                "http://api.kenuniv.com/api/wallet/redeem-history/${item['_id']}/dispatch",
                              ),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({
                                "courierName": courierController.text.trim(),
                                "trackingNumber": trackingController.text
                                    .trim(),
                              }),
                            );
                            final body = jsonDecode(res.body);
                            if (body['success'] == true) {
                              // Update the row's status and fields
                              setState(() {
                                item['status'] = "dispatched";
                                item['courierName'] = courierController.text
                                    .trim();
                                item['trackingNumber'] = trackingController.text
                                    .trim();
                              });
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Dispatched successfully"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refresh UI
                              this.setState(() {});
                            } else {
                              setState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    body['message'] ?? "Server error",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Dispatch"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<dynamic> redemptionList = [];
  bool loading = true;
  Map<String, String> kycStatusMap = {};

  String filterProduct = "";
  String filterName = "";
  String filterMobile = "";
  String? filterKycStatus;
  DateTimeRange? filterDateRange;

  List<dynamic> filteredList = [];

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
          filteredList = redemptionList;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      filteredList = redemptionList.where((item) {
        final product =
            (item['schemeId']?['productName'] ??
                    item['schemeId']?['schemeName'] ??
                    "")
                .toString()
                .toLowerCase();
        final name = (item['userId']?['name'] ?? "").toString().toLowerCase();
        final mobile = (item['userId']?['mobile'] ?? "").toString();
        final createdAt = item['createdAt'] != null
            ? DateTime.tryParse(item['createdAt'])
            : null;
        final kycStatus = kycStatusMap[item['userId']?['_id']] ?? "pending";

        bool matchesProduct =
            filterProduct.isEmpty ||
            product.contains(filterProduct.toLowerCase());
        bool matchesName =
            filterName.isEmpty || name.contains(filterName.toLowerCase());
        bool matchesMobile =
            filterMobile.isEmpty || mobile.contains(filterMobile);
        bool matchesKyc =
            filterKycStatus == null ||
            kycStatus.toLowerCase() == filterKycStatus!.toLowerCase();

        bool matchesDate = true;
        if (filterDateRange != null && createdAt != null) {
          matchesDate =
              createdAt.isAfter(
                filterDateRange!.start.subtract(const Duration(days: 1)),
              ) &&
              createdAt.isBefore(
                filterDateRange!.end.add(const Duration(days: 1)),
              );
        }

        return matchesProduct &&
            matchesName &&
            matchesMobile &&
            matchesKyc &&
            matchesDate;
      }).toList();
    });
  }

  Future<void> _fetchKycForUser(String userId) async {
    try {
      final res = await http.get(
        Uri.parse("http://api.kenuniv.com/api/kyc/user/$userId"),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final status = body['data']?['status'] ?? "pending";

        setState(() {
          kycStatusMap[userId] = status;
        });
      }
    } catch (_) {}
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 220,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: "Filter by Product",
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                filterProduct = v;
                                _applyFilters();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: "Filter by Name",
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                filterName = v;
                                _applyFilters();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: "Filter by Mobile",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              onChanged: (v) {
                                filterMobile = v;
                                _applyFilters();
                              },
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "KYC Status",
                                border: OutlineInputBorder(),
                              ),
                              value: filterKycStatus,
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text("All"),
                                ),
                                DropdownMenuItem(
                                  value: "pending",
                                  child: Text("Pending"),
                                ),
                                DropdownMenuItem(
                                  value: "approved",
                                  child: Text("Approved"),
                                ),
                                DropdownMenuItem(
                                  value: "rejected",
                                  child: Text("Rejected"),
                                ),
                              ],
                              onChanged: (v) {
                                filterKycStatus = v;
                                _applyFilters();
                              },
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (range != null) {
                                filterDateRange = range;
                                _applyFilters();
                              }
                            },
                            child: const Text("Select Date Range"),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                filterProduct = "";
                                filterName = "";
                                filterMobile = "";
                                filterKycStatus = null;
                                filterDateRange = null;
                                filteredList = redemptionList;
                              });
                            },
                            child: const Text("Clear Filters"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // allow horizontal scroll

                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      child: DataTable(
                        dataRowHeight: 70, // gives height so dropdown fits

                        columnSpacing: 45,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey[200],
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              "No.",
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
                          DataColumn(
                            label: Text(
                              "KYC Status",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "KYC Document",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Address",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Dispatch",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Action",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: List.generate(filteredList.length, (index) {
                          final item = filteredList[index];
                          final product =
                              item['schemeId']?['productName'] ??
                              item['schemeId']?['schemeName'] ??
                              "";
                          final user = item['userId']?['name'] ?? "";
                          final mobile = item['userId']?['mobile'] ?? "";
                          final date = formatDate(item['createdAt'] ?? "");
                          final pts = item['pointsUsed']?.toString() ?? "0";
                          final status = item['status'] ?? "pending";
                          final kycDoc = item['userId']?['kycDocument'] ?? "";
                          final address = item['userId']?['address'] ?? "";
                          final userId = item['userId']?['_id'];
                          String kycStatus = kycStatusMap[userId] ?? "loading";

                          if (!kycStatusMap.containsKey(userId)) {
                            _fetchKycForUser(userId);
                          }

                          // --- Dispatch logic
                          Widget dispatchCell;
                          if (item['status'] == "approved") {
                            dispatchCell = ElevatedButton(
                              onPressed: () => _showDispatchDialog(item, index),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 40),
                              ),
                              child: const Text("Dispatch"),
                            );
                          } else if (item['status'] == "dispatched") {
                            dispatchCell = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Dispatched",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (item['courierName'] != null &&
                                    item['courierName'].toString().isNotEmpty)
                                  Text("Courier: ${item['courierName']}"),
                                if (item['trackingNumber'] != null &&
                                    item['trackingNumber']
                                        .toString()
                                        .isNotEmpty)
                                  Text("Tracking: ${item['trackingNumber']}"),
                              ],
                            );
                          } else if (item['status'] == "delivered") {
                            dispatchCell = const Text(
                              "Delivered",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          } else {
                            dispatchCell = const Text(
                              "-",
                              style: TextStyle(color: Colors.grey),
                            );
                          }

                          // --- Mark Delivered logic
                          Widget actionCell;
                          if (item['status'] == "approved") {
                            actionCell = const Text(
                              "Approved",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          } else if (item['status'] == "dispatched") {
                            actionCell = ElevatedButton(
                              onPressed: () async {
                                try {
                                  final res = await http.patch(
                                    Uri.parse(
                                      "http://api.kenuniv.com/api/wallet/redeem-history/${item['_id']}/deliver",
                                    ),
                                    headers: {
                                      "Content-Type": "application/json",
                                    },
                                  );
                                  final body = jsonDecode(res.body);
                                  if (body['success'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Marked as Delivered"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    setState(() {
                                      item['status'] = "delivered";
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          body['message'] ?? "Server error",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 40),
                              ),
                              child: const Text("Mark Delivered"),
                            );
                          } else if (item['status'] == "delivered") {
                            actionCell = const Text(
                              "Delivered",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          } else if (kycStatus == "approved") {
                            actionCell = ElevatedButton(
                              onPressed: () async {
                                try {
                                  final res = await http.patch(
                                    Uri.parse(
                                      "http://api.kenuniv.com/api/wallet/redeem-history/${item['_id']}/approve",
                                    ),
                                    headers: {
                                      "Content-Type": "application/json",
                                    },
                                  );
                                  final body = jsonDecode(res.body);

                                  if (body['success'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Redemption Approved"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    setState(() {
                                      item['status'] = "approved";
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          body['message'] ?? "Server error",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: $e"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 40),
                              ),
                              child: const Text("Approve"),
                            );
                          } else {
                            actionCell = const Text(
                              "KYC Pending",
                              style: TextStyle(color: Colors.grey),
                            );
                          }

                          return DataRow(
                            cells: [
                              DataCell(Text("${index + 1}")),
                              DataCell(Text(product)),
                              const DataCell(Text("1")),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user),
                                    Text(
                                      mobile,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(date)),
                              DataCell(Text("$pts Points")),
                              DataCell(
                                Text(
                                  kycStatus.toUpperCase(),
                                  style: TextStyle(
                                    color: kycStatus == "approved"
                                        ? Colors.green
                                        : (kycStatus == "rejected"
                                              ? Colors.red
                                              : Colors.orange),
                                  ),
                                ),
                              ),
                              // KYC Document cell navigates to KycVerificationScreen
                              DataCell(
                                InkWell(
                                  onTap: () {
                                    if (userId == null) return;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => KycVerificationScreen(
                                          userId: userId,
                                          userName:
                                              item['userId']?['name'] ?? '',
                                          userMobile:
                                              item['userId']?['mobile'] ?? '',
                                          userAddress:
                                              item['userId']?['address'] ?? '',
                                          redemptionId: item['_id'],
                                          redemptionStatus:
                                              item['status'] ?? 'pending',
                                        ),
                                      ),
                                    ).then((_) {
                                      _fetchKycForUser(userId);
                                    });
                                  },
                                  child: const Text(
                                    "View KYC",
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                              // Address column (separate)
                              DataCell(Text(address)),
                              DataCell(dispatchCell),
                              DataCell(actionCell),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
