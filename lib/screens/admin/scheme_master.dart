import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenuniv/utils/constant.dart';
import '../../providers/scheme_provider.dart';
import '../../providers/auth_provider.dart';

class SchemeMaster extends ConsumerStatefulWidget {
  const SchemeMaster({super.key});

  @override
  ConsumerState<SchemeMaster> createState() => _SchemeMasterState();
}

class _SchemeMasterState extends ConsumerState<SchemeMaster> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _webImageBytes;
  XFile? _imageFile;

  final TextEditingController _schemeNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(schemeProvider.notifier).fetchSchemes());
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _webImageBytes = bytes; // store bytes for upload
        });
      }
    } else {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    }
  }

  @override
  void dispose() {
    _schemeNameController.dispose();
    _productNameController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schemeNotifier = ref.read(schemeProvider.notifier);
    final schemeState = ref.watch(schemeProvider);
    // Permission logic
    final canEdit = ref.watch(authProvider).permissions?['scheme'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Master'),
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload Image
                    InkWell(
                      onTap: canEdit ? _pickImage : null,
                      child: AbsorbPointer(
                        absorbing: !canEdit,
                        child: Opacity(
                          opacity: canEdit ? 1.0 : 0.6,
                          child: Container(
                            width: 180,
                            height: 190,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _imageFile == null
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_outlined,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Product Photo',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? (_webImageBytes != null
                                              ? Image.memory(
                                                  _webImageBytes!,
                                                  fit: BoxFit.cover,
                                                )
                                              : const SizedBox.shrink())
                                        : Image.file(
                                            File(_imageFile!.path),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _schemeNameController,
                              decoration: const InputDecoration(
                                labelText: 'Scheme Name',
                                border: OutlineInputBorder(),
                              ),
                              enabled: canEdit,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _productNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Product Name',
                                      border: OutlineInputBorder(),
                                    ),
                                    enabled: canEdit,
                                  ),
                                ),
                                const SizedBox(width: 36),
                                SizedBox(
                                  width: 200,
                                  child: TextField(
                                    controller: _pointsController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Points',
                                      border: OutlineInputBorder(),
                                    ),
                                    enabled: canEdit,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: canEdit
                        ? () async {
                            final schemeName = _schemeNameController.text
                                .trim();
                            final productName = _productNameController.text
                                .trim();
                            final pointsText = _pointsController.text.trim();
                            final points = int.tryParse(pointsText) ?? 0;

                            if (schemeName.isEmpty ||
                                productName.isEmpty ||
                                points <= 0 ||
                                _imageFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please fill all fields and upload an image',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            dynamic imageData;
                            if (kIsWeb) {
                              imageData = _webImageBytes;
                            } else {
                              imageData = File(_imageFile!.path);
                            }

                            try {
                              await schemeNotifier.addScheme(
                                schemeName: schemeName,
                                productName: productName,
                                points: points,
                                imageBytes: imageData,
                              );

                              _schemeNameController.clear();
                              _productNameController.clear();
                              _pointsController.clear();
                              setState(() => _imageFile = null);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Scheme added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add scheme: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 19, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 🔹 Scheme Table Section
                Expanded(
                  child: schemeState.when(
                    data: (schemes) {
                      if (schemes.isEmpty) {
                        return const Center(child: Text('No schemes found'));
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
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
                                // columnSpacing: 40,
                                showBottomBorder: true,
                                columns: const [
                                  DataColumn(label: Text('No.')),
                                  DataColumn(label: Text('Image')),
                                  DataColumn(label: Text('Scheme Name')),
                                  DataColumn(label: Text('Product Name')),
                                  DataColumn(label: Text('Points')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Action')),
                                ],
                                rows: List<DataRow>.generate(schemes.length, (
                                  index,
                                ) {
                                  final scheme = schemes[index];
                                  final isActive = scheme.status == 'active';

                                  return DataRow(
                                    color: WidgetStateProperty.all(
                                      index.isEven
                                          ? Colors.grey.shade50
                                          : Colors.white,
                                    ),
                                    cells: [
                                      DataCell(Text('${index + 1}')),
                                      DataCell(
                                        InkWell(
                                          onTap: () {
                                            if (scheme.image != null) {
                                              showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          child: Image.network(
                                                            '$baseUrl${scheme.image}',
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          scheme.productName,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: scheme.image != null
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
                                      ),
                                      DataCell(
                                        Text(
                                          scheme.schemeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          scheme.productName,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          scheme.points.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: isActive
                                                  ? Colors.green.shade300
                                                  : Colors.red.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: isActive
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        ElevatedButton(
                                          onPressed: canEdit
                                              ? () async {
                                                  if (isActive) {
                                                    await ref
                                                        .read(
                                                          schemeProvider
                                                              .notifier,
                                                        )
                                                        .deactivateScheme(
                                                          scheme.id!,
                                                        );
                                                  } else {
                                                    await ref
                                                        .read(
                                                          schemeProvider
                                                              .notifier,
                                                        )
                                                        .activateScheme(
                                                          scheme.id!,
                                                        );
                                                  }

                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        isActive
                                                            ? 'Scheme deactivated'
                                                            : 'Scheme activated',
                                                      ),
                                                      backgroundColor: isActive
                                                          ? Colors.orange
                                                          : Colors.green,
                                                    ),
                                                  );
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isActive
                                                ? Colors.orange
                                                : Colors.green,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            isActive
                                                ? 'Deactivate'
                                                : 'Activate',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
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
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
