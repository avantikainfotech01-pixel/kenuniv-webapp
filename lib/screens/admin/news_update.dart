import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kenuniv/providers/auth_provider.dart';
import 'package:kenuniv/utils/constant.dart';
import '../../providers/news_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_web/video_player_web.dart';
import 'package:http_parser/http_parser.dart';

class NewsUpdate extends ConsumerStatefulWidget {
  const NewsUpdate({super.key});

  @override
  ConsumerState<NewsUpdate> createState() => _NewsUpdateState();
}

class _NewsUpdateState extends ConsumerState<NewsUpdate> {
  final ImagePicker _picker = ImagePicker();
  XFile? _mediaFile;
  String? _mediaType; // 'image' or 'video'

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<dynamic> _localNewsList = [];

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _mediaFile = pickedFile;
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _mediaFile = pickedFile;
        _mediaType = 'video';
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
    // Get user permissions from auth provider
    final authState = ref.watch(authProvider);
    final canEditNews = authState.permissions?['news'] == true;

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
                        // Upload Media Section (Image/Video)
                        Column(
                          children: [
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: canEditNews ? _pickImage : null,
                                  icon: const Icon(Icons.image),
                                  label: const Text('Pick Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade400,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: canEditNews ? _pickVideo : null,
                                  icon: const Icon(Icons.videocam),
                                  label: const Text('Pick Video'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade400,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                if (_mediaFile != null) {
                                  if (_mediaType == 'image') {
                                    // Show full image dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: kIsWeb
                                            ? Image.network(_mediaFile!.path)
                                            : Image.file(
                                                File(_mediaFile!.path),
                                              ),
                                      ),
                                    );
                                  } else if (_mediaType == 'video') {
                                    // Show video in dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: _VideoPlayerDialog(
                                          videoUrl: kIsWeb
                                              ? _mediaFile!.path
                                              : null,
                                          videoFile: kIsWeb
                                              ? null
                                              : File(_mediaFile!.path),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                width: 180,
                                height: 190,
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
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'News Media',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      )
                                    : _mediaType == 'image'
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: kIsWeb
                                            ? Image.network(
                                                _mediaFile!.path,
                                                fit: BoxFit.cover,
                                                width: 180,
                                                height: 190,
                                              )
                                            : Image.file(
                                                File(_mediaFile!.path),
                                                fit: BoxFit.cover,
                                                width: 180,
                                                height: 190,
                                              ),
                                      )
                                    : Stack(
                                        children: [
                                          Container(
                                            width: 180,
                                            height: 190,
                                            color: Colors.black12,
                                            child: Center(
                                              child: Icon(
                                                Icons.videocam,
                                                size: 80,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          const Positioned(
                                            left: 0,
                                            right: 0,
                                            top: 0,
                                            bottom: 0,
                                            child: Center(
                                              child: Icon(
                                                Icons.play_circle_fill,
                                                size: 56,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
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
                        onPressed: canEditNews
                            ? () async {
                                if (_mediaFile != null && _mediaType != null) {
                                  dynamic fileForUpload;
                                  if (kIsWeb) {
                                    // Just pass Uint8List
                                    fileForUpload = await _mediaFile!
                                        .readAsBytes();
                                  } else {
                                    // Mobile: pass File
                                    fileForUpload = File(_mediaFile!.path);
                                  }

                                  await ref
                                      .read(newsProvider.notifier)
                                      .addNews(
                                        mediaFile: fileForUpload,
                                        mediaType: _mediaType ?? '',
                                        title: _titleController.text,
                                        description:
                                            _descriptionController.text,
                                      );

                                  _titleController.clear();
                                  _descriptionController.clear();
                                  setState(() {
                                    _mediaFile = null;
                                    _mediaType = null;
                                  });
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
                                      child: GestureDetector(
                                        onTap: () {
                                          if (news.mediaUrl == null ||
                                              news.mediaUrl!.isEmpty)
                                            return;

                                          if (news.mediaType == 'image') {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                child: Image.network(
                                                  '${baseUrl}${news.mediaUrl}',
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                            );
                                          } else if (news.mediaType ==
                                              'video') {
                                            showDialog(
                                              context: context,
                                              builder: (context) => Dialog(
                                                child: _VideoPlayerDialog(
                                                  videoUrl:
                                                      '${baseUrl}${news.mediaUrl}',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child:
                                            (news.mediaUrl == null ||
                                                news.mediaUrl!.isEmpty)
                                            ? const Center(
                                                child: Text(
                                                  "No media",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              )
                                            : news.mediaType == 'image'
                                            ? Image.network(
                                                '${baseUrl}${news.mediaUrl}',
                                              )
                                            : Stack(
                                                children: [
                                                  Container(
                                                    color: Colors.black12,
                                                    width: 100,
                                                    height: 60,
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.videocam,
                                                        size: 36,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                  const Positioned(
                                                    left: 0,
                                                    right: 0,
                                                    top: 0,
                                                    bottom: 0,
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.play_circle_fill,
                                                        size: 32,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                                  onPressed: canEditNews
                                      ? () async {
                                          await ref
                                              .read(newsProvider.notifier)
                                              .deleteNews(news.id);
                                          setState(() {
                                            _localNewsList.removeAt(index);
                                          });
                                        }
                                      : null,
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

// Widget for video preview dialog (mobile and web with correct url/file)

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
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    try {
      if (widget.videoFile != null) {
        _controller = VideoPlayerController.file(widget.videoFile!);
      } else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
        // Ensure HTTPS absolute URL
        final videoUrl =
            (widget.videoUrl!.startsWith('http') ||
                widget.videoUrl!.startsWith('blob:'))
            ? widget.videoUrl!
            : '$baseUrl${widget.videoUrl}';
        if (kIsWeb) {
          _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        } else {
          _controller = VideoPlayerController.network(videoUrl);
        }
      }

      if (_controller != null) {
        _initializeVideoPlayerFuture = _controller!
            .initialize()
            .then((_) async {
              await _controller!.setLooping(true);
              await _controller!.play();
              setState(() {});
            })
            .catchError((e) {
              debugPrint('Video init error: $e');
              setState(() {}); // To trigger error display in FutureBuilder
            });
      }
    } catch (e) {
      debugPrint('Video controller init exception: $e');
      setState(() {});
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
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            _controller!.value.isInitialized) {
          return AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load video',
              style: TextStyle(color: Colors.red),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active) {
          return Container(
            width: 400,
            height: 220,
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),
          );
        } else {
          // Unlikely, but fallback error
          return Center(
            child: Text(
              'Failed to load video',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
      },
    );
  }
}
