import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kenuniv/core/api_service.dart';
import 'package:kenuniv/utils/constant.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/qr_provider.dart';
import '../../providers/auth_provider.dart';

class QrCodeScreen extends ConsumerStatefulWidget {
  const QrCodeScreen({super.key});

  @override
  ConsumerState<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends ConsumerState<QrCodeScreen> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _activeStartController = TextEditingController();
  final _activeEndController = TextEditingController();
  int _selectedPoints = 10;
  List<dynamic> _qrList = [];
  bool _showAll = false;
  bool _loading = false;
  int? _nextStart;
  List<dynamic> _qrHistory = [];
  bool _loadingHistory = false;
  List<dynamic> _pointsList = [];

  Future<void> _fetchPointMaster() async {
    try {
      final response = await ApiService(
        token: '',
      ).getRequest('$baseUrl/api/point/points');
      if (response != null) {
        setState(() {
          _pointsList = response; // response should be a list of point objects
          if (_pointsList.isNotEmpty) {
            _selectedPoints = _pointsList[0]['points']; // default selection
          }
        });
      }
    } catch (e) {
      print("Failed to fetch point master: $e");
    }
  }

  Future<void> _fetchNextStart() async {
    final response = await ApiService(
      token: '',
    ).getRequest("$baseUrl/api/qr-history");
    if (response["history"].isNotEmpty) {
      setState(() {
        _nextStart = response["history"][0]["endSerial"] + 1;
        _startController.text = _nextStart.toString();
      });
    } else {
      setState(() {
        _nextStart = 1;
        _startController.text = "1";
      });
    }
  }

  Future<void> _generateQR() async {
    final start = _startController.text.trim();
    final end = _endController.text.trim();

    if (start.isEmpty || end.isEmpty) return;

    setState(() {
      _loading = true;
      _qrList = [];
      _showAll = false;
    });
    try {
      await ref
          .read(qrProvider.notifier)
          .generateQrs(
            serialFrom: int.parse(start),
            serialTo: int.parse(end),
            points: _selectedPoints,
          );
      // After generating, fetch the updated QR list from the provider
      final qrs = ref.read(qrProvider);
      setState(() {
        _qrList = qrs;
        _loading = false;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('QR Codes Generated'),
            content: const Text('QR codes have been generated successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() => _loading = false);
      if (e.toString().contains('already exists')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 3),
            content: Text('Some serial numbers already exist and were skipped'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate QR: $e')));
      }
    }
  }

  Future<void> _fetchQrHistory() async {
    setState(() {
      _loadingHistory = true;
    });
    try {
      final response = await ApiService(
        token: '',
      ).getRequest("$baseUrl/api/qr-history");
      final history = response["history"] ?? []; // ensure it's a list
      setState(() {
        _qrHistory = history;
        _loadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _loadingHistory = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchQrHistory();
    _fetchNextStart();
    _fetchPointMaster();
    _activeStartController.text = "1";
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final canWrite = authState.permissions?['qr'] ?? false;
    return Container(
      color: const Color(0xFFFfffff),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR Code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'QR Code Generate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Serial Number'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startController,
                    decoration: const InputDecoration(
                      hintText: 'Start No.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.compare_arrows),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _endController,
                    decoration: const InputDecoration(
                      hintText: 'End No.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedPoints,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Select Point',
                    ),
                    items: _pointsList.map<DropdownMenuItem<int>>((point) {
                      return DropdownMenuItem(
                        value: point['points'],
                        child: Text('${point['points']} (${point['code']})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() {
                      _selectedPoints = val!;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffC02221),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                onPressed: (!canWrite || _loading) ? null : _generateQR,
                child: const Text(
                  'Generate QR',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Replace your existing preview section with this code:
            if (_qrList.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 220,
                    height: 160,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFB8860B),
                            Color(0xFFDAA520),
                            Color(0xFFF4A460),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF4A90E2), width: 2),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Color(0xFF4A90E2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    shrinkWrap: true,
                                    mainAxisSpacing: 4,
                                    crossAxisSpacing: 4,
                                    physics: NeverScrollableScrollPhysics(),
                                    childAspectRatio: 0.8,
                                    children: _qrList.take(4).map((qr) {
                                      return Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 1,
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Image.network(
                                                qr.qrImage,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Expanded(
                                              flex: 1,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'S:${qr.serial}',
                                                    style: TextStyle(
                                                      fontSize: 7,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    'C:${qr.uniqueCode}',
                                                    style: TextStyle(
                                                      fontSize: 6,
                                                      color: Colors.black54,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4A90E2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '220 × 160',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Blue corner handles
                          Positioned(
                            top: -1,
                            left: -1,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Color(0xFF4A90E2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Color(0xFF4A90E2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -1,
                            left: -1,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Color(0xFF4A90E2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -1,
                            right: -1,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Color(0xFF4A90E2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // +X indicator (if you have more than 4 QR codes)
                          if (_qrList.length > 4)
                            Positioned(
                              bottom: 15,
                              right: 15,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${_qrList.length - 4}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        // PDF generation with ALL QR codes (including hidden ones)
                        final pdf = pw.Document();
                        for (int i = 0; i < _qrList.length; i += 24) {
                          final batch = _qrList.skip(i).take(24).toList();
                          final qrWidgets = <pw.Widget>[];
                          for (var qr in batch) {
                            final imageProvider = await networkImage(
                              qr.qrImage,
                            );
                            qrWidgets.add(
                              pw.Column(
                                mainAxisSize: pw.MainAxisSize.min,
                                children: [
                                  pw.Image(
                                    imageProvider,
                                    height: 50,
                                    width: 50,
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    'Serial: ${qr.serial}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                                  pw.Text(
                                    'Code: ${qr.uniqueCode}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                                ],
                              ),
                            );
                          }
                          pdf.addPage(
                            pw.Page(
                              build: (pw.Context context) {
                                return pw.GridView(
                                  crossAxisCount: 6,
                                  children: qrWidgets,
                                );
                              },
                            ),
                          );
                        }

                        if (kIsWeb) {
                          await Printing.sharePdf(
                            bytes: await pdf.save(),
                            filename: 'qr_codes.pdf',
                          );
                        } else {
                          final output = await getTemporaryDirectory();
                          final file = File("${output.path}/qr_codes.pdf");
                          await file.writeAsBytes(await pdf.save());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('PDF saved to: ${file.path}'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Generate PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xffC02221),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // NEW BUTTON: Pre-Printed Sheet PDF
                  Container(
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final pdf = pw.Document();

                        // Pre-Printed Sheet background color from selected point
                        final bgColorHex = _pointsList.firstWhere(
                          (p) => p['points'] == _selectedPoints,
                          orElse: () => {'color': '#FFFFFF'},
                        )['color'];

                        final bgColor = PdfColor.fromInt(
                          int.parse(
                            bgColorHex.replaceFirst('#', 'FF'),
                            radix: 16,
                          ),
                        );

                        // Watermark text (using point code)
                        final watermark = _pointsList.firstWhere(
                          (p) => p['points'] == _selectedPoints,
                          orElse: () => {'code': ''},
                        )['code'];

                        for (int i = 0; i < _qrList.length; i += 24) {
                          final batch = _qrList.skip(i).take(24).toList();
                          final qrWidgets = <pw.Widget>[];

                          for (var qr in batch) {
                            final imageProvider = await networkImage(
                              qr.qrImage,
                            );
                            qrWidgets.add(
                              pw.Stack(
                                children: [
                                  pw.Positioned(
                                    child: pw.Opacity(
                                      opacity: 0.1,
                                      child: pw.Text(
                                        watermark,
                                        style: pw.TextStyle(
                                          fontSize: 40,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  pw.Column(
                                    children: [
                                      pw.Image(
                                        imageProvider,
                                        height: 50,
                                        width: 50,
                                      ),
                                      pw.SizedBox(height: 4),
                                      pw.Text(
                                        'Serial: ${qr.serial}',
                                        style: const pw.TextStyle(fontSize: 8),
                                      ),
                                      pw.Text(
                                        'Code: ${qr.uniqueCode}',
                                        style: const pw.TextStyle(fontSize: 8),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }

                          pdf.addPage(
                            pw.Page(
                              pageTheme: pw.PageTheme(
                                buildBackground: (context) =>
                                    pw.Container(color: bgColor),
                              ),
                              build: (pw.Context context) {
                                return pw.GridView(
                                  crossAxisCount: 6,
                                  children: qrWidgets,
                                );
                              },
                            ),
                          );
                        }

                        if (kIsWeb) {
                          await Printing.sharePdf(
                            bytes: await pdf.save(),
                            filename: 'qr_preprinted.pdf',
                          );
                        }
                      },
                      child: const Text(
                        'Pre-Printed Sheet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xffC02221),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // NEW BUTTON: Black & White PDF (Default)
                  Container(
                    height: 35,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        final pdf = pw.Document();

                        for (int i = 0; i < _qrList.length; i += 24) {
                          final batch = _qrList.skip(i).take(24).toList();
                          final qrWidgets = <pw.Widget>[];

                          for (var qr in batch) {
                            final imageProvider = await networkImage(
                              qr.qrImage,
                            );
                            qrWidgets.add(
                              pw.Column(
                                children: [
                                  pw.Image(
                                    imageProvider,
                                    height: 50,
                                    width: 50,
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    'Serial: ${qr.serial}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                                  pw.Text(
                                    'Code: ${qr.uniqueCode}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                                ],
                              ),
                            );
                          }

                          pdf.addPage(
                            pw.Page(
                              build: (pw.Context context) {
                                return pw.GridView(
                                  crossAxisCount: 6,
                                  children: qrWidgets,
                                );
                              },
                            ),
                          );
                        }

                        if (kIsWeb) {
                          await Printing.sharePdf(
                            bytes: await pdf.save(),
                            filename: 'qr_bw.pdf',
                          );
                        }
                      },
                      child: const Text(
                        'Black & White PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xffC02221),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 30),
            const Text(
              'Active Or Inactive QR Codes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Serial Number'),
            const SizedBox(height: 8),

            // --- END Current Status Display ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _activeStartController,
                    decoration: const InputDecoration(
                      hintText: 'Start No.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.compare_arrows),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _activeEndController,
                    decoration: const InputDecoration(
                      hintText: 'End No.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onPressed: !canWrite
                      ? null
                      : () async {
                          final start = _activeStartController.text.trim();
                          final end = _activeEndController.text.trim();

                          if (start.isEmpty || end.isEmpty) return;

                          try {
                            await ref
                                .read(qrProvider.notifier)
                                .activateQrs(
                                  serialFrom: int.parse(start),
                                  serialTo: int.parse(end),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'QR Codes activated successfully',
                                ),
                              ),
                            );
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('QR Codes Activated'),
                                  content: const Text(
                                    'Selected QR codes have been activated successfully.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Activation failed: $e')),
                            );
                          }
                        },
                  child: const Text(
                    'Active',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onPressed: !canWrite
                      ? null
                      : () async {
                          final start = _activeStartController.text.trim();
                          final end = _activeEndController.text.trim();

                          if (start.isEmpty || end.isEmpty) return;

                          try {
                            await ref
                                .read(qrProvider.notifier)
                                .inactivateQrs(
                                  serialFrom: int.parse(start),
                                  serialTo: int.parse(end),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'QR Codes inactivated successfully',
                                ),
                              ),
                            );
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('QR Codes Inactivated'),
                                  content: const Text(
                                    'Selected QR codes have been inactivated successfully.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Inactivation failed: $e'),
                              ),
                            );
                          }
                        },
                  child: const Text(
                    'Inactive',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            // QR Generation History Section
            const Text(
              'QR Generation History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingHistory)
              const Center(child: CircularProgressIndicator())
            else if (_qrHistory.isEmpty)
              const Text('No QR generation history found.')
            else
              Container(
                width: double.infinity,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Start Serial')),
                    DataColumn(label: Text('End Serial')),
                    DataColumn(label: Text('Points')),
                    DataColumn(label: Text('Created At')),
                    DataColumn(label: Text('PDF')),
                  ],
                  rows: _qrHistory.map<DataRow>((record) {
                    final DateTime? createdAt = record['createdAt'] != null
                        ? DateTime.tryParse(record['createdAt'])
                        : null;
                    return DataRow(
                      cells: [
                        DataCell(Text('${record['startSerial']}')),
                        DataCell(Text('${record['endSerial']}')),
                        DataCell(Text('${record['points']}')),
                        DataCell(
                          Text(
                            createdAt != null
                                ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
                                : '',
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                            ),
                            tooltip: 'Re-download PDF',
                            onPressed: () async {
                              final recordId = record['_id'];
                              final pdfUrl =
                                  "${baseUrl}/qr/qr-history/pdf/$recordId";

                              if (kIsWeb) {
                                try {
                                  final response =
                                      await html.HttpRequest.request(
                                        pdfUrl,
                                        method: 'GET',
                                        responseType: 'blob',
                                      );

                                  if (response.status == 200) {
                                    final blob = response.response as html.Blob;
                                    final url =
                                        html.Url.createObjectUrlFromBlob(blob);

                                    final anchor = html.AnchorElement(href: url)
                                      ..download = 'qr_history.pdf'
                                      ..click();

                                    html.Url.revokeObjectUrl(url);
                                  } else {
                                    print('HTTP Error: ${response.status}');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to download PDF (Status ${response.status})',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print('Error downloading PDF: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Download failed — check CORS or server headers.',
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                // For mobile/desktop builds
                                final resp = await http.get(Uri.parse(pdfUrl));
                                if (resp.statusCode == 200) {
                                  final bytes = resp.bodyBytes;
                                  await Printing.sharePdf(
                                    bytes: bytes,
                                    filename: 'qr_history_${recordId}.pdf',
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to download PDF (${resp.statusCode})',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
