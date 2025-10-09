import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kenuniv/models/stock_model.dart';
import 'package:kenuniv/providers/stock_provider.dart';
import 'package:kenuniv/utils/constant.dart';
import 'package:kenuniv/providers/scheme_provider.dart';

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
  Future<void> _submitStock() async {
    if (selectedProduct == null ||
        _quantityController.text.isEmpty ||
        _minQtyController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final url = Uri.parse('$baseUrl/api/admin/stocks');
    final body = {
      "itemName": selectedProduct!,
      "quantity": int.tryParse(_quantityController.text) ?? 0,
      "minQty": int.tryParse(_minQtyController.text) ?? 0,
      "schemeId": selectedProduct, // adjust if using scheme id instead of name
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
          selectedProduct = null;
          selectedDate = null;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Gift Stock Master"),
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
                          data: (schemes) => DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Gift',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedProduct,
                            items: schemes
                                .where((scheme) => scheme.status == "active")
                                .toList()
                                .map(
                                  (scheme) => DropdownMenuItem<String>(
                                    value: scheme.schemeName,
                                    child: Text(scheme.productName ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedProduct = value;
                              });
                            },
                          ),
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _pickDate(context),
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
                        onPressed: _submitStock,
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
                    data: (stocks) => DataTable(
                      columns: const [
                        DataColumn(
                          label: Text(
                            'No.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Image',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Product Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Scheme Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Quantity',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Min Qty',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Low Stock',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows: schemes.asMap().entries.map((entry) {
                        int index = entry.key;
                        final scheme = entry.value;
                        // final stock = stocksMap[scheme.id];

                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(
                              scheme.image != null && scheme.image!.isNotEmpty
                                  ? Image.network(
                                      scheme.image!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox(width: 50, height: 50),
                            ),
                            DataCell(Text(scheme.productName ?? '')),
                            DataCell(Text(scheme.schemeName ?? '')),
                            DataCell(Text(scheme.points.toString())),
                            // DataCell(Text(stock != null ? '${stock.quantity}' : '0')),
                            // DataCell(Text(stock != null ? '${stock.minQty}' : '0')),
                            // DataCell(
                            //   (stock != null && stock.quantity < stock.minQty)
                            //       ? BlinkWidget()
                            //       : const SizedBox.shrink(),
                            // ),
                          ],
                        );
                      }).toList(),
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
