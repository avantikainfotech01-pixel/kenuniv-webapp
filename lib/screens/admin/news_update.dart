import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenuniv/providers/auth_provider.dart';
import 'package:kenuniv/utils/constant.dart';
import '../../providers/news_provider.dart';

class NewsUpdate extends ConsumerStatefulWidget {
  const NewsUpdate({super.key});

  @override
  ConsumerState<NewsUpdate> createState() => _NewsUpdateState();
}

class _NewsUpdateState extends ConsumerState<NewsUpdate> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<dynamic> _localNewsList = [];

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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);

    // // 🔑 Get user permissions from auth provider
    // final authState = ref.watch(authProvider);
    // final userPermissions = authState.when(
    //   data: (loginResponse) => loginResponse?.user.permissions ?? {},
    //   loading: () => {},
    //   error: (_, __) => {},
    // );
    // final canEditNews = userPermissions['news'] == true;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text('News Update'),
      ),
      body: Column(
        children: [
          Padding(
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
                                        'News Photo',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? Image.network(
                                            _imageFile!.path, // works for web
                                            fit: BoxFit.cover,
                                            width: 180,
                                            height: 190,
                                          )
                                        : Image.file(
                                            File(
                                              _imageFile!.path,
                                            ), // works for mobile
                                            fit: BoxFit.cover,
                                            width: 180,
                                            height: 190,
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
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'News Title',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _descriptionController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'News Description',
                                    border: OutlineInputBorder(),
                                  ),
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
                          if (_imageFile != null) {
                            dynamic imageForUpload;

                            if (kIsWeb) {
                              // On web, read bytes
                              final bytes = await _imageFile!.readAsBytes();
                              imageForUpload =
                                  bytes; // send bytes to your provider
                            } else {
                              // On mobile, use File
                              imageForUpload = File(_imageFile!.path);
                            }

                            await ref
                                .read(newsProvider.notifier)
                                .addNews(
                                  imageFile: imageForUpload,

                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                );

                            _titleController.clear();
                            _descriptionController.clear();
                            setState(() {
                              _imageFile = null;
                            });
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
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: newsAsync.when(
                  data: (newsList) {
                    if (_localNewsList.isEmpty) {
                      _localNewsList = List.from(newsList);
                    }
                    return ReorderableListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = _localNewsList.removeAt(oldIndex);
                          _localNewsList.insert(newIndex, item);
                        });
                      },
                      children: _localNewsList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final news = entry.value;
                        return Card(
                          key: ValueKey(news.id),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text('${index + 1}'),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 100,
                                      height: 60,
                                      child: Image.network(
                                        '${baseUrl}${news.image}',
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        news.title,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        news.description,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await ref
                                        .read(newsProvider.notifier)
                                        .deleteNews(news.id);
                                    setState(() {
                                      _localNewsList.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
