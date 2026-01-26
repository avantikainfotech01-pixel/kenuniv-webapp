import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kenuniv/core/api_service.dart';
import 'package:kenuniv/utils/constant.dart';
import 'kyc_verification_screen.dart';

class KycListScreen extends StatefulWidget {
  const KycListScreen({Key? key}) : super(key: key);

  @override
  State<KycListScreen> createState() => _KycListScreenState();
}

class _KycListScreenState extends State<KycListScreen> {
  List<dynamic> kycList = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchKycList();
  }

  Future<void> fetchKycList() async {
    try {
      final res = await ApiService(
        token: '',
      ).getRequest('$baseUrl/api/kyc/admin/kyc');
      if (res['success'] == true) {
        setState(() {
          kycList = uniqueLatestPerUser(res['data']);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // Keep only one latest KYC entry per user
  List<dynamic> uniqueLatestPerUser(List<dynamic> list) {
    final Map<String, dynamic> latestMap = {};

    for (var item in list) {
      final dynamic userField = item['userId'];

      // Handle both ObjectId string and populated object cases
      final String? userId = userField is Map
          ? userField['_id']?.toString()
          : userField?.toString();

      if (userId == null) continue;

      final existing = latestMap[userId];

      if (existing == null) {
        latestMap[userId] = item;
      } else {
        final DateTime existingDate = DateTime.parse(existing['createdAt']);
        final DateTime newDate = DateTime.parse(item['createdAt']);

        if (newDate.isAfter(existingDate)) {
          latestMap[userId] = item;
        }
      }
    }

    return latestMap.values.toList();
  }

  String formatDate(String? date) {
    if (date == null) return '-';
    final d = DateTime.parse(date);
    return DateFormat('dd MMM yyyy, hh:mm a').format(d);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification List')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : kycList.isEmpty
          ? const Center(child: Text('No KYC requests found'))
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('#')),
                      DataColumn(label: Text('User ID')),
                      DataColumn(label: Text('Document Type')),
                      DataColumn(label: Text('Front Image')),
                      DataColumn(label: Text('Back Image')),
                      DataColumn(label: Text('Date & Time')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: List.generate(kycList.length, (index) {
                      final item = kycList[index];
                      // Normalize userId whether it is String or populated Map
                      final String uid = (item['userId'] is Map)
                          ? item['userId']['_id']?.toString() ?? ''
                          : item['userId']?.toString() ?? '';

                      // Safely read user info only when populated object exists
                      final String uName = (item['userId'] is Map)
                          ? item['userId']['name']?.toString() ?? ''
                          : '';

                      final String uMobile = (item['userId'] is Map)
                          ? item['userId']['mobile']?.toString() ?? ''
                          : '';

                      final String uAddress = (item['userId'] is Map)
                          ? item['userId']['address']?.toString() ?? ''
                          : '';

                      final status = item['status'] ?? 'pending';

                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(uid.isEmpty ? '-' : uid)),
                          DataCell(
                            Text(item['documentType']?.toString() ?? '-'),
                          ),
                          DataCell(Text(item['frontImage']?.toString() ?? '-')),
                          DataCell(Text(item['backImage']?.toString() ?? '-')),
                          DataCell(Text(formatDate(item['createdAt']))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(status).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => KycVerificationScreen(
                                      userId: uid,
                                      userName: uName,
                                      userMobile: uMobile,
                                      userAddress: uAddress,
                                      redemptionId: '',
                                      redemptionStatus: status,
                                    ),
                                  ),
                                ).then((_) => fetchKycList());
                              },
                              child: const Text('Verify KYC'),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}
