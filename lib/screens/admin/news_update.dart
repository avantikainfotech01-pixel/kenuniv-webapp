// lib/screens/admin/news_update.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../providers/news_provider.dart';
import 'package:kenuniv/utils/constant.dart';
import 'package:kenuniv/providers/auth_provider.dart';

class NewsUpdate extends ConsumerStatefulWidget {
  const NewsUpdate({super.key});

  @override
  ConsumerState<NewsUpdate> createState() => _NewsUpdateState();
}

class _NewsUpdateState extends ConsumerState<NewsUpdate> {
  final ImagePicker _picker = ImagePicker();
  XFile? _mediaFile;
  String? _mediaType; // 'image' or 'video'
  Uint8List? _webBytes; // store bytes for preview on web
  bool _uploading = false;
  double _progress = 0.0;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<dynamic> _localNewsList = [];

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        _webBytes = await picked.readAsBytes();
      }
      setState(() {
        _mediaFile = picked;
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        _webBytes = await picked.readAsBytes();
      }
      setState(() {
        _mediaFile = picked;
        _mediaType = 'video';
      });
    }
  }

  Future<void> _submit() async {
    final canEditNews = ref.read(authProvider).permissions?['news'] == true;
    if (!canEditNews) return;

    if (_mediaFile == null || _mediaType == null) return;
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    if (title.isEmpty && desc.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add title or description')));
      return;
    }

    try {
      setState(() {
        _uploading = true;
        _progress = 0;
      });

      final fileForUpload = kIsWeb ? _webBytes : File(_mediaFile!.path);

      await ref
          .read(newsProvider.notifier)
          .addNews(
            mediaFile: fileForUpload,
            mediaType: _mediaType!,
            title: title,
            description: desc,
            onProgress: (sent, total) {
              setState(() {
                _progress = total > 0 ? sent / total : 0;
              });
            },
          );

      // reset
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _mediaFile = null;
        _webBytes = null;
        _mediaType = null;
        _uploading = false;
        _progress = 0;
      });
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsList = ref.watch(newsProvider);
    final authState = ref.watch(authProvider);
    final canEditNews = authState.permissions?['news'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('News Update')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Upload Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Media picker + preview
                          Column(
                            children: [
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: canEditNews ? _pickImage : null,
                                    icon: const Icon(Icons.image),
                                    label: const Text('Image'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: canEditNews ? _pickVideo : null,
                                    icon: const Icon(Icons.videocam),
                                    label: const Text('Video'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  if (_mediaFile == null) return;
                                  if (_mediaType == 'image') {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: kIsWeb
                                            ? Image.memory(_webBytes!)
                                            : Image.file(
                                                File(_mediaFile!.path),
                                              ),
                                      ),
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: _VideoPlayerDialog(
                                          videoFile: kIsWeb
                                              ? null
                                              : File(_mediaFile!.path),
                                          videoUrl: kIsWeb
                                              ? null
                                              : null, // not used for local file
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 180,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _mediaFile == null
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.upload_outlined,
                                              size: 36,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Tap to pick',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        )
                                      : _mediaType == 'image'
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: kIsWeb
                                              ? (_webBytes != null
                                                    ? Image.memory(
                                                        _webBytes!,
                                                        fit: BoxFit.cover,
                                                        width: 180,
                                                        height: 140,
                                                      )
                                                    : const SizedBox())
                                              : Image.file(
                                                  File(_mediaFile!.path),
                                                  fit: BoxFit.cover,
                                                  width: 180,
                                                  height: 140,
                                                ),
                                        )
                                      : Stack(
                                          children: [
                                            Container(
                                              width: 180,
                                              height: 140,
                                              color: Colors.black12,
                                              child: const Center(
                                                child: Icon(
                                                  Icons.videocam,
                                                  size: 48,
                                                ),
                                              ),
                                            ),
                                            const Positioned.fill(
                                              child: Center(
                                                child: Icon(
                                                  Icons.play_circle_fill,
                                                  size: 40,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              if (_uploading)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: SizedBox(
                                    width: 180,
                                    child: LinearProgressIndicator(
                                      value: _progress,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 20),

                          // Title / description
                          Expanded(
                            child: Column(
                              children: [
                                TextField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              _titleController.clear();
                              _descriptionController.clear();
                              setState(() {
                                _mediaFile = null;
                                _webBytes = null;
                                _mediaType = null;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: canEditNews && !_uploading
                                ? _submit
                                : null,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                'Submit',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // News List (reorderable)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      final list =
                          newsList; // since newsProvider returns List<Map>
                      if (list.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text("No news found")),
                        );
                      }

                      if (_localNewsList.isEmpty) {
                        _localNewsList = List.from(list);
                      }

                      return ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _localNewsList.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _localNewsList.removeAt(oldIndex);
                          _localNewsList.insert(newIndex, item);
                          setState(() {});
                          await ref
                              .read(newsProvider.notifier)
                              .reorderLocal(oldIndex, newIndex);
                        },
                        itemBuilder: (ctx, index) {
                          final news = _localNewsList[index];
                          final media = news['mediaUrl'] ?? '';
                          final type = news['mediaType'] ?? 'image';

                          return ListTile(
                            key: ValueKey(news['_id'] ?? index),
                            leading: SizedBox(
                              width: 80,
                              child: type == 'image'
                                  ? Image.network(
                                      '$baseUrl$media',
                                      fit: BoxFit.cover,
                                    )
                                  : Stack(
                                      children: [
                                        Container(
                                          color: Colors.black12,
                                          width: 80,
                                          height: 60,
                                        ),
                                        const Center(
                                          child: Icon(Icons.videocam),
                                        ),
                                      ],
                                    ),
                            ),
                            title: Text(news['title'] ?? ''),
                            subtitle: Text(news['description'] ?? ''),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.vertical_align_top),
                                  onPressed: () async {
                                    await ref
                                        .read(newsProvider.notifier)
                                        .moveToTop(news['_id']);
                                    setState(() {
                                      final item = _localNewsList.removeAt(
                                        index,
                                      );
                                      _localNewsList.insert(0, item);
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await ref
                                        .read(newsProvider.notifier)
                                        .deleteNews(news['_id']);
                                    setState(
                                      () => _localNewsList.removeAt(index),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              if (type == 'image') {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.network(
                                      '$baseUrl$media',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: _VideoPlayerDialog(
                                      videoUrl: '$baseUrl$media',
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Video dialog (web + mobile)
class _VideoPlayerDialog extends StatefulWidget {
  final File? videoFile;
  final String? videoUrl;
  const _VideoPlayerDialog({Key? key, this.videoFile, this.videoUrl})
    : super(key: key);

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  VideoPlayerController? _controller;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    try {
      if (widget.videoFile != null) {
        _controller = VideoPlayerController.file(widget.videoFile!);
      } else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
        final url = widget.videoUrl!;
        _controller = kIsWeb
            ? VideoPlayerController.networkUrl(Uri.parse(url))
            : VideoPlayerController.networkUrl(Uri.parse(url));
      }

      if (_controller != null) {
        _initFuture = _controller!.initialize().then((_) {
          _controller!.setLooping(true);
          _controller!.play();
          setState(() {});
        });
      } else {
        _initFuture = Future.value();
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      _initFuture = Future.value();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Invalid video')),
      );
    }
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.done &&
            _controller!.value.isInitialized) {
          return AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          );
        } else if (snap.hasError) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Failed to load video')),
          );
        } else {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
