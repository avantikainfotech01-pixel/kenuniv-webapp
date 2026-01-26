import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class KycVerificationScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userMobile;
  final String userAddress;
  final String redemptionId;
  final String redemptionStatus;

  const KycVerificationScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userMobile,
    required this.userAddress,
    required this.redemptionId,
    required this.redemptionStatus,
  });

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  String kycFrontUrl = "";
  String kycBackUrl = "";
  String kycStatus = "pending";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchKycDetails();
  }

  Future<void> _fetchKycDetails() async {
    try {
      final res = await http.get(
        Uri.parse("http://api.kenuniv.com/api/kyc/user/${widget.userId}"),
        headers: {"Content-Type": "application/json"},
      );
      final data = jsonDecode(res.body);
      final kycData = data['data'] ?? {};
      final frontImage = kycData['frontImage'] ?? '';
      final backImage = kycData['backImage'] ?? '';

      setState(() {
        kycFrontUrl = frontImage.isNotEmpty
            ? "http://api.kenuniv.com/uploads/kyc/$frontImage"
            : "";
        kycBackUrl = backImage.isNotEmpty
            ? "http://api.kenuniv.com/uploads/kyc/$backImage"
            : "";
        kycStatus = (kycData['status'] ?? "pending").toString();
        if (kycStatus == "none") {
          kycFrontUrl = "";
          kycBackUrl = "";
        }
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load KYC details")),
      );
    }
  }
  // import provider or wherever you keep admin token if needed
  // import 'package:flutter_riverpod/flutter_riverpod.dart'; // if using riverpod

  Future<void> _approveKyc() async {
    setState(() => loading = true);

    try {
      // 1) Get latest KYC record for the user (to obtain kycDocId)
      final getRes = await http.get(
        Uri.parse(
          "http://api.kenuniv.com/api/kyc/user/${widget.userId}",
        ), // no extra /api
        headers: {"Content-Type": "application/json"},
      );

      if (getRes.statusCode != 200) {
        final body = getRes.body;
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to fetch KYC (status ${getRes.statusCode}): $body",
            ),
          ),
        );
        return;
      }

      final getJson = jsonDecode(getRes.body);
      final kycData = getJson['data'];
      if (kycData == null || kycData['_id'] == null) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No KYC document found for this user")),
        );
        return;
      }

      final String kycDocId = kycData['_id'];

      // 2) Call status update endpoint using kycDocId
      // NOTE: change method to PUT if your server expects PUT.
      final Map<String, String> headers = {"Content-Type": "application/json"};
      // If your admin panel requires auth, attach token here.
      // Replace this with how you actually retrieve the admin token:
      // final adminToken = await getAdminToken();
      // if (adminToken != null) headers['Authorization'] = 'Bearer $adminToken';
      // If your app stores token in memory/provider, fetch it and add header.

      final patchRes = await http.put(
        Uri.parse("http://api.kenuniv.com/api/kyc/status/$kycDocId"),
        headers: headers,
        body: jsonEncode({"status": "approved"}),
      );

      final patchBody = patchRes.body;
      setState(() => loading = false);

      if (patchRes.statusCode == 200) {
        final parsed = jsonDecode(patchBody);
        if (parsed['success'] == true) {
          setState(() => kycStatus = "approved");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("KYC approved")));
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Approve failed: ${parsed['message'] ?? patchBody}",
              ),
            ),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Approve failed (${patchRes.statusCode}): $patchBody",
            ),
          ),
        );
        return;
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Server error: $e")));
    }
  }

  Future<void> _rejectKyc() async {
    setState(() => loading = true);
    try {
      final getRes = await http.get(
        Uri.parse("http://api.kenuniv.com/api/kyc/user/${widget.userId}"),
        headers: {"Content-Type": "application/json"},
      );

      if (getRes.statusCode != 200) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch KYC: ${getRes.body}")),
        );
        return;
      }

      final getJson = jsonDecode(getRes.body);
      final kycData = getJson['data'];
      if (kycData == null || kycData['_id'] == null) {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("No KYC document found")));
        return;
      }

      final String kycDocId = kycData['_id'];

      final patchRes = await http.put(
        Uri.parse("http://api.kenuniv.com/api/kyc/status/$kycDocId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": "rejected"}),
      );

      setState(() => loading = false);

      if (patchRes.statusCode == 200) {
        setState(() => kycStatus = "rejected");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("KYC rejected")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reject failed: ${patchRes.body}")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Server error: $e")));
    }
  }

  Widget _buildKycImageCard(String imageUrl, String label) {
    return Card(
      elevation: 2,
      child: Container(
        height: 250,
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          Center(child: Text("$label image not available")),
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                    )
                  : Center(child: Text("No $label Image")),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KYC Verification"),
        backgroundColor: Colors.red.shade700,
        elevation: 2,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Name: ${widget.userName}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Mobile: ${widget.userMobile}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Address: ${widget.userAddress}",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text(
                                "KYC Status: ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: kycStatus == "approved"
                                      ? Colors.green.withOpacity(0.15)
                                      : kycStatus == "rejected"
                                      ? Colors.red.withOpacity(0.15)
                                      : Colors.orange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  kycStatus.toUpperCase(),
                                  style: TextStyle(
                                    color: kycStatus == "approved"
                                        ? Colors.green.shade700
                                        : kycStatus == "rejected"
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildKycImageCard(kycFrontUrl, "Front Side"),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildKycImageCard(kycBackUrl, "Back Side"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      if (kycStatus != "approved")
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _approveKyc,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.green.shade700,
                            ),
                            child: const Text(
                              "Approve",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (kycStatus != "approved") const SizedBox(width: 12),
                      if (kycStatus != "rejected")
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _rejectKyc,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.red.shade700,
                            ),
                            child: const Text(
                              "Reject",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (kycStatus == "approved")
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        "KYC Approved",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  if (kycStatus == "rejected")
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        "KYC Rejected",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
