import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/scheme_provider.dart';

class SchemeMaster extends ConsumerStatefulWidget {
  const SchemeMaster({super.key});

  @override
  ConsumerState<SchemeMaster> createState() => _SchemeMasterState();
}

class _SchemeMasterState extends ConsumerState<SchemeMaster> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  final TextEditingController _schemeNameController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
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
    final SchemeNotifier = ref.read(schemeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text('Gift Master'),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upload Photo Section
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        width: 180,
                        height: 190,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
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
                                child: Image.network(
                                  _imageFile!.path,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Fields Section
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
                    onPressed: () async {
                      final schemeName = _schemeNameController.text.trim();
                      final productName = _productNameController.text.trim();
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
                        imageData = await _imageFile!.readAsBytes();
                      } else {
                        imageData = File(_imageFile!.path);
                      }

                      try {
                        final schemeNotifier = ref.read(
                          schemeProvider.notifier,
                        );
                        await schemeNotifier.addScheme(
                          schemeName: schemeName,
                          productName: productName,
                          points: points,
                          imageFile: imageData,
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
                    },
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
