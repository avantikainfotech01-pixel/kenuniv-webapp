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
  int? _selectedPoints;
  List<dynamic> _qrList = [];
  bool _showAll = false;
  bool _loading = false;
  int? _nextStart;
  List<dynamic> _qrHistory = [];
  bool _loadingHistory = false;
  List<dynamic> _pointsList = [];

  int _loadingPdfIndex = 0;

  // ==========================================
  // LOGOS AND LAYOUT BUILDERS
  // ==========================================

  // 1. English Logo (KENUNIV)
  pw.Widget _buildKenunivLogo({bool isBw = false}) {
    return pw.Container(
      width: 70,
      color: PdfColors.white,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.RichText(
            text: pw.TextSpan(
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              children: [
                pw.TextSpan(
                  text: 'KEN',
                  style: const pw.TextStyle(color: PdfColors.black),
                ),
                pw.TextSpan(
                  text: 'UNIV',
                  style: pw.TextStyle(
                    color: isBw ? PdfColors.black : PdfColors.red,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 1),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 1),
            child: pw.Text(
              'TM',
              style: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
                fontSize: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Hindi Logo (केनयुनिव)
  pw.Widget _buildHindiKenunivLogo({bool isBw = false}) {
    return pw.Container(
      width: 70,
      color: PdfColors.white,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          children: [
            pw.TextSpan(
              text: 'केन',
              style: const pw.TextStyle(color: PdfColors.black),
            ),
            pw.TextSpan(
              text: 'यूिनव',
              style: pw.TextStyle(
                color: isBw ? PdfColors.black : PdfColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // LAYOUT 2: Final Layout with Icons and proper T&C placement
  // ------------------------------------------------------------------
  pw.Widget _buildLayout2(
    dynamic qr,
    pw.ImageProvider imageProvider,
    pw.Font iconFont, {
    bool isBw = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: isBw ? PdfColors.black : PdfColors.grey,
          width: 1,
          style: pw.BorderStyle.dashed,
        ),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          // TOP SECTION: Text on left, QR on right
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Left Column
              pw.Container(
                width: 72,
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildKenunivLogo(isBw: isBw),
                    pw.SizedBox(height: 2),
                    _buildHindiKenunivLogo(isBw: isBw),
                    pw.SizedBox(height: 6),
                    // Phone Icon + Number
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Icon(
                          const pw.IconData(0xe0cd),
                          font: iconFont,
                          size: 7,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(width: 2),
                        pw.Text(
                          '1800 890 7606',
                          softWrap: false,
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'www.kenuniv.com',
                      softWrap: false,
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(width: 6),

              // Right Column: QR Code + Unique Code
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(imageProvider, height: 56, width: 56),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${qr.uniqueCode}',
                    softWrap: false,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 5),

          // BOTTOM SECTION: Terms & Conditions at bottom center
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Icon(
                const pw.IconData(0xe88e),
                font: iconFont,
                size: 5,
                color: PdfColors.black,
              ),
              pw.SizedBox(width: 2),
              pw.Text(
                "Terms & Conditions apply",
                softWrap: false,
                style: pw.TextStyle(
                  fontSize: 5.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PAGE HELPERS
  // ==========================================

  pw.Widget _buildPageBorder(String pointCode) {
    return pw.Positioned.fill(
      child: pw.Container(
        margin: const pw.EdgeInsets.all(0), // Removed margin to touch corners
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 1.3, color: PdfColors.black),
        ),
        child: pw.Stack(
          children: [
            _buildBorderLabel(pointCode, top: 2, left: 0, right: 0),
            _buildBorderLabel(pointCode, bottom: 2, left: 0, right: 0),
            _buildBorderSideLabel(pointCode, left: 2, top: 0, bottom: 0),
            _buildBorderSideLabel(pointCode, right: 2, top: 0, bottom: 0),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildBorderLabel(
    String text, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return pw.Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildBorderSideLabel(
    String text, {
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return pw.Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: 1.5708,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // API & STATE METHODS
  // ==========================================

  Future<void> _fetchPointMaster() async {
    try {
      final response = await ApiService(
        token: '',
      ).getRequest('$baseUrl/api/point/points');

      if (response != null && mounted) {
        setState(() {
          final Set<int> seenPoints = {};
          _pointsList = [];

          for (var item in (response as List)) {
            final int? pointValue = int.tryParse(item['points'].toString());

            if (pointValue != null && !seenPoints.contains(pointValue)) {
              seenPoints.add(pointValue);
              item['points'] = pointValue;
              _pointsList.add(item);
            }
          }

          if (_pointsList.isNotEmpty) {
            _selectedPoints = _pointsList[0]['points'];
          }
        });
      }
    } catch (e) {
      print("Failed to fetch point master: $e");
    }
  }

  Future<void> _fetchNextStart() async {
    try {
      final response = await ApiService(
        token: '',
      ).getRequest("$baseUrl/api/qr-history");
      if (response != null &&
          response["history"] != null &&
          response["history"].isNotEmpty) {
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
    } catch (e) {
      print("Error fetching next start: $e");
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
            points: _selectedPoints!,
          );
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
                onPressed: () => Navigator.of(context).pop(),
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
            duration: Duration(milliseconds: 3000),
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
      final history = response["history"] ?? [];
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
                  child: _pointsList.isEmpty
                      ? const SizedBox(
                          height: 50,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          value: _selectedPoints,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Select Point',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 15,
                            ),
                          ),
                          items: _pointsList.map<DropdownMenuItem<int>>((
                            point,
                          ) {
                            return DropdownMenuItem<int>(
                              value: point['points'] as int,
                              child: Text(
                                '${point['points']} (${point['code']})',
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPoints = val;
                            });
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffC02221),
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
                  SizedBox(
                    width: 220,
                    height: 160,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFB8860B),
                            Color(0xFFDAA520),
                            Color(0xFFF4A460),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4A90E2),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF4A90E2),
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                            Container(
                                              color: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                  ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: const [
                                                  Text(
                                                    'KEN',
                                                    style: TextStyle(
                                                      fontSize: 6,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  Text(
                                                    'UNIV',
                                                    style: TextStyle(
                                                      fontSize: 6,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Image.network(
                                                qr.qrImage,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            Text(
                                              '${qr.uniqueCode}',
                                              style: const TextStyle(
                                                fontSize: 6,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ===============================================
                  // Button 1: Generate PDF (Generic/Colored)
                  // ===============================================
                  SizedBox(
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
                      onPressed: _loadingPdfIndex != 0
                          ? null
                          : () async {
                              setState(() {
                                _loadingPdfIndex = 1;
                              });
                              try {
                                final fontRegular =
                                    await PdfGoogleFonts.robotoRegular();
                                final fontBold =
                                    await PdfGoogleFonts.robotoBold();
                                final fontFallback =
                                    await PdfGoogleFonts.notoSansGujaratiRegular();
                                final fontHindi =
                                    await PdfGoogleFonts.notoSansDevanagariRegular();
                                final iconFont =
                                    await PdfGoogleFonts.materialIconsRegular();

                                final pdf = pw.Document(
                                  theme: pw.ThemeData.withFont(
                                    base: fontRegular,
                                    bold: fontBold,
                                    fontFallback: [fontFallback, fontHindi],
                                  ),
                                );

                                for (int i = 0; i < _qrList.length; i += 18) {
                                  final batch = _qrList
                                      .skip(i)
                                      .take(18)
                                      .toList();
                                  final qrWidgets = <pw.Widget>[];

                                  for (var qr in batch) {
                                    final imageProvider = await networkImage(
                                      qr.qrImage,
                                    );
                                    qrWidgets.add(
                                      _buildLayout2(
                                        qr,
                                        imageProvider,
                                        iconFont,
                                        isBw: false,
                                      ),
                                    );
                                  }

                                  // FIX: Add empty containers so the grid never changes sizes!
                                  while (qrWidgets.length < 18) {
                                    qrWidgets.add(pw.Container());
                                  }

                                  pdf.addPage(
                                    pw.Page(
                                      pageFormat: PdfPageFormat.a4,
                                      build: (pw.Context context) {
                                        return pw.Stack(
                                          children: [
                                            pw.Container(
                                              color: PdfColors.white,
                                            ),
                                            _buildPageBorder(""),
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.fromLTRB(
                                                    15,
                                                    20,
                                                    15,
                                                    20,
                                                  ),
                                              child: pw.Align(
                                                alignment: pw.Alignment.topLeft,
                                                child: pw.GridView(
                                                  crossAxisCount: 3,
                                                  mainAxisSpacing: 10,
                                                  crossAxisSpacing: 8,
                                                  childAspectRatio:
                                                      1.52, // Perfect fit for new taller layout
                                                  children: qrWidgets,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                }
                                if (kIsWeb)
                                  await Printing.sharePdf(
                                    bytes: await pdf.save(),
                                    filename: 'qr_codes.pdf',
                                  );
                              } finally {
                                if (mounted)
                                  setState(() {
                                    _loadingPdfIndex = 0;
                                  });
                              }
                            },
                      child: _loadingPdfIndex == 1
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xffC02221),
                              ),
                            )
                          : const Text(
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

                  // ===============================================
                  // Button 2: Pre-Printed Sheet PDF (Background Color)
                  // ===============================================
                  SizedBox(
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
                      onPressed: _loadingPdfIndex != 0
                          ? null
                          : () async {
                              setState(() {
                                _loadingPdfIndex = 2;
                              });
                              try {
                                final fontRegular =
                                    await PdfGoogleFonts.robotoRegular();
                                final fontBold =
                                    await PdfGoogleFonts.robotoBold();
                                final fontFallback =
                                    await PdfGoogleFonts.notoSansGujaratiRegular();
                                final fontHindi =
                                    await PdfGoogleFonts.notoSansDevanagariRegular();
                                final iconFont =
                                    await PdfGoogleFonts.materialIconsRegular();

                                final pdf = pw.Document(
                                  theme: pw.ThemeData.withFont(
                                    base: fontRegular,
                                    bold: fontBold,
                                    fontFallback: [fontFallback, fontHindi],
                                  ),
                                );

                                final pointData = _pointsList.firstWhere(
                                  (p) => p['points'] == _selectedPoints,
                                  orElse: () => {
                                    'color': '#FFFFFF',
                                    'code': '',
                                  },
                                );
                                final bgColor = PdfColor.fromInt(
                                  int.parse(
                                    pointData['color'].replaceFirst('#', 'FF'),
                                    radix: 16,
                                  ),
                                );
                                final pointCode = pointData['code'];

                                for (int i = 0; i < _qrList.length; i += 18) {
                                  final batch = _qrList
                                      .skip(i)
                                      .take(18)
                                      .toList();
                                  final qrWidgets = <pw.Widget>[];

                                  for (var qr in batch) {
                                    final imageProvider = await networkImage(
                                      qr.qrImage,
                                    );
                                    qrWidgets.add(
                                      _buildLayout2(
                                        qr,
                                        imageProvider,
                                        iconFont,
                                        isBw: false,
                                      ),
                                    );
                                  }

                                  // FIX: Add empty containers so the grid never changes sizes!
                                  while (qrWidgets.length < 18) {
                                    qrWidgets.add(pw.Container());
                                  }

                                  pdf.addPage(
                                    pw.Page(
                                      pageFormat: PdfPageFormat.a4,
                                      build: (pw.Context context) {
                                        return pw.Stack(
                                          children: [
                                            pw.Container(color: bgColor),
                                            _buildPageBorder(pointCode),
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.fromLTRB(
                                                    15,
                                                    20,
                                                    15,
                                                    20,
                                                  ),
                                              child: pw.Align(
                                                alignment: pw.Alignment.topLeft,
                                                child: pw.GridView(
                                                  crossAxisCount: 3,
                                                  mainAxisSpacing: 10,
                                                  crossAxisSpacing: 8,
                                                  childAspectRatio: 1.52,
                                                  children: qrWidgets,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                }

                                if (kIsWeb)
                                  await Printing.sharePdf(
                                    bytes: await pdf.save(),
                                    filename: 'qr_preprinted.pdf',
                                  );
                              } finally {
                                if (mounted)
                                  setState(() {
                                    _loadingPdfIndex = 0;
                                  });
                              }
                            },
                      child: _loadingPdfIndex == 2
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xffC02221),
                              ),
                            )
                          : const Text(
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

                  // ===============================================
                  // Button 3: Black & White PDF
                  // ===============================================
                  SizedBox(
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
                      onPressed: _loadingPdfIndex != 0
                          ? null
                          : () async {
                              setState(() {
                                _loadingPdfIndex = 3;
                              });
                              try {
                                final fontRegular =
                                    await PdfGoogleFonts.robotoRegular();
                                final fontBold =
                                    await PdfGoogleFonts.robotoBold();
                                final fontFallback =
                                    await PdfGoogleFonts.notoSansGujaratiRegular();
                                final fontHindi =
                                    await PdfGoogleFonts.notoSansDevanagariRegular();
                                final iconFont =
                                    await PdfGoogleFonts.materialIconsRegular();

                                final pdf = pw.Document(
                                  theme: pw.ThemeData.withFont(
                                    base: fontRegular,
                                    bold: fontBold,
                                    fontFallback: [fontFallback, fontHindi],
                                  ),
                                );

                                for (int i = 0; i < _qrList.length; i += 18) {
                                  final batch = _qrList
                                      .skip(i)
                                      .take(18)
                                      .toList();
                                  final qrWidgets = <pw.Widget>[];

                                  for (var qr in batch) {
                                    final imageProvider = await networkImage(
                                      qr.qrImage,
                                    );
                                    qrWidgets.add(
                                      _buildLayout2(
                                        qr,
                                        imageProvider,
                                        iconFont,
                                        isBw: true,
                                      ),
                                    );
                                  }

                                  // FIX: Add empty containers so the grid never changes sizes!
                                  while (qrWidgets.length < 18) {
                                    qrWidgets.add(pw.Container());
                                  }

                                  pdf.addPage(
                                    pw.Page(
                                      pageFormat: PdfPageFormat.a4,
                                      build: (pw.Context context) {
                                        return pw.Stack(
                                          children: [
                                            pw.Container(
                                              color: PdfColors.white,
                                            ),
                                            _buildPageBorder(""),
                                            pw.Padding(
                                              padding:
                                                  const pw.EdgeInsets.fromLTRB(
                                                    15,
                                                    20,
                                                    15,
                                                    20,
                                                  ),
                                              child: pw.Align(
                                                alignment: pw.Alignment.topLeft,
                                                child: pw.GridView(
                                                  crossAxisCount: 3,
                                                  mainAxisSpacing: 10,
                                                  crossAxisSpacing: 8,
                                                  childAspectRatio: 1.52,
                                                  children: qrWidgets,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  );
                                }

                                if (kIsWeb)
                                  await Printing.sharePdf(
                                    bytes: await pdf.save(),
                                    filename: 'qr_bw.pdf',
                                  );
                              } finally {
                                if (mounted)
                                  setState(() {
                                    _loadingPdfIndex = 0;
                                  });
                              }
                            },
                      child: _loadingPdfIndex == 3
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xffC02221),
                              ),
                            )
                          : const Text(
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
                              builder: (context) => AlertDialog(
                                title: const Text('QR Codes Activated'),
                                content: const Text(
                                  'Selected QR codes have been activated successfully.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
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
                              builder: (context) => AlertDialog(
                                title: const Text('QR Codes Inactivated'),
                                content: const Text(
                                  'Selected QR codes have been inactivated successfully.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
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
              SizedBox(
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
                                  "http://api.kenuniv.com/api/qr-history/pdf/$recordId";
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to download PDF (Status ${response.status})',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Download failed.'),
                                    ),
                                  );
                                }
                              } else {
                                final resp = await http.get(Uri.parse(pdfUrl));
                                if (resp.statusCode == 200) {
                                  final bytes = resp.bodyBytes;
                                  await Printing.sharePdf(
                                    bytes: bytes,
                                    filename: 'qr_history_$recordId.pdf',
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
