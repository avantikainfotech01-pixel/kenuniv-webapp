import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kenuniv/models/scheme_model.dart';
import 'package:kenuniv/providers/stock_provider.dart';
import 'package:kenuniv/utils/constant.dart';
import 'package:kenuniv/providers/scheme_provider.dart';
import 'package:kenuniv/providers/auth_provider.dart';

class StockMaster extends ConsumerStatefulWidget {
  const StockMaster({super.key});

  @override
  ConsumerState<StockMaster> createState() => _StockMasterState();
}

class _StockMasterState extends ConsumerState<StockMaster> {
  String? selectedProduct;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _minQtyController = TextEditingController();
  DateTime? selectedDate;
  String? selectedSchemeId;
  String? selectedProductName;

  Future<void> _submitStock() async {
    // Get permission state
    final authState = ref.read(authProvider);
    final canWrite = authState.permissions?['stock'] == true;
    final isReadOnly = !canWrite;
    if (isReadOnly) return;
    if (selectedSchemeId == null ||
        _quantityController.text.isEmpty ||
        _minQtyController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final url = Uri.parse('$baseUrl/api/admin/stocks');
    final body = {
      "schemeId": selectedSchemeId!,
      "itemName": selectedProductName ?? "",
      "quantity": int.tryParse(_quantityController.text) ?? 0,
      "minQty": int.tryParse(_minQtyController.text) ?? 0,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock added successfully')),
        );
        _quantityController.clear();
        _minQtyController.clear();
        setState(() {
          selectedSchemeId = null;
          selectedProductName = null;
          selectedDate = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _minQtyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final schemesAsync = ref.watch(schemeProvider);
    final stocksAsync = ref.watch(stockProvider);
    final authState = ref.watch(authProvider);
    final canWrite = authState.permissions?['stock'] == true;
    final isReadOnly = !canWrite;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Gift Stock Master"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(stockProvider);
              ref.refresh(schemeProvider);
            },
          ),
        ],
        centerTitle: false,
      ),
      body: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 4,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stock Master',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: schemesAsync.when(
                          data: (schemes) {
                            final activeSchemes = schemes
                                .where((scheme) => scheme.status == "active")
                                .toList();
                            if (activeSchemes.isEmpty) {
                              return const Text("No active schemes available");
                            }
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Gift Scheme',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedSchemeId,
                              items: activeSchemes.map((scheme) {
                                return DropdownMenuItem<String>(
                                  value: scheme.id,
                                  child: Text(
                                    "${scheme.productName ?? ''} (${scheme.schemeName ?? ''})",
                                  ),
                                );
                              }).toList(),
                              onChanged: isReadOnly
                                  ? null
                                  : (value) {
                                      final selected = activeSchemes.firstWhere(
                                        (s) => s.id == value,
                                        orElse: () => activeSchemes.first,
                                      );
                                      setState(() {
                                        selectedSchemeId = selected.id;
                                        selectedProductName =
                                            selected.productName;
                                      });
                                    },
                              // Disable dropdown if read-only
                              disabledHint: selectedSchemeId != null
                                  ? Text(
                                      activeSchemes
                                              .firstWhere(
                                                (s) => s.id == selectedSchemeId,
                                                orElse: () =>
                                                    activeSchemes.first,
                                              )
                                              .productName ??
                                          '',
                                    )
                                  : null,
                              // Not all DropdownButtonFormField support enabled, so we use onChanged: null to disable
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Text('Error: $error'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !isReadOnly,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _minQtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimum Quantity',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !isReadOnly,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: isReadOnly ? null : () => _pickDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                          hintText: selectedDate == null
                              ? 'Select date'
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                        ),
                        controller: TextEditingController(
                          text: selectedDate == null
                              ? ''
                              : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                        ),
                        enabled: !isReadOnly,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: isReadOnly ? null : _submitStock,
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: SizedBox(
                width: double.infinity,
                child: schemesAsync.when(
                  data: (schemes) => stocksAsync.when(
                    data: (stocks) => SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 6,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: DataTable(
                            dataRowHeight: 70,
                            headingRowColor: WidgetStateProperty.all(
                              Colors.red.withOpacity(0.1),
                            ),
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 15,
                            ),
                            columnSpacing: 25,
                            showBottomBorder: true,
                            columns: const [
                              DataColumn(label: Text('No.')),
                              DataColumn(label: Text('Image')),
                              DataColumn(label: Text('Gift Name')),
                              DataColumn(label: Text('Scheme')),
                              DataColumn(label: Text('Quantity')),
                              DataColumn(label: Text('Min Qty')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: List<DataRow>.generate(stocks.length, (
                              index,
                            ) {
                              final stock = stocks[index];
                              final scheme = schemes.firstWhere(
                                (s) => s.id == stock.schemeId?.id,
                                orElse: () => Scheme(
                                  id: '',
                                  schemeName: stock.schemeId?.schemeName ?? '',
                                  productName:
                                      stock.schemeId?.productName ?? '',
                                  points: stock.schemeId?.points ?? 0,
                                ),
                              );

                              final isLowStock = stock.quantity <= stock.minQty;

                              return DataRow(
                                color: WidgetStateProperty.all(
                                  index.isEven
                                      ? Colors.grey.shade50
                                      : Colors.white,
                                ),
                                cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child:
                                          (scheme.image != null &&
                                              scheme.image!.isNotEmpty)
                                          ? Image.network(
                                              '$baseUrl${scheme.image}',
                                              width: 55,
                                              height: 55,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 55,
                                              height: 55,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      scheme.productName.isNotEmpty
                                          ? scheme.productName
                                          : stock.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      scheme.schemeName,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      stock.quantity.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isLowStock
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(stock.minQty.toString())),
                                  DataCell(
                                    isLowStock
                                        ? Row(
                                            children: [
                                              BlinkWidget(),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(
                                                    0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.red.shade300,
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Low Stock',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.green.shade300,
                                              ),
                                            ),
                                            child: const Text(
                                              'OK',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Error: $error'),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlinkWidget extends StatefulWidget {
  @override
  _BlinkWidgetState createState() => _BlinkWidgetState();
}

class _BlinkWidgetState extends State<BlinkWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.transparent,
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: _colorAnimation.value,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
